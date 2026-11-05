# Linux 离线安装资源库

在没有互联网的电脑上安装 Ubuntu 24.04 并搭建完整开发环境所需的资源：安装介质、本地 APT 仓库、开发工具、安装脚本和验证工具。仅支持 x86_64。

- **Ubuntu：** Desktop 24.04.5.1、Server 24.04.5、WSL 24.04.5。
- **本地 APT 仓库：** 2265 个官方软件包，已包含全部递归依赖，包括桌面环境和中文支持。
- **受许可限制的文件：** VMware、VS Code、WSL MSI 只有 `.url` 占位文件，需要联网后单独取得。
- **开发环境：** C/C++、Python 3.12、Java 21、Go 1.26、Rust 1.91、Node.js 24、PHP 8.3 及常用工具。

## 从哪里开始

| 我想…… | 看这里 |
|---|---|
| 把库带到离线电脑，或从 GitHub 组装完整的库 | [OFFLINE_INSTALLATION_GUIDE.md](OFFLINE_INSTALLATION_GUIDE.md) |
| 安装系统或开发环境 | [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md) |
| 用 VMware | [VMWARE_GUIDE.md](../03_VMWARE/vm_configuration/VMWARE_GUIDE.md) |
| 了解测试了什么、没测什么 | [VERIFICATION_REPORT.md](VERIFICATION_REPORT.md) |
| 查版本 | [VERSION_MANIFEST.md](VERSION_MANIFEST.md) |
| 检查硬件要求 | [HARDWARE_COMPATIBILITY.md](HARDWARE_COMPATIBILITY.md) |

## 使用前须知

- **有些文件要单独下载。** VMware、VS Code、WSL MSI 因许可限制不放在仓库里，要在联网时运行 `fetch_url_placeholders` 脚本取得。VMware 还需要 Broadcom 账户，见 [HOW_TO_OBTAIN.md](../03_VMWARE/workstation_installers/HOW_TO_OBTAIN.md)。其他内容的取得方式见 [LICENSES.md](../12_CHECKSUMS_AND_METADATA/LICENSES.md)。
- **VMware Tools 和共享目录没有测通。** Ubuntu、WSL2 和 VMware 安装都已实测通过，其余见验证报告。
- **APT 仓库是筛选后的子集，不是 Ubuntu 完整镜像。** 清单外的软件无法安装，也不含 2026-11-05 之后的安全更新。

## GitHub 上的文件分布

| 位置 | 内容 |
|---|---|
| git 仓库 | 脚本、配置、文档、清单、仓库索引、官方签名元数据、`.url` 占位文件 |
| [Release](https://github.com/yuriev315/linux-offline-installation-resource-library/releases/tag/library-2026.11.05) | ISO（分卷）、Ubuntu WSL 镜像、APT 软件包（分卷）、Python wheels、Node.js |

分卷由 `10_INSTALLATION_SCRIPTS/recovery/assemble_from_github_release.sh`（Windows 上用 `.ps1`）自动下载、校验和合并。

## 目录

| 目录 | 内容 |
|---|---|
| `00_DOCUMENTATION` | 文档 |
| `01_UBUNTU_ISO` | Desktop 和 Server ISO、官方校验和签名 |
| `02_WSL2` | Ubuntu rootfs，WSL 安装包的 `.url` 占位 |
| `03_VMWARE` | VMware 获取方法、`.url` 占位、指南和虚拟机模板 |
| `04_APT_OFFLINE_REPOSITORY` | 本地 APT 仓库和 Ubuntu 官方元数据 |
| `05`–`09` | 按用途分组的软件包清单（`packages.list`）和依赖闭包（`resolved_closure.txt`）。`.deb` 文件统一放在 `04`，不重复存放；`07` 里还有 Python wheels |
| `10_INSTALLATION_SCRIPTS` | 安装、校验和恢复脚本 |
| `11_CONFIGURATIONS` | 配置模板 |
| `12_CHECKSUMS_AND_METADATA` | SHA256、文件清单、依赖清单、下载来源、许可 |
| `13_TESTS` | 验证脚本和测试记录 |
| `14_LOGS_AND_REPORTS` | 下载日志和最终报告 |
| `15_DEVELOPMENT_ENVIRONMENT` | Node.js、编辑器、Hello World 示例和语言分组 |
