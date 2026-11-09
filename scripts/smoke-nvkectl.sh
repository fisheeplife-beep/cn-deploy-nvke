#!/usr/bin/env bash
# Smoke: confirm nvkectl binary builds and reports a version.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${NVKE_DEST:-data/upstream-nvke}"
BIN="$ROOT/$DEST/cli/bin/nvkectl"
if [[ ! -x "$BIN" ]]; then
  "$ROOT/scripts/build-nvkectl.sh"
fi
echo "=== smoke-nvkectl $(date '+%Y-%m-%d %H:%M %Z') ==="
"$BIN" version
"$BIN" --help 2>&1 | head -40 || true
echo "OK — CLI smoke only. Full mock-NICo / bare-metal paths not covered here."
