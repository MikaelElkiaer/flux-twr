#!/usr/bin/env bash

set -Eeuo pipefail

OUTPUT_DIR="$(pwd)/monitoring/mixins/"

function build {
  mixin="$1"
  echo "Building $mixin"
  cd "$mixin" || true
  mkdir -p build
  jb install
  jsonnet -J vendor -e '(import "mixin.libsonnet")' -m "build"
  mkdir -p "$OUTPUT_DIR"
  for file in build/*.json; do
    YAML_FILE="$(basename "${file%.json}.yaml")"
    yq "$file" -p json >"$OUTPUT_DIR/$YAML_FILE"
  done
}

find ./mixins -maxdepth 1 -type d -name "*-mixin" | while read -r mixin; do
  build "$mixin"
done
