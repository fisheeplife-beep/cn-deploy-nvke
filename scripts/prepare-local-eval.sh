#!/usr/bin/env bash
# Prepare upstream tree for official local mock-NICo quickstart (does NOT start kind/tilt).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${NVKE_DEST:-data/upstream-nvke}"
ABS="$ROOT/$DEST"
if [[ ! -d "$ABS/.git" ]]; then
  "$ROOT/scripts/clone-upstream.sh"
fi
cd "$ABS"

# CAPNICo pinned copy next to the clone (official quickstart layout)
CAP_PARENT="$(cd "$ABS/.." && pwd)"
CAP_DEST="${CAPNICO_ABS:-$CAP_PARENT/nvke-quickstart-capnico}"
if [[ -d "$CAP_DEST" ]]; then
  echo "CAPNICo copy already exists: $CAP_DEST (move it aside if stale)"
else
  echo "Downloading pinned CAPNICo module…"
  CAPNICO_MODULE_DIR="$(cd "$ABS/controller" && GOWORK=off go mod download -json github.com/dsx-ai-factory/cluster-api-provider-nico | jq -r .Dir)"
  mkdir -p "$CAP_DEST"
  cp -R "$CAPNICO_MODULE_DIR/." "$CAP_DEST/"
  chmod -R u+w "$CAP_DEST"
  test -f "$CAP_DEST/chart/Chart.yaml"
  echo "CAPNICo → $CAP_DEST"
fi

# tilt_config.json
cat > "$ABS/controller/tilt_config.json" <<'JSON'
{
  "providers": ["capi_core", "bgp-containers", "nico"],
  "nico_sim_backends": ["container"],
  "capnico_source_dir": "../../nvke-quickstart-capnico"
}
JSON
echo "wrote controller/tilt_config.json"

# .env.tilt
if [[ ! -f "$ABS/controller/.env.tilt" ]]; then
  if [[ -f "$ROOT/local/.env.tilt.example" ]]; then
    # merge: start from upstream example then overlay lab passwords
    cp "$ABS/controller/.env.tilt.example" "$ABS/controller/.env.tilt"
    # fill the five empty required keys from our example
    while IFS='=' read -r k v; do
      [[ -z "${k:-}" || "$k" =~ ^# ]] && continue
      # replace empty KEY= lines
      if grep -qE "^${k}=$" "$ABS/controller/.env.tilt"; then
        sed -i "s|^${k}=$|${k}=${v}|" "$ABS/controller/.env.tilt"
      fi
    done < "$ROOT/local/.env.tilt.example"
  else
    cp "$ABS/controller/.env.tilt.example" "$ABS/controller/.env.tilt"
  fi
  echo "wrote controller/.env.tilt (lab passwords — not for production)"
else
  echo "controller/.env.tilt already present — left unchanged"
fi

echo ""
echo "Next (on a host with Docker + kind + Helm 4 + tilt):"
echo "  cd $ABS"
echo "  make -C cli build && export PATH=\"\$PWD/cli/bin:\$PATH\""
echo "  sudo sysctl -w fs.inotify.max_user_instances=1024   # if needed"
echo "  make -C controller host-up"
echo "  make -C controller capd-up"
echo "  cd controller && tilt up"
echo "Then follow docs/local-eval.md / upstream quickstart-local.md"
