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

# Set the DYLD_FALLBACK_LIBRARY_PATH to include /usr/local/lib
export DYLD_FALLBACK_LIBRARY_PATH="/usr/local/lib"

# Add all subdirectories in the current directory to DYLD_FALLBACK_LIBRARY_PATH
for dir in $(find . -type d); do
    export DYLD_FALLBACK_LIBRARY_PATH="${DYLD_FALLBACK_LIBRARY_PATH}:$(pwd)/$dir"
done

delocate-path -L "$dylib_dirname.dylibs" .

wheel=$(basename "$in_whl")
zip -r "$wheel" ./*
mkdir -p "$out_dir"
mv "$wheel" "$out_dir"
tempdir=$(pwd)
cd -
rm -rf "$tempdir"
