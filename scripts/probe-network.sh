#!/usr/bin/env bash
# Best-effort HTTP probes for registries / docs / Go modules (no Docker needed).
set -euo pipefail
say() { printf '%s\n' "$*"; }
probe() {
  local name="$1" url="$2"
  local code
  code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 15 -L "$url" 2>/dev/null || true)
  [[ "$code" =~ ^[0-9]{3}$ ]] || code="000"
  say "$name	HTTP $code	$url"
}
say "=== NVKE network probe $(date '+%Y-%m-%d %H:%M %Z') ==="
probe "GitHub nvke" "https://github.com/dsx-ai-factory/nvke"
probe "GitHub CAPNICo" "https://github.com/dsx-ai-factory/cluster-api-provider-nico"
probe "docs.nvidia.com/nvke" "https://docs.nvidia.com/nvke/"
probe "proxy.golang.org" "https://proxy.golang.org/"
probe "sum.golang.org" "https://sum.golang.org/"
probe "ghcr.io/v2" "https://ghcr.io/v2/"
probe "registry.k8s.io/v2" "https://registry.k8s.io/v2/"
probe "hub.docker.com" "https://hub.docker.com/"
say "(registry /v2 roots often return 401 — that still means reachable)"
