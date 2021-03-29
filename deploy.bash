#!/usr/bin/env bash

image_name="manylinux-cpp17-py3.8"
version="2021.1"
push=""
latest=""
test=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -i|--image-name)
      image_name=$2
      shift
      shift
      ;;
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
    -t|--test)
      test="yes"
      shift
      ;;
  esac
done

image_name="ghcr.io/klebert-engineering/$image_name"
docker build -t "$image_name:$version" .

if [[ -n "$latest" ]]; then
  echo "Tagging latest."
  docker tag "$image_name:$version" "$image_name:latest"
fi

if [[ -n "$push" ]]; then
  echo "Pushing."
  docker push "$image_name:$version"
  if [[ -n "$latest" ]]; then
    docker push "$image_name:latest"
  fi
fi
