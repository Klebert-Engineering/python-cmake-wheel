#!/usr/bin/env bash

in_whl=$1
out_dir=$2
dylib_dirname=$3

set -ex
cd "$(mktemp -d)"
unzip "$in_whl"

# Print the contents of the current directory after unzipping
echo "Contents of directory after unzipping wheel:"
ls -l

DYLD_FALLBACK_LIBRARY_PATH=/usr/local/lib delocate-path -L "$dylib_dirname" .

# Print the contents of the current directory after running delocate-path
echo "Contents of directory after running delocate-path:"
ls -l

# Print the contents of /usr/local/lib
echo "Contents of /usr/local/lib:"
ls -l /usr/local/lib

wheel=$(basename "$in_whl")
zip -r "$wheel" ./*
mkdir -p "$out_dir"
mv "$wheel" "$out_dir"
tempdir=$(pwd)
cd -
rm -rf "$tempdir"
