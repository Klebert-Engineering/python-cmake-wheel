#!/usr/bin/env bash

my_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
. "$my_dir/python.bash"

venv=$(mktemp -d)
echo "→ Setting up a virtual environment in $venv ..."
python3 -m venv "$venv"
source "$venv/$activate_path"
python -m pip install -U pip
pip install pytest

trap '
  if [[ -n $(jobs -p) ]]; then
    echo "→ Killing $(jobs -p)"
    kill $(jobs -p)
  fi
  echo "→ Removing $venv"; rm -rf "$venv"' EXIT

while [[ $# -gt 0 ]]; do
  case $1 in
    -w|--wheels-dir)
      echo "→ Installing wheels from $2 ..."
      pip install --no-deps "$2"/*
      shift
      shift
      ;;
    -b|--background)
      echo "→ Launching Background Task $2 ..."
      $2 &
      sleep 5
      shift
      shift
      ;;
    -f|--foreground)
      echo "→ Starting $2 ..."
      $2
      shift
      shift
      ;;
  esac
done

exit 0
