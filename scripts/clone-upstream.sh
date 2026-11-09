#!/usr/bin/env bash
# Shallow clone dsx-ai-factory/nvke at a pinned tag.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TAG="${NVKE_TAG:-v0.23.1}"
DEST="${NVKE_DEST:-data/upstream-nvke}"
ABS="$ROOT/$DEST"
mkdir -p "$(dirname "$ABS")"
if [[ -d "$ABS/.git" ]]; then
  echo "Already cloned: $ABS"
  git -C "$ABS" fetch --depth 1 origin "refs/tags/${TAG}:refs/tags/${TAG}" 2>/dev/null || true
  git -C "$ABS" checkout -q "tags/${TAG}" 2>/dev/null || git -C "$ABS" checkout -q "$TAG" || true
  git -C "$ABS" describe --tags --always
  exit 0
fi
git clone --depth 1 --branch "$TAG" https://github.com/dsx-ai-factory/nvke.git "$ABS"
echo "OK $TAG → $ABS"
git -C "$ABS" describe --tags --always
