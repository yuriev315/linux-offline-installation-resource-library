# 版本清单

由 `generate_version_manifest.py` 根据本地仓库生成。每个工具一个版本（内核除外：Server 用 GA，Desktop 用 HWE）。

## 安装介质和独立安装包

| 组件 | 版本 | 文件 |
|---|---|---|
| Ubuntu Desktop | 24.04.5.1 (20260914) | `ubuntu-24.04.5.1-desktop-amd64.iso` |
| Ubuntu Server | 24.04.5 (20260909) | `ubuntu-24.04.5-live-server-amd64.iso` |
| Ubuntu WSL | 24.04.5 | `ubuntu-24.04.5-wsl-amd64.wsl` |
| WSL | 3.0.3（`.url` 占位） | `wsl.3.0.3.0.x64.msi` |
| WSL2 旧版内核更新 | 5.10.16（`.url` 占位） | `wsl_update_x64.msi` |
| Node.js | 24.22.2 LTS（含 npm） | `node-v24.22.2-linux-x64.tar.xz` |
| VS Code | 1.145.0（`.url` 占位） | `code_1.145.0-1793749366_amd64.deb` |
| VS Code 扩展 | ms-python.debugpy-2026.6.0@linux-x64（`.url` 占位） | `ms-python.debugpy-2026.6.0@linux-x64.vsix` |
| VS Code 扩展 | ms-python.python-2026.10.0@linux-x64（`.url` 占位） | `ms-python.python-2026.10.0@linux-x64.vsix` |
| VS Code 扩展 | ms-vscode-remote.remote-wsl-1.104.7（`.url` 占位） | `ms-vscode-remote.remote-wsl-1.104.7.vsix` |
| VS Code 扩展 | ms-vscode.cmake-tools-1.24.42（`.url` 占位） | `ms-vscode.cmake-tools-1.24.42.vsix` |
| VS Code 扩展 | ms-vscode.cpptools-1.35.6@linux-x64（`.url` 占位） | `ms-vscode.cpptools-1.35.6@linux-x64.vsix` |
| VMware Workstation Pro | 26H1u1（build 25688693，`.url` 占位） | `VMware-Workstation-Full-26H1u1-25688693.exe`、`.x86_64.bundle` |
| VMware Tools（Windows 客户机） | 13.1.5（`.url` 占位） | `VMware-tools-windows-13.1.5-25544008.iso` |

## Python wheels

| 文件 |
|---|
| `build-1.6.1-py3-none-any.whl` |
| `coverage-7.17.2-cp312-cp312-manylinux1_x86_64.manylinux_2_28_x86_64.manylinux_2_5_x86_64.whl` |
| `distlib-0.4.4-py2.py3-none-any.whl` |
| `filelock-4.2.9-py3-none-any.whl` |
| `iniconfig-2.3.1-py3-none-any.whl` |
| `packaging-26.3-py3-none-any.whl` |
| `pip-26.3-py3-none-any.whl` |
| `platformdirs-4.14.5-py3-none-any.whl` |
| `pluggy-1.7.0-py3-none-any.whl` |
| `py_spy-0.4.3-py2.py3-none-manylinux1_x86_64.manylinux_2_5_x86_64.whl` |
| `pygments-2.21.0-py3-none-any.whl` |
| `pyproject_hooks-1.3.3-py3-none-any.whl` |
| `pytest-9.2.0-py3-none-any.whl` |
| `pytest_cov-7.1.0-py3-none-any.whl` |
| `python_discovery-1.9.4-py3-none-any.whl` |
| `setuptools-84.2.1-py3-none-any.whl` |
| `virtualenv-21.15.5-py3-none-any.whl` |
| `wheel-0.48.0-py3-none-any.whl` |

## APT 软件包（Ubuntu 24.04 noble，amd64）

### 系统基础

| 软件包 | 版本 |
|---|---|
| systemd | `255.4-1ubuntu8.18` |
| apt | `2.8.4ubuntu0.1` |
| dpkg | `1.22.6ubuntu6.6` |
| libc6 | `2.39-0ubuntu8.9` |
| libgcc-s1 | `14.2.0-4ubuntu2~24.04.1` |
| libstdc++6 | `14.2.0-4ubuntu2~24.04.1` |
| bash | `5.2.21-2ubuntu4` |
| coreutils | `9.4-3ubuntu6.3` |
| util-linux | `2.39.3-9ubuntu6.6` |
| sudo | `1.9.15p5-3ubuntu5.24.04.4` |
| openssl | `3.0.13-0ubuntu3.16` |
| ca-certificates | `20260816ubuntu0.24.04.1` |

### 内核和固件

| 软件包 | 版本 |
|---|---|
| linux-generic | `6.8.0-147.147` |
| linux-generic-hwe-24.04 | `7.0.0-42.42~24.04.1` |
| linux-firmware | `20240318.git3b128b60.0ubuntu3.1` |
| intel-microcode | `3.20260210.0ubuntu0.24.04.1` |
| amd64-microcode | `3.20251202.1ubuntu0.24.04.1` |

### C/C++

| 软件包 | 版本 |
|---|---|
| gcc | `4:13.2.0-7ubuntu1` |
| g++ | `4:13.2.0-7ubuntu1` |
| clang | `1:18.0-59~exp2` |
| llvm | `1:18.0-59~exp2` |
| lld | `1:18.0-59~exp2` |
| lldb | `1:18.0-59~exp2` |
| make | `4.3-4.1build2` |
| cmake | `3.28.3-1build7` |
| ninja-build | `1.11.1-2` |
| binutils | `2.42-4ubuntu2.10` |
| gdb | `15.1-1ubuntu1~24.04.1` |
| valgrind | `1:3.22.0-0ubuntu3` |
| ccache | `4.9.1-1` |
| pkg-config | `1.8.1-2build1` |
| autoconf | `2.71-3` |
| automake | `1:1.16.5-1.3ubuntu1` |
| libtool | `2.4.7-7build1` |
| git | `1:2.43.0-1ubuntu7.4` |
| git-lfs | `3.4.1-1ubuntu0.4` |
| libc6-dev | `2.39-0ubuntu8.9` |
| libstdc++-13-dev | `13.3.0-6ubuntu2~24.04.1` |
| libstdc++-14-dev | `14.2.0-4ubuntu2~24.04.1` |
| crossbuild-essential-arm64 | `12.10ubuntu1` |

### 开发库

| 软件包 | 版本 |
|---|---|
| libssl-dev | `3.0.13-0ubuntu3.16` |
| zlib1g-dev | `1:1.3.dfsg-3.1ubuntu2.3` |
| libffi-dev | `3.4.6-1build1` |
| libsqlite3-dev | `3.45.1-1ubuntu2.9` |
| libxml2-dev | `2.9.14+dfsg-1.3ubuntu3.10` |
| libxslt1-dev | `1.1.39-0exp1ubuntu0.24.04.3` |
| libopenblas-dev | `0.3.26+ds-1ubuntu0.1` |
| liblapack-dev | `3.12.0-3build1.1` |
| libomp-dev | `1:18.0-59~exp2` |
| libprotobuf-dev | `3.21.12-8.2ubuntu0.4` |
| protobuf-compiler | `3.21.12-8.2ubuntu0.4` |
| libcurl4-openssl-dev | `8.5.0-2ubuntu10.16` |
| libevent-dev | `2.1.12-stable-9ubuntu2.2` |

### Python

| 软件包 | 版本 |
|---|---|
| python3 | `3.12.3-0ubuntu2.1` |
| python3.12 | `3.12.3-1ubuntu0.17` |
| python3-dev | `3.12.3-0ubuntu2.1` |
| python3-venv | `3.12.3-0ubuntu2.1` |
| python3-pip | `24.0+dfsg-1ubuntu1.3` |
| python3-setuptools | `68.1.2-2ubuntu1.2` |
| python3-wheel | `0.42.0-2` |
| python3-virtualenv | `20.25.0+ds-2` |
| python3-pytest | `7.4.4-1` |
| python3-dbg | `3.12.3-0ubuntu2.1` |

### Shell

| 软件包 | 版本 |
|---|---|
| zsh | `5.9-6ubuntu2` |
| shellcheck | `0.9.0-1` |
| shfmt | `3.8.0-1` |
| jq | `1.7.1-3ubuntu0.24.04.2` |
| yq | `3.1.0-3` |
| perl | `5.38.2-3.2ubuntu0.6` |
| ruby | `1:3.2~ubuntu1` |
| expect | `5.45.4-3` |

### 语言运行环境

| 软件包 | 版本 |
|---|---|
| openjdk-21-jdk | `21.0.12.1+1-1~24.04.4` |
| golang-1.26-go | `1.26.8-1~ubuntu0.24.04.2` |
| rustc-1.91 | `1.91.1+dfsg~24.04-0ubuntu0.24.04.3` |
| cargo-1.91 | `1.91.1+dfsg~24.04-0ubuntu0.24.04.3` |
| php-cli | `2:8.3+93ubuntu2` |

### 编辑器和 Git 工具

| 软件包 | 版本 |
|---|---|
| vim | `2:9.1.0016-1ubuntu7.20` |
| neovim | `0.9.5-6ubuntu2` |
| emacs-nox | `1:29.3+1-1ubuntu2` |
| gitk | `1:2.43.0-1ubuntu7.4` |
| git-gui | `1:2.43.0-1ubuntu7.4` |
| tig | `2.5.8-1build2` |

### 调试和测试

| 软件包 | 版本 |
|---|---|
| strace | `6.8-0ubuntu2` |
| ltrace | `0.7.3-6.4ubuntu3` |
| lcov | `2.0-4ubuntu2` |
| googletest | `1.14.0-1` |
| libgtest-dev | `1.14.0-1` |
| libgmock-dev | `1.14.0-1` |
| linux-tools-generic-hwe-24.04 | `7.0.0-42.42~24.04.1` |

### 网络

| 软件包 | 版本 |
|---|---|
| iproute2 | `6.1.0-1ubuntu6.4` |
| iputils-ping | `3:20240117-1ubuntu0.1` |
| net-tools | `2.10-0.1ubuntu4.4` |
| bind9-dnsutils | `1:9.18.39-0ubuntu0.24.04.9` |
| traceroute | `1:2.1.5-1` |
| tcpdump | `4.99.4-3ubuntu4.24.04.1` |
| curl | `8.5.0-2ubuntu10.16` |
| wget | `1.21.4-1ubuntu4.5` |
| openssh-client | `1:9.6p1-3ubuntu13.20` |
| openssh-server | `1:9.6p1-3ubuntu13.20` |
| netcat-openbsd | `1.226-1ubuntu2` |
| socat | `1.8.0.0-4ubuntu0.1` |
| nmap | `7.94+git20230807.3be01efb1+dfsg-3build2` |
| ethtool | `1:6.7-1build1` |
| network-manager | `1.46.0-1ubuntu2.8` |

### 存储

| 软件包 | 版本 |
|---|---|
| fdisk | `2.39.3-9ubuntu6.6` |
| parted | `3.6-4build1` |
| gdisk | `1.0.10-1build1` |
| e2fsprogs | `1.47.0-2.4~exp1ubuntu4.1` |
| xfsprogs | `6.6.0-1ubuntu2.1` |
| btrfs-progs | `6.6.3-1.1build2` |
| dosfstools | `4.2-1.1build1` |
| ntfs-3g | `1:2022.10.3-1.2ubuntu3.2` |
| exfatprogs | `1.2.2-1build1` |
| lvm2 | `2.03.16-3ubuntu3.2` |
| mdadm | `4.3-1ubuntu2.1` |
| cryptsetup | `2:2.7.0-1ubuntu4.2` |
| smartmontools | `7.4-2build1` |

### 压缩和监控

| 软件包 | 版本 |
|---|---|
| zstd | `1.5.5+dfsg2-2build1.1` |
| p7zip-full | `16.02+transitional.1` |
| zip | `3.0-13ubuntu0.2` |
| unzip | `6.0-28ubuntu4.1` |
| rsync | `3.2.7-1ubuntu1.5` |
| htop | `3.3.0-4build1` |
| iotop | `0.6-42-ga14256a-0.2build1` |
| sysstat | `12.6.1-2` |
| fio | `3.36-1ubuntu0.1` |
| stress-ng | `0.17.06-1build1` |

### VMware 客户机

| 软件包 | 版本 |
|---|---|
| open-vm-tools | `2:13.0.10-0ubuntu0.24.04.2` |
| open-vm-tools-desktop | `2:13.0.10-0ubuntu0.24.04.2` |
| fuse3 | `3.14.0-5build1` |
| xserver-xorg-video-vmware | `1:13.4.0-1build1` |

仓库共 2265 个软件包。完整清单见 `12_CHECKSUMS_AND_METADATA/PACKAGE_DEPENDENCIES.csv`。
