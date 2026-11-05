# 验证报告

适用对象：需要判断这个库能否用于自己环境的人。构建和测试日期为 2026-11-05。

## 结论

| 场景 | 状态 | 依据 |
|---|---|---|
| Ubuntu Server 从 ISO 安装，全程断网 | **已验证**（在 KVM 中） | 测试 A |
| Ubuntu Desktop 从 ISO 安装，全程断网 | **已验证**（在 KVM 中，到登录界面） | 测试 A |
| WSL2 离线安装、导入、开发环境、备份恢复 | **已验证**（无网卡 Windows 11 虚拟机） | 测试 B |
| VMware Workstation 离线安装 | **已验证**（无网卡 Windows 11 虚拟机） | 测试 C |
| VMware 中的虚拟机启动、VMware Tools、共享目录 | **测试中**，尚未得出结论 | 测试 C |
| 真实物理机 | **未验证** | 全部测试都在虚拟机中进行 |

## 测试 A：从 ISO 安装（Server 和 Desktop）

**环境：** Linux KVM/QEMU，UEFI，4 vCPU，Server 4 GB 内存，Desktop 6 GB 内存。

**断网方式：** 虚拟机没有任何网卡（`-nic none`）。日志显示只有 `lo`，外部地址不可达。

**流程：** 用本地 ISO 无人值守安装 → 首次启动 → 从只读磁盘上的资源库安装系统工具、内核、开发环境、扩展软件包、open-vm-tools 和 VS Code → 运行验证 → 重启进入新内核。

| 检查项 | Server | Desktop |
|---|---|---|
| ISO 安装 | 通过 | 通过 |
| `setup_ubuntu_native.sh` 及重复运行 | 通过 | 通过 |
| `install_dev_environment.sh --profile fulldev` | 通过 | 通过 |
| `extras`、`apt-tools` 配置 | 通过 | 通过 |
| `setup_vmware_guest.sh`（软件包层面） | 通过 | 通过 |
| VS Code 安装 | 通过 | 通过 |
| 开发环境验证 | **56 通过，0 失败** | **56 通过，0 失败** |
| 系统工具验证 | **88 通过，0 失败** | **88 通过，0 失败** |
| 升级内核后重启 | 通过（7.0.0-42） | 通过（7.0.0-42） |
| 图形登录 | 不适用 | `gdm3`、`gnome-shell` 运行，出现登录界面 |

结果记录：`13_TESTS/installation_tests/results_server/`、`results_desktop/`（含登录界面截图）。

**局限：**

- 安装程序的内核和 initrd 由 QEMU 直接加载，ISO 同时作为安装来源挂载。**从 ISO 的引导菜单启动和 U 盘写入没有测试**。
- Desktop 只到登录界面，**没有实际登录进桌面**。
- Server 重启后默认进入 HWE 7.0 内核，因为测试同时安装了两条内核线。GA 6.8 已安装，但没有启动过。
- Server 上 `systemd-networkd-wait-online` 启动失败，这是没有网卡时的预期结果。
- `05_SYSTEM_PACKAGES/desktop` 配置（把 Server 变成桌面系统）和 `wsl-system` 配置只完成了依赖解析，没有实际安装测试。

## 测试 B：真实 WSL2

**环境：** Windows 11 Enterprise 评估版（build 26200），运行在 KVM 虚拟机中，8 GB 内存，**没有网卡**。资源库放在 exFAT 磁盘上，与建议的 U 盘用法相同。不使用 Microsoft Store。

| 检查项 | 结果 |
|---|---|
| 所有 PowerShell 脚本的语法（Windows 自带解析器） | 通过 |
| `wsl_offline_install.ps1 -CheckOnly` | 通过 |
| 启用 Windows 功能，要求重启（退出码 3010） | 通过 |
| 从本地 MSI 安装 WSL 3.0.3，从本地 rootfs 导入 Ubuntu | 通过，VERSION 2 |
| 创建默认用户 | 通过，默认用户 `dev` |
| 从本地仓库安装 `fulldev` | 通过 |
| 开发环境验证 | **55 通过，0 失败，1 跳过**（未在 WSL 中安装 VS Code） |
| 系统工具验证 | **88 通过，0 失败**（含 systemd 和 loop 设备） |
| 备份、恢复 | 通过 |
| 拒绝覆盖已有备份和已有发行版 | 通过 |

结果记录：`13_TESTS/windows_tests/`。

**局限：** 这是嵌套虚拟化下的结果，WSL 会提示 “Nested virtualization is not supported on this machine”（指 WSL 内部不能再运行虚拟机）。Windows 10 没有测试。

## 测试 C：真实 VMware Workstation

**环境：** 同测试 B。测试用的 VMware 26H1u1 安装包来自第三方镜像（因为 Broadcom 要求登录）。它的 Broadcom Authenticode 签名在 Windows 上返回 `Valid`，SHA256 与独立记录一致；这些文件不在公开仓库中。

| 检查项 | 结果 |
|---|---|
| 从本地文件无人值守安装 | 通过，退出码 0，无网络 |
| `create_vmware_vm.ps1`（检查、建盘、生成 `.vmx`、挂载 ISO） | 通过 |
| 从 ISO 开机的虚拟机 | 通过（开机并运行 4 分钟，未走完安装） |
| 预装 Ubuntu 的虚拟机开机 | 通过 |
| VMware Tools、共享目录、快照 | **测试中**，尚未得出结论。开启 Hyper-V（WSL2 共存）时，预装虚拟机 30 分钟内 Tools 未进入 running，可能是三层嵌套太慢，尚无定论；正在关闭 Hyper-V 后重测 |

预装 Ubuntu 是测试 A 的 Server 磁盘转成的 VMDK。这样可以验证 open-vm-tools 在真实 VMware 里的行为，但**没有测试在 VMware 中从 ISO 完整安装 Ubuntu**。

## 文件完整性

记录：`14_LOGS_AND_REPORTS/integrity_check.log`、`12_CHECKSUMS_AND_METADATA/FILE_INVENTORY.csv`。

| 对象 | 检查方式 | 结果 |
|---|---|---|
| Desktop、Server ISO | 官方 SHA256（列表有 GPG 签名）、ISO 内部 `md5sum.txt` | 通过 |
| WSL 镜像 | 官方 SHA256，实际导入 | 通过 |
| 2265 个 `.deb` | Ubuntu 官方签名索引的 SHA256、`dpkg-deb` 读取 | 全部通过 |
| Node.js | 官方 SHASUMS（有 GPG 签名） | 通过 |
| Python wheels | PyPI 记录的 SHA256、zip 测试 | 通过 |
| WSL 3.0.3 MSI | GitHub digest、Authenticode 证书链 | 通过 |
| `wsl_update_x64.msi` | Authenticode 摘要、签名时点的证书链 | **部分通过**：微软未公布校验值，证书已过期 |
| VMware `.exe` | Broadcom Authenticode 证书链、独立的 SHA256 记录 | 通过 |
| VMware `.bundle` | 独立的 SHA256 记录 | **部分通过**：没有代码签名可查，也没有实际运行 |
| VMware Tools ISO | 官方站点 HTTPS 下载 | **部分通过**：签名文件未校验，没有实际使用 |
| VS Code、Server、VSIX | Microsoft 公布的 SHA256（VSIX 的值是本地计算的），实际安装 | 通过 |
| Shell 脚本 | `bash -n`、ShellCheck | 通过；ShellCheck 有 2 条已确认无害的警告 |

## `.url` 占位文件

VMware、VS Code、WSL MSI 等 14 个受许可限制的文件在仓库中只有 `.url` 占位，详见 `12_CHECKSUMS_AND_METADATA/LICENSES.md`。占位文件里的直链在 2026-11-05 全部可达；VMware 的 2 个指向 Broadcom 的登录页面，脚本无法访问。**发布方日后更新文件后，直链内容可能变化，SHA256 校验会报错**。

## 测试中发现并修复的问题

只有实际运行才暴露的问题：

1. **`.vmx` 模板无法开机。** VMware 报 `No PCIe slot available for Ethernet0`：模板缺 PCIe 桥。已修复，并在真实 VMware 中重新通过。
2. **验证脚本可能永远挂住。** 超时后，遗留子进程仍占着输出管道，shell 一直等待。已改为输出到文件。
3. **Clang++ 找不到 `<iostream>`。** noble 上 clang 会选择 GCC 14，但默认没有对应头文件。已加入 `libstdc++-14-dev`。
4. **`libtool` 命令不存在。** 可执行文件在单独的 `libtool-bin` 包里，已加入。
5. **VS Code 依赖名称。** `libasound2` 等在 noble 上改名为 `*t64`，已映射。
6. **默认语言版本过旧。** APT 默认的 Node 18、Go 1.22、Rust 1.75 已过时。改用 Ubuntu 官方提供的 Go 1.26、Rust 1.91，以及 Node.js 官方的 v24 LTS。
7. **校验清单和换行符。** 清单曾在文件重写前计算哈希；`.ps1` 的换行符在克隆后会变。都已修复，并用全新克隆验证。

## 测试环境的限制

Windows 评估版授权已过期，系统每小时自动关机一次。测试框架在关机后重启并从断点继续，没有绕过这项限制。因此 Windows 的测试是分多次开机完成的。

## 仍未满足的要求

- **VMware 和 VS Code 不能完全离线取得。** 它们需要先联网下载一次，VMware 还需要 Broadcom 账户。
- **`arm64` 未包含。** 本库只面向 amd64。
- **没有后续安全更新。** 软件包是 2026-11-05 的快照。
