# 路径 B：自有机器 + 真实 NICo（清单，未在本仓实测）

对齐上游：[Plan your installation](https://github.com/dsx-ai-factory/nvke/blob/main/docs/operate/plan-installation.md)  
平台版本：[Supported platforms](https://github.com/dsx-ai-factory/nvke/blob/main/docs/overview/supported-platforms.md)  
Preview 限制：[Preview status](https://github.com/dsx-ai-factory/nvke/blob/main/docs/overview/preview-status.md)

> **本仓作者环境没有 NICo、没有 GPU 裸金属、没有可引导节点镜像托管。** 以下是跟做清单与国内差异提示，**不是**已跑通的安装记录。

## 你最终得到什么

奇数台管理面节点上的 **management cluster**，其上跑 NVKE management plane；通过 **CAPNICo → NICo** 为客户创建独立 **workload cluster**（各自控制面 / etcd / node pool）。

## 七步（顺序不要跳）

| 步 | 做什么 | 上游文档 |
|----|--------|----------|
| 1 | 构建并 HTTP(S) 托管节点 OS 镜像 | build-node-images |
| 2 | 用 cloud-init 准备管理节点，记录 TPM EK 指纹 | prepare-nodes |
| 3 | `nvkectl bootstrap site` 成形管理集群 | bootstrap-management-cluster |
| 4 | 安装 CAPI / CAPNICo / SPIRE / 遥测 / NVKE API | install-management-plane |
| 5 | 配置 NICo（org/site/vpc/instance type/token） | provider-nico |
| 6 | 打开 API 认证（默认明文 HTTP + 无认证） | api-authentication |
| 7 | 创建 workload cluster | workload-clusters/create |

## 国内容易翻车的点

1. **镜像与制品**：NVKE **不**在 GitHub Release 发可用节点镜像；你要自己 build（NVKR 或仓内 os-image）并放到可达的 registry / HTTP(S)。跨境拉基础层极慢。  
2. **NICo**：Preview 默认基础设施提供者就是 NICo（LaunchLayer 需另行启用）。没 NICo 就没有正式路径——请先走路径 A。  
3. **Bootstrap 主机**：需要 **rootful nerdctl + containerd**；文档写明 **Docker 不支持** bootstrap。  
4. **工具钉版本**：`kind` v0.32.0、`clusterctl` v1.13.6、Helm **v4.2.4**、kubectl CI 钉 v1.36.0、K8s **1.36.3**、CAPNICo **v0.1.0**。Helm 3 装不了这些 chart。  
5. **安全默认值危险**：安装后 API 在 **:30080 明文 HTTP** 且认证关闭；必须收紧网络并按文档开 OIDC。  
6. **管理面不能自升级 / 无备份恢复流程**（Preview 已知限制）——节点数与 etcd 加密在 bootstrap 时定终身。  
7. **驱动 / GPU**：workload 上的加速运行时属 AICR 等相邻项目；本仓不覆盖 GPU Operator 安装。

## 开始前建议你填的值

至少准备：SPIFFE trust domain、自签 SPIRE CA、管理面 VIP（多节点时）、NICo endpoint/org/token/site/vpc/instance type、自控 registry、节点 TPM 指纹表。完整表见上游 plan-installation「Fill in your values」。

## 与路径 A 的关系

路径 A 用 mock-NICo + kind 验证「管理面 + 创建集群」心智模型；**不能**替代 NICo 正式安装。先 A 后 B。
