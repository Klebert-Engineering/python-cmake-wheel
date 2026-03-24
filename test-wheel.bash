#!/usr/bin/env bash

set -euo pipefail

venv_python="${PYTHON_WHEEL_TEST_EXECUTABLE:-}"
if [[ -z "$venv_python" ]]; then
  echo "PYTHON_WHEEL_TEST_EXECUTABLE is not set; using 'python3' from PATH." >&2
  venv_python="python3"
fi

venv=$(mktemp -d)
echo "→ Setting up a virtual environment in $venv using python '$venv_python' ($("$venv_python" --version))..."

"$venv_python" -m venv "$venv"

venv_bin="$venv/bin"
if [[ -d "$venv/Scripts" ]]; then
  venv_bin="$venv/Scripts"
fi

# NOTE: Do not source the venv's `activate` script here. On Windows, `venv`
# writes `VIRTUAL_ENV` as an absolute Windows path (e.g. `C:\...`) which breaks
# PATH handling in Git-Bash/MSYS. Instead, prepend the venv bin dir to PATH.
export VIRTUAL_ENV="$venv"
export PATH="$venv_bin:$PATH"
hash -r 2>/dev/null || true

python -m pip install -U pip
pip install pytest

cleanup=true
background_pids=()
failed_pids=()
cleanup_done=false

is_windows_shell=false
case "${OSTYPE:-}" in
  msys*|cygwin*)
    is_windows_shell=true
    ;;
esac
if [[ "${OS:-}" == "Windows_NT" ]]; then
  is_windows_shell=true
fi

terminate_pid_tree() {
  local pid="$1"

  if ! kill -0 "$pid" >/dev/null 2>&1; then
    return 0
  fi

  if [[ "$is_windows_shell" == true ]] && command -v taskkill >/dev/null 2>&1; then
    taskkill //PID "$pid" //T //F >/dev/null 2>&1 || true
    return 0
  fi

  kill -TERM "-$pid" >/dev/null 2>&1 || kill "$pid" >/dev/null 2>&1 || true

  local deadline=$((SECONDS + 20))
  while kill -0 "$pid" >/dev/null 2>&1; do
    if (( SECONDS >= deadline )); then
      kill -KILL "-$pid" >/dev/null 2>&1 || kill -9 "$pid" >/dev/null 2>&1 || true
      break
    fi
    sleep 1
  done

  wait "$pid" 2>/dev/null || true
}

run_command() {
  local cmd="$1"
  if [[ "$cmd" == *.py ]] && [[ "$cmd" != *[[:space:]]* ]]; then
    python "$cmd"
  else
    $cmd
  fi
}

launch_background_command() {
  local cmd="$1"
  if [[ "$is_windows_shell" == true ]]; then
    $cmd &
  elif command -v setsid >/dev/null 2>&1; then
    setsid $cmd &
  else
    $cmd &
  fi
}

cleanup_background_jobs() {
  local pid=""
  for pid in "${background_pids[@]:+${background_pids[@]}}"; do
    if [[ "$is_windows_shell" == true ]]; then
      if kill -0 "$pid" >/dev/null 2>&1; then
        terminate_pid_tree "$pid"
      else
        wait "$pid" 2>/dev/null || true
      fi
      continue
    fi

    if kill -0 "$pid" >/dev/null 2>&1; then
      terminate_pid_tree "$pid"
    else
      if wait "$pid"; then
        echo "Background task $pid already exited with zero status."
      else
        local exit_status=$?
        echo "Background task $pid exited with nonzero status ($exit_status)."
        failed_pids+=("$pid")
      fi
    fi
  done
}

cleanup_virtualenv() {
  if [[ "$cleanup" != "true" ]]; then
    return 0
  fi

  if [[ "$is_windows_shell" == true ]]; then
    # GitHub's Windows runners clean the workspace after each job anyway.
    # Avoid synchronously deleting the temporary venv here: Git-Bash/MSYS can
    # spend minutes tearing down a Python tree after the background services
    # were killed, which turns integration tests into apparent hangs.
    echo "→ Skipping synchronous removal of $venv on Windows"
    return 0
  fi

  echo "→ Removing $venv"
  rm -rf "$venv"
}

on_exit() {
  if [[ "$cleanup_done" == "true" ]]; then
    return 0
  fi
  cleanup_done=true
  set +e
  cleanup_background_jobs
  cleanup_virtualenv

  if [[ ${#failed_pids[@]} -gt 0 ]]; then
    echo "The following background processes exited with nonzero status: ${failed_pids[@]:+${failed_pids[@]}}"
    return 1
  fi
  return 0
}

trap on_exit EXIT

while [[ $# -gt 0 ]]; do
  case $1 in
    -w|--wheels-dir)
      echo "→ Installing wheels from $2 ..."
      pip install --no-deps --force-reinstall "$2"/*
      shift
      shift
      ;;
    -b|--background)
      echo "→ Launching background task: $2"
      launch_background_command "$2"
      background_pids+=("$!")
      echo "... started with PID: $!"
      sleep 5
      shift
      shift
      ;;
    -f|--foreground)
      echo "→ Starting foreground task: $2"
      run_command "$2"
      shift
      shift
      ;;
    -c|--cleanup)
      echo "The temporary virtual will be deleted: $2"
      cleanup=$2
      shift
      shift
      ;;
  esac
done

cleanup_status=0
on_exit || cleanup_status=$?
trap - EXIT
exit "$cleanup_status"
