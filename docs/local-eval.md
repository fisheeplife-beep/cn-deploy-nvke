# 路径 A：本机 mock-NICo 评估（主推）

对齐上游：[Quickstart: evaluate locally with mock-NICo](https://github.com/dsx-ai-factory/nvke/blob/main/docs/get-started/quickstart-local.md)  
官方站点文档：https://docs.nvidia.com/nvke/

**不需要** NVIDIA 账号、真 GPU 或真实 NICo。mock-NICo（`nico-sim`）用 Docker 容器模拟节点。

## 资源与工具（上游硬要求）

| 项 | 要求 |
|----|------|
| OS | Linux amd64/arm64（本页不含 macOS；macOS 见上游 `local-site.md` + Colima） |
| CPU / 内存 / 磁盘 | ≥6 CPU、**≥12 GiB 空闲内存**、≥100 GiB 空闲磁盘 |
| 内核 | `tpm_vtpm_proxy`（`/dev/vtpmx`）；Debian/Ubuntu 上由 `make -C controller host-up` 处理，需 sudo |
| 运行时 | Docker Engine + BuildKit（用户可无 sudo 使用） |
| 工具 | git、GNU Make、Go ≥1.27.3、gcc、`kind` **v0.32.0**、kubectl、**Helm 4**、tilt、jq、curl、nc、`dpkg-deb`、`dpkg-scanpackages` |
| 系统 | `fs.inotify.max_user_instances` ≥ 1024 |
| 端口 | 勿占用 179、5432、7233、8080、8081、10350、18080、30440、30443 |

## 本仓包装步骤

```bash
git clone https://github.com/fisheeplife-beep/cn-deploy-nvke.git
cd cn-deploy-nvke
./scripts/preflight.sh          # 缺 Docker/kind/tilt 会红灯——请先装
./scripts/clone-upstream.sh     # 钉 v0.23.1（可用 NVKE_TAG 覆盖）
./scripts/build-nvkectl.sh
./scripts/prepare-local-eval.sh # CAPNICo 拷贝 + tilt_config + .env.tilt
```

然后进入上游树（与官方文档一致）：

```bash
cd data/upstream-nvke
export PATH="$PWD/cli/bin:$PATH"

# 若 inotify 过低：
sudo sysctl -w fs.inotify.max_user_instances=1024

make -C controller host-up      # 加载 vtpm
make -C controller capd-up      # kind 管理面 + Cluster API + 节点镜像（耗时长、吃磁盘）
cd controller && tilt up          # 等全部资源变绿
```

另开终端：

```bash
cd data/upstream-nvke
export PATH="$PWD/cli/bin:$PATH"
kubectl config view --raw --minify --context kind-controller-capi > local-mgmt.kubeconfig
chmod 600 local-mgmt.kubeconfig
nvkectl config set-site --name local --url http://localhost:8080 --kubeconfig "$PWD/local-mgmt.kubeconfig"
nvkectl get providers            # nico 应为 CONFIGURED
nvkectl create cluster -f cli/examples/nico-mock-cluster.yaml
nvkectl get clusters             # 等到 Provisioned
nvkectl get kubeconfig my-cluster --output-file my-cluster.kubeconfig
kubectl --kubeconfig my-cluster.kubeconfig get nodes --watch
```

清理见上游 quickstart「Clean up」；勿把 lab 密码与 kubeconfig 提交进 Git。

## 成功长什么样

1. Tilt UI 全部绿（含 `nico-sim`、`capnico-provider`、`nvke-controller`）。  
2. `nvkectl get clusters` 中 `my-cluster` 为 `Provisioned`。  
3. 工作负载集群两个节点均为 `Ready`。

## 与官方差异

- 本仓只做**预检 / 浅克隆 / 编 CLI / 写配置**；**不**替代 `capd-up` / `tilt up`。  
- 钉 tag 默认 **`v0.23.1`**；升级请改 `NVKE_TAG` 并重读该 tag 的 docs（Preview API 会变）。  
- 示例密码仅 lab 用。
