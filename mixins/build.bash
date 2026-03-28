#!/usr/bin/env bash

set -Eeuo pipefail

OUTPUT_DIR="$(pwd)/monitoring/mixins/"

function build {
  mixin="$1"
  echo "Building $mixin"
  cd "$mixin" || true
  mkdir -p "$OUTPUT_DIR"
  jb install
  jsonnet -J vendor -e '(import "mixin.libsonnet")' -m "$OUTPUT_DIR"
}

find ./mixins -maxdepth 1 -type d -name "*-mixin" | while read -r mixin; do
  build "$mixin"
done
