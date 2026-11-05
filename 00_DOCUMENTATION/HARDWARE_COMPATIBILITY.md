# 硬件和系统兼容性

**架构：本库只支持 x86_64（amd64）。** 不含 arm64 软件包；脚本检测到其他架构或非 Ubuntu 24.04 系统时会报错退出。

下表的配置是建议值，不是测试得出的最低要求。

| 使用方式 | CPU | 内存 | 磁盘 | 其他要求 |
|---|---|---|---|---|
| Ubuntu Desktop（原生或虚拟机） | 4 核 | 8 GB | 80 GB | |
| Ubuntu Server（原生或虚拟机） | 2 核 | 4 GB | 40 GB | |
| WSL2 | 4 核 | 8 GB | 40 GB | Windows 10 2004（build 19041）或更高，开启 VT-x / AMD-V |
| VMware Workstation 主机 | 虚拟机所需加 2 核 | 虚拟机所需加 8 GB | 虚拟机所需加 20 GB | 64 位 Windows，开启 VT-x / AMD-V |

安装完整开发环境（`fulldev`）后，系统盘还要多占约 6–10 GB。

## 内核

| 介质 | 默认内核 | 本地仓库中的版本 |
|---|---|---|
| Server ISO | GA 6.8 | `linux-generic` 6.8.0-147 |
| Desktop ISO | HWE 7.0 | `linux-generic-hwe-24.04` 7.0.0-42 |

很新的硬件应优先使用 HWE 内核。

## 固件

`linux-firmware`、`intel-microcode` 和 `amd64-microcode` 已包含在 `kernel` 配置中。

## 已知限制

- **GPU**：不含 NVIDIA 专有驱动。普通 VMware 虚拟机的虚拟显卡不支持 CUDA。
- **perf**：`perf` 命令需要与运行中内核匹配的工具包。WSL2 使用 Microsoft 内核，请直接运行 `/usr/lib/linux-tools/*/perf`。
- **WSL2 内核版本**：`wsl.3.0.3.0.x64.msi` 自带内核。`wsl_update_x64.msi` 是 5.10.16 的旧版，只有旧 Windows 10 环境才需要。
