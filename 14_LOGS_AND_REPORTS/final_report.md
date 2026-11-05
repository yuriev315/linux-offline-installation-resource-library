# 最终报告

> **进行中：** VMware 虚拟机实测尚未结束，下表状态可能更新。

构建日期：2026-11-05。详细测试结果见 [VERIFICATION_REPORT.md](../00_DOCUMENTATION/VERIFICATION_REPORT.md)。

## 结论

Ubuntu 24.04 的离线安装、WSL2 和开发环境已在无网卡虚拟机中实测通过。VMware Workstation 离线安装成功，虚拟机内的 VMware Tools 和共享目录还在测试中。受许可限制的 14 个文件在仓库中只有 `.url` 占位。

## 交付物

| # | 交付物 | 状态 | 位置 |
|---:|---|---|---|
| 1 | Ubuntu Desktop ISO | 已交付（官方文件名为 24.04.5.1） | `01_UBUNTU_ISO/ubuntu_desktop` |
| 2 | Ubuntu Server ISO | 已交付 | `01_UBUNTU_ISO/ubuntu_server` |
| 3 | Ubuntu WSL rootfs | 已交付 | `02_WSL2/ubuntu_rootfs` |
| 4 | WSL2 离线组件 | Ubuntu rootfs 已交付；WSL MSI 为 `.url` 占位。已在 Windows 上实测通过 | `02_WSL2` |
| 5 | VMware Workstation 安装程序 | **`.url` 占位**，需从 Broadcom 下载。测试版本在 Windows 上安装成功 | `03_VMWARE/workstation_installers` |
| 6 | open-vm-tools | 已交付，软件包已测试，VMware 内运行测试中；VMware Tools ISO 为 `.url` 占位 | APT 仓库 |
| 7 | APT 离线仓库 | 已交付并验证 | `04_APT_OFFLINE_REPOSITORY` |
| 8 | 系统依赖 DEB | 已交付并验证 | APT 仓库，分组见 `05` |
| 9 | 开发工具 | 已交付并验证 | APT 仓库，分组见 `06`、`15` |
| 10 | Python 环境 | 已交付并验证 | APT 仓库和 `07` |
| 11 | 网络、存储和系统工具 | 已交付并验证 | APT 仓库，分组见 `05`、`09` |
| 12 | 配置文件 | 已交付；SSH 已实测，其余部分未在目标环境生效 | `11_CONFIGURATIONS` |
| 13 | 原生安装脚本 | 已交付并验证 | `10_INSTALLATION_SCRIPTS/ubuntu_native` |
| 14 | WSL2 脚本 | 已交付并在 Windows 上实测通过 | `10_INSTALLATION_SCRIPTS/ubuntu_wsl` |
| 15 | VMware 指南和脚本 | 已交付；建虚拟机和开机已在 VMware 中通过，Tools 和共享目录测试中 | `03_VMWARE`、`10_INSTALLATION_SCRIPTS/ubuntu_vmware` |
| 16 | APT 仓库配置脚本 | 已交付并验证 | `10_INSTALLATION_SCRIPTS/apt_offline` |
| 17 | SHA256 校验文件 | 已交付 | `12_CHECKSUMS_AND_METADATA/SHA256SUMS.txt` |
| 18 | 依赖关系清单 | 已交付 | `12_CHECKSUMS_AND_METADATA/PACKAGE_DEPENDENCIES.csv` |
| 19 | 下载来源清单 | 已交付 | `12_CHECKSUMS_AND_METADATA/DOWNLOAD_URLS.md` |
| 20 | 断网安装验证报告 | 已交付 | `00_DOCUMENTATION/VERIFICATION_REPORT.md` |

补充要求的开发环境（C/C++、Python、Shell、Java、Node.js、Go、Rust、PHP、编辑器、调试工具、Hello World 示例和验证脚本）已全部交付，并通过 56 项验证。VS Code 在仓库中是 `.url` 占位。

## 与原要求不同之处

| 原要求 | 实际做法 | 原因 |
|---|---|---|
| Desktop 24.04.5 | Desktop **24.04.5.1** | 官方只提供这个文件名 |
| 单独存放 `05`–`09` 的 DEB 包 | 这些目录只放清单，`.deb` 统一放在 `04` | 避免重复占用空间，也让仓库成为唯一来源 |
| 建议的目录结构 | 删除了无实际内容的空目录，新增 `15_DEVELOPMENT_ENVIRONMENT` | 原任务要求只创建有用途的目录；补充要求需要放置位置 |
| Node.js 等语言来自同一渠道 | Java、Go、Rust、PHP 用 APT；Node.js 用官方 tarball | Ubuntu 的 Node 18 已停止维护 |
| 两条内核线 | 同时收录 GA 6.8 和 HWE 7.0 | Server 和 Desktop 的 ISO 默认内核不同 |

## 发布位置

- 仓库：https://github.com/yuriev315/linux-offline-installation-resource-library
- Release：https://github.com/yuriev315/linux-offline-installation-resource-library/releases/tag/library-2026.11.05

## 使用前要知道的

- **没有后续安全更新。** 软件包是 2026-11-05 的快照。
- **本地仓库的签名私钥不公开。** 私钥只保存在构建机的 `.tools/gpg_local/`（已被 git 忽略）。
- **构建脚本不能在新克隆上直接运行。** 它们依赖构建机的 `.tools/`（私有 APT 配置和系统基线），这些内容未纳入 git。
- **受许可限制的文件只有 `.url` 占位。** 见 `12_CHECKSUMS_AND_METADATA/LICENSES.md`。
