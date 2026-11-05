# 安装指南

适用对象：把本库拿到目标电脑上，要安装 Ubuntu 或搭建开发环境的人。

开始前先确认目标电脑是 x86_64 架构，并看一下 [HARDWARE_COMPATIBILITY.md](HARDWARE_COMPATIBILITY.md)。如果目标电脑完全不能联网，请同时阅读 [OFFLINE_INSTALLATION_GUIDE.md](OFFLINE_INSTALLATION_GUIDE.md)。

所有脚本都可以重复运行，不会覆盖已有配置，也不会替换 `/usr/bin/python3`。

## 方式一：Ubuntu 原生安装

1. **写入启动盘。** 把 ISO 写入 U 盘，再从 U 盘启动并完成安装。
   - 桌面版：`01_UBUNTU_ISO/ubuntu_desktop/ubuntu-24.04.5.1-desktop-amd64.iso`
   - 服务器版：`01_UBUNTU_ISO/ubuntu_server/ubuntu-24.04.5-live-server-amd64.iso`
2. **复制资源库。** 把库复制到新系统。ISO 不用复制，可节省 10 GB。

   ```bash
   sudo cp -r /media/<U盘>/Linux_Offline_Installation_Resource_Library /opt/
   cd /opt/Linux_Offline_Installation_Resource_Library
   ```

3. **安装系统工具。** `--with-kernel` 同时安装内核和固件，`--enable-ssh` 启用 SSH，两者都是可选项。

   ```bash
   sudo 10_INSTALLATION_SCRIPTS/ubuntu_native/setup_ubuntu_native.sh --with-kernel --enable-ssh --timezone Asia/Shanghai
   ```

4. **安装开发环境。**

   ```bash
   sudo 10_INSTALLATION_SCRIPTS/dependency_installation/install_dev_environment.sh
   ```

5. **验证。** 重新打开终端后运行：

   ```bash
   bash 13_TESTS/dev_environment/verify_dev_environment.sh
   sudo bash 13_TESTS/system_tests/verify_system_tools.sh
   ```

## 方式二：WSL2

先确认库里已有 WSL 安装包（联网时运行 `fetch_url_placeholders.ps1 -Only wsl`）。然后在 Windows 的管理员 PowerShell 中运行：

```powershell
cd <库目录>\10_INSTALLATION_SCRIPTS\ubuntu_wsl
Set-ExecutionPolicy -Scope Process Bypass
..\integrity_verification\verify_powershell_syntax.ps1              # 只解析语法，不运行脚本
.\wsl_offline_install.ps1 -CheckOnly                                # 只检查，不做改动
.\wsl_offline_install.ps1 -DistroName Ubuntu-24.04 -InstallDir D:\WSL\Ubuntu-24.04 -User dev
```

脚本第一次运行会启用 Windows 功能，并提示**重启**。重启后用同样的命令再运行一次，它会完成安装并导入 Ubuntu，整个过程不使用 Microsoft Store。

这一步只会启用 WSL2 所需的两个功能（`Microsoft-Windows-Subsystem-Linux` 和 `VirtualMachinePlatform`），并用 `--version 2` 导入。本库不提供 WSL1 流程。

资源配置模板是 `11_CONFIGURATIONS/wsl/wslconfig.template`。脚本只在 `%USERPROFILE%\.wslconfig` 不存在时才写入。

安装完整开发环境（在发行版内运行）：

```bash
sudo /mnt/d/<库目录>/10_INSTALLATION_SCRIPTS/dependency_installation/install_dev_environment.sh
```

备份和恢复：

```powershell
.\wsl_backup.ps1  -DistroName Ubuntu-24.04 -OutFile D:\Backup\ubuntu-2404.tar
.\wsl_restore.ps1 -BackupFile D:\Backup\ubuntu-2404.tar -DistroName Ubuntu-24.04-restored -InstallDir D:\WSL\restored
```

## 方式三：VMware Workstation

安装程序需要你从 Broadcom 下载，见 [HOW_TO_OBTAIN.md](../03_VMWARE/workstation_installers/HOW_TO_OBTAIN.md)。后续操作见 [VMWARE_GUIDE.md](../03_VMWARE/vm_configuration/VMWARE_GUIDE.md)。

## 可单独安装的内容

```bash
cd 10_INSTALLATION_SCRIPTS/dependency_installation
sudo ./offline_install.sh --list                     # 查看全部配置和分组
sudo ./offline_install.sh --dry-run --profile c-cpp  # 只检查依赖，不安装
sudo ./offline_install.sh --profile c-cpp
sudo ./offline_install.sh --packages "htop jq"
```

| 配置 | 内容 |
|---|---|
| `base` | 基础系统和系统管理工具 |
| `dev` | GCC、Make、CMake、Ninja、Git、GDB 等 |
| `c-cpp` | `dev` 加 Clang/LLVM、开发库、Valgrind、ccache、Git LFS |
| `python`、`python-dev` | Python 3.12 基础环境；调试和测试工具 |
| `shell` | Zsh、ShellCheck、shfmt、jq、yq、Perl、Ruby、Expect |
| `languages` | Java 21、Go 1.26、Rust 1.91、PHP 8.3 |
| `editors` | Vim、Neovim、Emacs、Git 客户端工具 |
| `debug` | GDB、LLDB、Valgrind、strace、ltrace、perf、lcov、GoogleTest |
| `net`、`storage` | 网络工具；存储、文件系统、压缩和监控工具 |
| `kernel` | GA 和 HWE 内核、固件 |
| `vmware-guest` | open-vm-tools 及其桌面组件 |
| `cross` | arm64 交叉编译器 |
| `server`、`wsl` | 常用组合 |
| `fulldev` | 完整开发环境（不含内核） |
| `extras` | Rust、PHP、Java 扩展，clang-format/tidy，libc++，gfortran，doxygen 等 |
| `desktop` | Ubuntu 桌面环境、中文语言包、Noto CJK 字体、拼音输入法 |
| `apt-tools` | apt-offline、apt-rdepends、aptly |
| `wsl-system` | ubuntu-wsl、wsl-setup、wslu |

## Python

系统 Python 不会被改动。虚拟环境从本地 wheel 仓库安装，不访问 PyPI：

```bash
bash 10_INSTALLATION_SCRIPTS/dependency_installation/python_offline_env.sh ~/venv pytest
~/venv/bin/python -m pytest --version
```

## VS Code

仓库里只有占位文件，先在联网电脑上运行 `fetch_url_placeholders.sh --only vscode`。然后：

```bash
sudo 10_INSTALLATION_SCRIPTS/dependency_installation/install_vscode.sh --extensions-for <用户名>
bash 10_INSTALLATION_SCRIPTS/dependency_installation/install_vscode_server.sh   # 用于 Remote-SSH 或 Remote-WSL
```

## 修复

安装中断后可运行 `sudo 10_INSTALLATION_SCRIPTS/recovery/repair_packages.sh`。

安装日志在 `/var/log/linux-offline/install.log`。
