# 排障速查

| 现象 | 可能原因 | 处理 |
|------|----------|------|
| `preflight` 报 Docker / kind / tilt missing | 工具未装 | 先装 Docker Engine、kind v0.32.0、Helm 4、tilt、kubectl |
| `tilt` 里 management plane 反复重启，`entr: cannot create kqueue` | inotify 默认太低 | `sudo sysctl -w fs.inotify.max_user_instances=1024` |
| `host-up` 失败 / 无 `/dev/vtpmx` | 未加载 `tpm_vtpm_proxy` 或无 sudo | 按上游在 Debian/Ubuntu 上重跑 `make -C controller host-up` |
| `go mod download` 超时 | 国内访问 proxy.golang.org | 设 `GOPROXY`，见 `china-network.md` |
| `docker pull` / kind 镜像失败 | GHCR / registry.k8s.io 受限 | 代理或 save/load，见 `china-network.md` |
| `nvkectl get providers` 中 nico 非 CONFIGURED | Tilt 未就绪 | 等 Tilt 全绿；查 `kubectl -n capnico-system logs deploy/controller-manager` |
| 集群 `ProvisioningFailed` | mock-NICo / 控制器错误 | Tilt 看 `nvke-controller`、`nico-sim` 日志 |
| 节点一直 NotReady | CNI / 网络未就绪 | `Provisioned` 后仍需 wait；`kubectl get nodes --watch` |
| 想当生产用 lab 栈 | lab 含示例密码、明文 API | **不要**；改走 bare-metal 并开认证 |
| apt 装不上依赖 | 沙箱/镜像源 500 | 换机器或手动装二进制；本作者机曾遇 apt mirror 500 |

更多以上游 docs 与 `#nvke` Slack / Discussions 为准。
