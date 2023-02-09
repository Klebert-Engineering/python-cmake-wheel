#!/usr/bin/env bash

image_name="manylinux-cpp17-py"
version="2023.1"
push=""
latest=""
python_versions=(3.8.10 3.9.13 3.10.9 3.11.1)

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
  esac
done


for pyver_long in "${python_versions[@]}"; do

    pyver_short=$(echo "$pyver_long" | sed "s/\\.[0-9]\+\$//")

    echo "Building manylinux Docker image for Python $pyver_short ($pyver_long)..."

    sed -e "s/\${pyver_long}/$pyver_long/g" \
        -e "s/\${pyver_short}/$pyver_short/g" \
        Dockerfile.template > "Dockerfile-$pyver_long"

    image_name_full="ghcr.io/klebert-engineering/$image_name$pyver_short"
    docker build -t "$image_name_full:$version" -f "Dockerfile-$pyver_long" .

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
