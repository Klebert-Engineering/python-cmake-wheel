#!/usr/bin/env bash

image_name="manylinux-cpp17-py"
version="2025.1"
push=""
latest=""
python_versions=(3.9.13 3.10.9 3.11.1 3.12.4 3.13.1)
architecture=x86_64

while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--version)
      version=$2
      shift
      shift
      ;;
    -p|--push)
      push="yes"
      shift
      ;;
    -l|--latest)
      latest="yes"
      shift
      ;;
    -a|--arch)
      architecture=$2
      shift
      shift
      ;;
  esac
done


for pyver_long in "${python_versions[@]}"; do

    pyver_short=$(echo "$pyver_long" | sed "s/\\.[0-9]\+\$//")

    echo "Building $architecture manylinux Docker image for Python $pyver_short ($pyver_long)..."

    dockerfile="Dockerfile-$pyver_long-$architecture"

    sed -e "s/\${pyver_long}/$pyver_long/g" \
        -e "s/\${pyver_short}/$pyver_short/g" \
        -e "s/\${architecture}/$architecture/g" \
        Dockerfile.template > $dockerfile

    image_name_full="ghcr.io/klebert-engineering/$image_name$pyver_short-$architecture"
    docker build -t "$image_name_full:$version" -f $dockerfile .

    if [[ -n "$latest" ]]; then
      echo "Tagging latest."
      docker tag "$image_name_full:$version" "$image_name_full:latest"
    fi

    if [[ -n "$push" ]]; then
      echo "Pushing."
      docker push "$image_name_full:$version"
      if [[ -n "$latest" ]]; then
        docker push "$image_name_full:latest"
      fi
    fi

done
