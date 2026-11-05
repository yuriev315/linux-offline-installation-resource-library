#!/usr/bin/env python3
"""Write 00_DOCUMENTATION/VERSION_MANIFEST.md and DOWNLOAD_MANIFEST.md from the repository index and the files on disk."""
import glob, gzip, os, re, sys
LIB = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
ver = {}
sizes = {}
for f in glob.glob(f"{LIB}/04_APT_OFFLINE_REPOSITORY/dists/noble-offline/*/binary-amd64/Packages"):
    for st in open(f, encoding="utf-8").read().split("\n\n"):
        m = re.search(r"^Package: (.+)$", st, re.M)
        if m:
            ver[m[1]] = re.search(r"^Version: (.+)$", st, re.M)[1]
            sizes[m[1]] = int(re.search(r"^Size: (\d+)$", st, re.M)[1])
SECTIONS = {
    "系统基础": "systemd apt dpkg libc6 libgcc-s1 libstdc++6 bash coreutils util-linux sudo openssl ca-certificates",
    "内核和固件": "linux-generic linux-generic-hwe-24.04 linux-firmware intel-microcode amd64-microcode",
    "C/C++": "gcc g++ clang llvm lld lldb make cmake ninja-build binutils gdb valgrind ccache pkg-config autoconf automake libtool git git-lfs libc6-dev libstdc++-13-dev libstdc++-14-dev crossbuild-essential-arm64",
    "开发库": "libssl-dev zlib1g-dev libffi-dev libsqlite3-dev libxml2-dev libxslt1-dev libopenblas-dev liblapack-dev libomp-dev libprotobuf-dev protobuf-compiler libcurl4-openssl-dev libevent-dev",
    "Python": "python3 python3.12 python3-dev python3-venv python3-pip python3-setuptools python3-wheel python3-virtualenv python3-pytest python3-dbg",
    "Shell": "zsh shellcheck shfmt jq yq perl ruby expect",
    "语言运行环境": "openjdk-21-jdk golang-1.26-go rustc-1.91 cargo-1.91 php-cli",
    "编辑器和 Git 工具": "vim neovim emacs-nox gitk git-gui tig",
    "调试和测试": "strace ltrace lcov googletest libgtest-dev libgmock-dev linux-tools-generic-hwe-24.04",
    "网络": "iproute2 iputils-ping net-tools bind9-dnsutils traceroute tcpdump curl wget openssh-client openssh-server netcat-openbsd socat nmap ethtool network-manager",
    "存储": "fdisk parted gdisk e2fsprogs xfsprogs btrfs-progs dosfstools ntfs-3g exfatprogs lvm2 mdadm cryptsetup smartmontools",
    "压缩和监控": "zstd p7zip-full zip unzip rsync htop iotop sysstat fio stress-ng",
    "VMware 客户机": "open-vm-tools open-vm-tools-desktop fuse3 xserver-xorg-video-vmware",
}
L = ["# 版本清单", "", "由 `generate_version_manifest.py` 根据本地仓库生成。每个工具一个版本（内核除外：Server 用 GA，Desktop 用 HWE）。", "",
     "## 安装介质和独立安装包", "", "| 组件 | 版本 | 文件 |", "|---|---|---|",
     "| Ubuntu Desktop | 24.04.5.1 (20260914) | `ubuntu-24.04.5.1-desktop-amd64.iso` |",
     "| Ubuntu Server | 24.04.5 (20260909) | `ubuntu-24.04.5-live-server-amd64.iso` |",
     "| Ubuntu WSL | 24.04.5 | `ubuntu-24.04.5-wsl-amd64.wsl` |",
     "| WSL | 3.0.3（`.url` 占位） | `wsl.3.0.3.0.x64.msi` |", "| WSL2 旧版内核更新 | 5.10.16（`.url` 占位） | `wsl_update_x64.msi` |",
     "| Node.js | 24.22.2 LTS（含 npm） | `node-v24.22.2-linux-x64.tar.xz` |"]
vs = sorted(os.path.basename(p) for p in glob.glob(f"{LIB}/15_DEVELOPMENT_ENVIRONMENT/editors/vscode/*.deb"))
L += [f"| VS Code | {v.split('_')[1].split('-')[0]}（`.url` 占位） | `{v}` |" for v in vs]
L += [f"| VS Code 扩展 | {n[:-5]}（`.url` 占位） | `{n}` |" for n in sorted(map(os.path.basename, glob.glob(f"{LIB}/15_DEVELOPMENT_ENVIRONMENT/editors/vsix/*.vsix")))]
L += ["| VMware Workstation Pro | 26H1u1（build 25688693，`.url` 占位） | `VMware-Workstation-Full-26H1u1-25688693.exe`、`.x86_64.bundle` |",
      "| VMware Tools（Windows 客户机） | 13.1.5（`.url` 占位） | `VMware-tools-windows-13.1.5-25544008.iso` |", ""]
L += ["## Python wheels", "", "| 文件 |", "|---|"] + [f"| `{os.path.basename(p)}` |" for p in sorted(glob.glob(f"{LIB}/07_PYTHON_BASE_ENVIRONMENT/wheelhouse/*.whl"))] + [""]
L += ["## APT 软件包（Ubuntu 24.04 noble，amd64）", ""]
miss = []
for sec, pk in SECTIONS.items():
    L += [f"### {sec}", "", "| 软件包 | 版本 |", "|---|---|"]
    for p in pk.split():
        if p in ver:
            L.append(f"| {p} | `{ver[p]}` |")
        else:
            miss.append(p)
    L.append("")
L += [f"仓库共 {len(ver)} 个软件包。完整清单见 `12_CHECKSUMS_AND_METADATA/PACKAGE_DEPENDENCIES.csv`。", ""]
open(f"{LIB}/00_DOCUMENTATION/VERSION_MANIFEST.md", "w", encoding="utf-8").write("\n".join(L))
if miss:
    sys.exit(f"packages named in the manifest but absent from the repository: {miss}")


def tree(*paths):
    t = 0; n = 0
    for d in paths:
        for r, _, fs in os.walk(f"{LIB}/{d}"):
            for f in fs:
                t += os.path.getsize(os.path.join(r, f)); n += 1
    return n, t / 2**30


rows = [("Ubuntu ISO", "01_UBUNTU_ISO"), ("WSL2", "02_WSL2"), ("VMware", "03_VMWARE"), ("APT 仓库", "04_APT_OFFLINE_REPOSITORY"), ("Python wheels", "07_PYTHON_BASE_ENVIRONMENT"), ("开发环境（Node.js、VS Code、示例）", "15_DEVELOPMENT_ENVIRONMENT")]
D = ["# 下载清单", "", "单个文件的版本、来源、大小、SHA256 和验证状态见 `12_CHECKSUMS_AND_METADATA/FILE_INVENTORY.csv`。下载地址见 `12_CHECKSUMS_AND_METADATA/DOWNLOAD_URLS.md`。", "", "| 类别 | 目录 | 文件数 | 大小 |", "|---|---|---:|---:|"]
for a, d in rows:
    n, s = tree(d); D.append(f"| {a} | `{d}` | {n} | {s:.2f} GiB |")
D += ["", "受许可限制的文件（VMware、VS Code、WSL MSI）在仓库里只有 `.url` 占位，见 `12_CHECKSUMS_AND_METADATA/LICENSES.md`。", ""]
open(f"{LIB}/00_DOCUMENTATION/DOWNLOAD_MANIFEST.md", "w", encoding="utf-8").write("\n".join(D))
print("ok", len(ver), "packages")
