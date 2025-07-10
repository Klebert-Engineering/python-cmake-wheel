#!/usr/bin/env bash

image_name="manylinux-cpp17-py"
version="2025.1"
push=""
latest=""
python_versions=(3.9 3.10 3.11 3.12 3.13)
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

# Validate architecture
if [[ "$architecture" != "x86_64" && "$architecture" != "aarch64" ]]; then
  echo "Error: Unsupported architecture '$architecture'. Supported architectures are: x86_64, aarch64"
  exit 1
fi


for pyver in "${python_versions[@]}"; do

    echo "Building $architecture manylinux Docker image for Python $pyver..."

    dockerfile="Dockerfile-$pyver-$architecture"

    pyver_no_dot=$(echo $pyver | tr -d '.')
    sed -e "s/\${pyver_short}/$pyver/g" \
        -e "s/\${pyver_short_no_dot}/$pyver_no_dot/g" \
        -e "s/\${architecture}/$architecture/g" \
        Dockerfile.template > $dockerfile

    image_name_full="ghcr.io/klebert-engineering/$image_name$pyver-$architecture"
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
