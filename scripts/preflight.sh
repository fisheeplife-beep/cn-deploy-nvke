#!/usr/bin/env bash
# NVKE CN preflight — local mock-NICo eval host readiness.
set -euo pipefail

ok=0; warn=0; bad=0
say() { printf '%s\n' "$*"; }
pass() { say "✅ $*"; ok=$((ok+1)); }
warn_() { say "⚠️  $*"; warn=$((warn+1)); }
fail() { say "❌ $*"; bad=$((bad+1)); }

say "=== NVKE CN preflight (local mock-NICo) ==="
say ""
say "Host: $(uname -s) $(uname -m)"
say "Time: $(date '+%Y-%m-%d %H:%M %Z')"
say ""

arch=$(uname -m)
case "$arch" in
  x86_64|amd64|aarch64|arm64) pass "CPU arch $arch" ;;
  *) fail "Unsupported arch $arch (need amd64 or arm64)" ;;
esac

# CPUs
cpus=$(nproc 2>/dev/null || echo 0)
if [[ "$cpus" -ge 6 ]]; then pass "CPUs $cpus (≥6)"; else warn_ "CPUs $cpus — upstream asks ≥6"; fi

# Memory: prefer MemAvailable
if [[ -r /proc/meminfo ]]; then
  avail_kb=$(awk '/MemAvailable/{print $2}' /proc/meminfo)
  avail_gib=$((avail_kb / 1024 / 1024))
  total_kb=$(awk '/MemTotal/{print $2}' /proc/meminfo)
  total_gib=$((total_kb / 1024 / 1024))
  if [[ "$avail_gib" -ge 12 ]]; then
    pass "RAM available ~${avail_gib} GiB (total ~${total_gib} GiB)"
  elif [[ "$total_gib" -ge 12 ]]; then
    warn_ "RAM available ~${avail_gib} GiB / total ~${total_gib} GiB — upstream wants ≥12 GiB free; close apps or add swap"
  else
    fail "RAM total ~${total_gib} GiB — below 12 GiB free requirement for local eval"
  fi
fi

# Disk
if df -Pk . >/dev/null 2>&1; then
  avail_kb=$(df -Pk . | awk 'NR==2{print $4}')
  avail_gb=$((avail_kb / 1024 / 1024))
  if [[ "$avail_gb" -ge 100 ]]; then pass "Disk free ~${avail_gb} GB (≥100)"; else warn_ "Disk free ~${avail_gb} GB — upstream asks ≥100 GiB"; fi
fi

# Required tools for local quickstart
req_fail=(docker kind kubectl helm tilt git curl jq)
req_soft=(make go gcc nc dpkg-deb dpkg-scanpackages)
for t in git curl jq; do
  if command -v "$t" >/dev/null 2>&1; then pass "$t present"; else fail "$t missing"; fi
done
if command -v make >/dev/null 2>&1; then pass "make: $(make --version 2>/dev/null | head -1)"; else fail "GNU Make missing"; fi
if command -v go >/dev/null 2>&1; then
  gv=$(go version 2>/dev/null || true)
  pass "go: $gv"
  # warn if older than 1.27
  if ! go version | grep -Eq 'go1\.(2[7-9]|[3-9][0-9])'; then
    warn_ "Go < 1.27.3 — build still works if GOTOOLCHAIN can download (unset GOTOOLCHAIN=local)"
  fi
else
  fail "Go missing (need 1.27.3+ to build nvkectl / CAPNICo)"
fi
if command -v gcc >/dev/null 2>&1 || command -v cc >/dev/null 2>&1; then pass "C compiler present"; else warn_ "gcc/cc missing — some builds need it"; fi
for t in nc dpkg-deb; do
  if command -v "$t" >/dev/null 2>&1; then pass "$t present"; else warn_ "$t missing (Debian/Ubuntu: netcat-openbsd + dpkg)"; fi
done
if command -v dpkg-scanpackages >/dev/null 2>&1; then pass "dpkg-scanpackages present"; else warn_ "dpkg-scanpackages missing (package dpkg-dev)"; fi

if command -v docker >/dev/null 2>&1; then
  pass "docker: $(docker --version 2>/dev/null | head -1)"
  if docker info >/dev/null 2>&1; then pass "docker daemon reachable"; else fail "docker daemon not reachable"; fi
else
  fail "Docker Engine missing — local eval uses kind + mock-NICo containers"
fi

for t in kind kubectl helm tilt; do
  if command -v "$t" >/dev/null 2>&1; then
    pass "$t: $($t version 2>/dev/null | head -1 || $t --version 2>/dev/null | head -1 || echo present)"
  else
    fail "$t missing — install before capd-up / tilt up (kind v0.32.0, Helm 4, kubectl, tilt)"
  fi
done

# inotify
if sysctl fs.inotify.max_user_instances >/dev/null 2>&1; then
  cur=$(sysctl -n fs.inotify.max_user_instances 2>/dev/null || echo 0)
  if [[ "$cur" -ge 1024 ]]; then pass "fs.inotify.max_user_instances=$cur"; else warn_ "fs.inotify.max_user_instances=$cur — raise to ≥1024 before tilt up"; fi
else
  warn_ "cannot read fs.inotify.max_user_instances"
fi

# vtpm hint
if [[ -e /dev/vtpmx ]]; then pass "/dev/vtpmx present"; else warn_ "/dev/vtpmx missing — run: make -C controller host-up (needs sudo + tpm_vtpm_proxy)"; fi

# ports (best-effort)
ports=(179 5432 7233 8080 8081 10350 18080 30440 30443)
busy=()
if command -v ss >/dev/null 2>&1; then
  for p in "${ports[@]}"; do
    if ss -lnt 2>/dev/null | grep -qE ":${p}\\s"; then busy+=("$p"); fi
  done
elif command -v netstat >/dev/null 2>&1; then
  for p in "${ports[@]}"; do
    if netstat -lnt 2>/dev/null | grep -qE ":${p}\\s"; then busy+=("$p"); fi
  done
fi
if [[ ${#busy[@]} -eq 0 ]]; then pass "quickstart ports look free (best-effort)"; else warn_ "ports possibly busy: ${busy[*]}"; fi

say ""
say "--- network (best-effort) ---"
probe() {
  local name="$1" url="$2"
  local code
  code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 12 -L "$url" 2>/dev/null || true)
  [[ "$code" =~ ^[0-9]{3}$ ]] || code="000"
  # 401 on registry v2 root is OK (auth required)
  if [[ "$code" =~ ^(200|301|302|401|403)$ ]]; then pass "Reachable: $name (HTTP $code)"; else warn_ "Unreachable/slow: $name ($url → HTTP $code)"; fi
}
probe "GitHub nvke" "https://github.com/dsx-ai-factory/nvke"
probe "docs.nvidia.com/nvke" "https://docs.nvidia.com/nvke/"
probe "proxy.golang.org" "https://proxy.golang.org/"
probe "ghcr.io" "https://ghcr.io/v2/"
probe "registry.k8s.io" "https://registry.k8s.io/v2/"

say ""
say "=== summary: ${ok} ok / ${warn} warn / ${bad} bad ==="
say "Local eval needs Docker + kind + Helm 4 + tilt + ≥12GiB free RAM. Bare-metal/NICo path is a separate checklist (docs/bare-metal.md)."
[[ "$bad" -gt 0 ]] && exit 1
exit 0
