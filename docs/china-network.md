# 国内网络说明（NVKE）

NVKE 本地评估与正式安装都依赖外网拉代码、Go module、容器镜像与（正式路径）节点镜像制品。国内常见卡点如下。

## 你会碰到什么

| 依赖 | 用途 | 国内常见问题 |
|------|------|--------------|
| `github.com/dsx-ai-factory/nvke` | 源码 / release tag | clone 慢或中断 |
| `proxy.golang.org` / `sum.golang.org` | 编 `nvkectl`、CAPNICo、控制器 | 超时；可换 `GOPROXY` |
| `ghcr.io` | CAPNICo 等公开镜像 | 拉不动；需代理或私有镜像仓库 |
| `registry.k8s.io` 及 kind 节点镜像 | kind 管理面、Kubernetes 组件 | 需镜像加速或事先 `docker load` |
| Docker Hub | 部分基础镜像 | 限流 / 超时 |
| `docs.nvidia.com/nvke` | 官方文档 | 一般可访问；弱网可离线翻上游 `docs/` |

本地 quickstart **明确要求** outbound 到 GitHub、Go module proxy 与公共容器仓库。正式安装还要能从你自建的 registry / HTTP(S) boot 端点拉节点 OS 镜像（NVKE **不**在 GitHub Release 里发节点镜像二进制包）。

## 建议做法（择一）

1. **给 Docker / shell 配可出网代理**（公司代理或自建），保证 `docker pull` 与 `go mod download` 成功。  
2. **Go：** `export GOPROXY=https://goproxy.cn,direct`（或你们内网 Athens），`GOSUMDB=sum.golang.google.cn` 按环境调整。  
3. **镜像：** 把 kind 节点镜像、CAPNICo、registry.k8s.io 组件预先在可出网机器 `docker pull` + `docker save`，再拷到内网 `docker load`。  
4. **Git：** 用镜像站 / `git clone` 重试 / 加大 `http.postBuffer`；本仓 `clone-upstream.sh` 用 `--depth 1 --branch <tag>` 减小体积。  
5. **正式路径：** 自建 registry + HTTP(S) 托管 boot 制品；见上游 [Build and host node OS images](https://github.com/dsx-ai-factory/nvke/blob/main/docs/operate/build-node-images.md)。

## 探针

```bash
./scripts/probe-network.sh
./scripts/preflight.sh
```

`ghcr.io/v2` / `registry.k8s.io/v2` 返回 **401** 通常表示**可达但要鉴权**，不要当成「挂了」。

## 不要做的事

- 不要在文档里写死某个不可用的「破解镜像站」列表当唯一方案。  
- 不要把生产 NICo / registry 凭据提交进 Git。  
- Preview 阶段 API 默认明文 HTTP 且认证关闭——即使网络通了，也别裸奔公网。
