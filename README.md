# cn-deploy-nvke

Chinese, follow-along **deployment companion** for [dsx-ai-factory/nvke](https://github.com/dsx-ai-factory/nvke) (NVIDIA Kubernetes Engine) — not an official fork, and not a verbatim copy of upstream docs.

**Start here (ZH):** [README.zh-CN.md](./README.zh-CN.md)

### What you get

- Preflight for the official **local mock-NICo** evaluation host
- Pin-tag shallow clone + `nvkectl` build helpers
- `prepare-local-eval.sh` (CAPNICo copy, `tilt_config.json`, lab `.env.tilt`)
- China network notes + bare-metal / real **NICo** checklist (honest: not run here)

### Verification snapshot (author box, 2026-11-09, Asia/Shanghai, Linux x86_64)

| Path | Status |
|------|--------|
| Upstream Apache-2.0 identity + pin `v0.23.1` | **Confirmed** |
| Network probes (GitHub / docs / Go proxy; GHCR & registry.k8s.io HTTP 401) | **Verified** |
| Shallow clone + CAPNICo `go mod download` | **Verified** |
| `make -C cli build` → `nvkectl v0.23.1` | **Verified** |
| Full kind + Tilt + mock-NICo create-cluster | **Not verified** (no Docker/kind/tilt on author box; RAM headroom below 12 GiB free) |
| Bare-metal + real NICo | **Not verified** |

Pinned baseline: **NVKE `v0.23.1`**. Details in `examples/`.

### Quick start (CLI only)

```bash
./scripts/preflight.sh
./scripts/clone-upstream.sh
./scripts/build-nvkectl.sh
./scripts/smoke-nvkectl.sh
# On a Docker+kind+tilt host, continue with:
./scripts/prepare-local-eval.sh
# then docs/local-eval.md
```

### License

Companion scripts/docs: **MIT**. Upstream NVKE: **Apache-2.0**.
