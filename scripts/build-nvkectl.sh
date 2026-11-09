#!/usr/bin/env bash
# Build nvkectl from the cloned upstream tree.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${NVKE_DEST:-data/upstream-nvke}"
ABS="$ROOT/$DEST"
if [[ ! -f "$ABS/cli/Makefile" ]]; then
  echo "upstream missing — run ./scripts/clone-upstream.sh first" >&2
  exit 1
fi
if ! command -v make >/dev/null 2>&1; then
  echo "GNU Make required" >&2
  exit 1
fi
if ! command -v go >/dev/null 2>&1; then
  echo "Go 1.27.3+ required" >&2
  exit 1
fi
make -C "$ABS/cli" build
BIN="$ABS/cli/bin/nvkectl"
"$BIN" version
echo "Add to PATH: export PATH=\"$ABS/cli/bin:\$PATH\""
