#!/usr/bin/env bash

set -e

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

trap '
  failed_pids=()
  for pid in $(jobs -p); do
    if kill -0 $pid >/dev/null 2>&1; then
      # Background process is still running - kill it.
      kill $pid
    else
      exit_status=$?
      if [[ $exit_status -eq 0 ]]; then
        echo "Background task $pid already exited with zero status."
      else
        echo "Background task $pid exited with nonzero status ($exit_status)."
        failed_pids+=("$pid")
      fi
    fi
  done

  if [[ "$cleanup" == "true" ]]; then
    echo "→ Removing $venv"; rm -rf "$venv"
  fi

  if [[ ${#failed_pids[@]} -gt 0 ]]; then
    echo "The following background processes exited with nonzero status: ${failed_pids[@]}"
    exit 1
  fi
  ' EXIT

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
      $2 &
      echo "... started with PID: $!"
      sleep 5
      shift
      shift
      ;;
    -f|--foreground)
      echo "→ Starting foreground task: $2"
      if [[ "$2" == *.py ]] && [[ "$2" != *[[:space:]]* ]]; then
        python "$2"
      else
        $2
      fi
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
