# NVKE 国内可跟做部署配套

> 上游仓库：[dsx-ai-factory/nvke](https://github.com/dsx-ai-factory/nvke)（**Apache-2.0**，见上游 [`LICENSE`](https://github.com/dsx-ai-factory/nvke/blob/main/LICENSE) / [`NOTICE`](https://github.com/dsx-ai-factory/nvke/blob/main/NOTICE)）  
> 官方文档：https://docs.nvidia.com/nvke/ · 仓内 docs：[`docs/`](https://github.com/dsx-ai-factory/nvke/tree/main/docs)  
> 本地评估：[quickstart-local.md](https://github.com/dsx-ai-factory/nvke/blob/main/docs/get-started/quickstart-local.md)（mock-NICo，可不需真 GPU）  
> 正式安装规划：[plan-installation.md](https://github.com/dsx-ai-factory/nvke/blob/main/docs/operate/plan-installation.md)（真实 **NICo** + 自建节点镜像）  
> 本仓性质：**独立中文部署配套**（预检 / 钉 tag 浅克隆 / 编 `nvkectl` / 本地评估配置准备 / 国内网络与裸金属清单），**不是**官方镜像或 fork，也**不会**整页搬运上游 README。

NVIDIA Kubernetes Engine（NVKE）是装在自有 NVIDIA GPU 基础设施上的 **Kubernetes 管理面**：你运营管理集群，客户拿到各自的 workload 集群。当前为 **Preview**——API / 配置 / 行为可能随版本变化，**不建议生产**。

系列索引：[cn-deploy](https://github.com/fisheeplife-beep/cn-deploy)

---

## 验证边界（请先看）

| 路径 | 本仓作者环境验证状态（2026-11-09，Asia/Shanghai，Linux x86_64） |
|------|----------------------------------------------------------------|
| **上游身份 / 许可证** | ✅ **已确认** — `dsx-ai-factory/nvke` Apache-2.0；钉 **`v0.23.1`**（`347baab`） |
| **文档 / GitHub / Go proxy HTTP** | ✅ **已验证** — 见 [`examples/network-probe.txt`](./examples/network-probe.txt) |
| **浅克隆 + `go mod download` CAPNICo** | ✅ **已验证** — 见 [`examples/capnico-module.txt`](./examples/capnico-module.txt) |
| **`make -C cli build` → `nvkectl version`** | ✅ **已验证** — `nvkectl v0.23.1`。见 [`examples/nvkectl-version.txt`](./examples/nvkectl-version.txt) |
| **路径 A：kind + Tilt + mock-NICo 全栈** | ⚠️ **未验证** — 作者机 **无 Docker / kind / Helm 4 / tilt**；apt 源曾 500；可用内存 ~10 GiB **低于**上游「12 GiB 空闲」。脚本只做到配置准备 |
| **路径 B：裸金属 + 真实 NICo + 节点镜像** | ⚠️ **未验证** — 无 NICo / GPU 机器 / boot 制品托管。仅提供中文清单 |
| **生产加固（API OIDC / TLS / 备份）** | ⚠️ **未验证**（Preview 本身也无完整备份/管理面升级流程） |

摘要：[`examples/verification-boundary.txt`](./examples/verification-boundary.txt) · 主机快照：[`examples/host-snapshot.txt`](./examples/host-snapshot.txt)

---

## 选哪条路？

| 场景 | 推荐 |
|------|------|
| **先理解 NVKE、没有 GPU / NICo** | **路径 A：本机 mock-NICo 评估**（主推） |
| **AI 工厂 / 有 NICo 与 GPU 裸金属** | **路径 B：正式安装清单**（先读 Preview 限制） |
| **只想确认 CLI 能编出来** | `./scripts/clone-upstream.sh && ./scripts/build-nvkectl.sh` |
| **只测网络** | `./scripts/probe-network.sh` |

**主推：路径 A。** 没有 NICo 不要硬上路径 B。

---

## 环境要求（路径 A）

| 项 | 建议 |
|----|------|
| OS | Linux amd64/arm64 |
| 资源 | ≥6 CPU、**≥12 GiB 空闲内存**、≥100 GiB 空闲磁盘 |
| 软件 | Docker Engine + BuildKit、`kind` v0.32.0、kubectl、**Helm 4**、tilt、git、GNU Make、Go ≥1.27.3、gcc、jq、curl、nc、dpkg 工具 |
| 内核 | `tpm_vtpm_proxy`（`/dev/vtpmx`） |
| 系统 | `fs.inotify.max_user_instances` ≥ 1024 |
| 出网 | GitHub、Go module proxy、GHCR / registry.k8s.io 等（见 [`docs/china-network.md`](./docs/china-network.md)） |

```bash
git clone https://github.com/fisheeplife-beep/cn-deploy-nvke.git
cd cn-deploy-nvke
./scripts/preflight.sh
```

---

## 路径 A｜本地 mock-NICo（本仓主推）

```bash
./scripts/clone-upstream.sh          # 默认 NVKE_TAG=v0.23.1
./scripts/build-nvkectl.sh
./scripts/prepare-local-eval.sh      # CAPNICo 拷贝 + tilt_config.json + .env.tilt
```

随后在 **已装 Docker/kind/tilt/Helm4** 的机器上按 [`docs/local-eval.md`](./docs/local-eval.md) 继续：`host-up` → `capd-up` → `tilt up` → `nvkectl create cluster`。

Lab 密码模板：[`local/.env.tilt.example`](./local/.env.tilt.example)（**勿用于生产**）。

> 本项目**不是**「一条 `docker compose up`」类服务；本地评估是 **kind 管理面 + Tilt 拉起控制器 + mock-NICo 容器节点**。因此本仓不提供 Compose 主路径。

---

## 路径 B｜裸金属 + NICo

见 [`docs/bare-metal.md`](./docs/bare-metal.md)。核心差异：自建节点镜像与 registry、真实 NICo、bootstrap 主机要用 **nerdctl（非 Docker）**、安装后必须处理 **明文 API / 默认无认证**。

---

## 国内网络 / 排障

- [`docs/china-network.md`](./docs/china-network.md) — GOPROXY、镜像 save/load、代理  
- [`docs/troubleshooting.md`](./docs/troubleshooting.md)

---

## 安全注意（勿裸奔）

1. Preview：**不建议生产**；管理面无自升级、无官方备份恢复流程。  
2. 安装后 NVKE API 默认 **:30080 HTTP + 认证关闭**——先收紧网络再开 OIDC。  
3. Lab 的 kubeconfig / `.env.tilt` 含管理凭据，勿提交、勿暴露。  
4. 上游 Apache-2.0；本配套脚本与文档 **MIT**，不重新授权上游代码或镜像。

---

## 开源边界

- 行为以 [nvke](https://github.com/dsx-ai-factory/nvke) 与 [docs.nvidia.com/nvke](https://docs.nvidia.com/nvke/) 为准。  
- 商标：Kubernetes®、NVIDIA® 等归各自权利人；本仓仅为社区跟做笔记。  
- 未向上游开 Issue（工程 Issue 队列活跃，空要「中文配套」易像 spam）；有跟做结果后再考虑 Discussions。

---

## 系列

- 索引：[cn-deploy](https://github.com/fisheeplife-beep/cn-deploy)  
- 体检：[cn-deploy-doctor](https://github.com/fisheeplife-beep/cn-deploy-doctor)  
- 选题：[trending-gap-radar](https://github.com/fisheeplife-beep/trending-gap-radar)  
- 同系列：[cn-deploy-n8n](https://github.com/fisheeplife-beep/cn-deploy-n8n) · [cn-deploy-firecrawl](https://github.com/fisheeplife-beep/cn-deploy-firecrawl) · [cn-deploy-openclaw](https://github.com/fisheeplife-beep/cn-deploy-openclaw)
