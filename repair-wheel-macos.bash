#!/usr/bin/env bash

in_whl=$1
out_dir=$2
dylib_dirname=$3

set -ex
cd "$(mktemp -d)"
unzip "$in_whl"

# Print the contents of the current directory after unzipping
echo "\nContents of directory after unzipping wheel ..."
ls -l

echo "\nDelocating ..."
DYLD_FALLBACK_LIBRARY_PATH=/usr/local/lib delocate-path -L "$dylib_dirname.dylibs" .

echo "\nRepackaging ..."
wheel=$(basename "$in_whl")
zip -r "$wheel" ./*
mkdir -p "$out_dir"
mv "$wheel" "$out_dir"
tempdir=$(pwd)
cd -
rm -rf "$tempdir"

echo "\nDone."
