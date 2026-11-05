# 许可与再分发说明

这里说明本库各组件的许可状态，以及它们是否存放在公开仓库中。这不是法律意见。如有疑问，请以各项目的官方许可文本为准。

## 不存放在仓库中，只有 `.url` 占位

每个 `.url` 文件都是普通的快捷方式，放在原文件的位置，里面有官方地址、文件大小和 SHA256。

| 组件 | 原因 | 取得方式 |
|---|---|---|
| VMware Workstation Pro | Broadcom 专有软件，需要账户下载 | 手动下载，见 `03_VMWARE/workstation_installers/HOW_TO_OBTAIN.md` |
| VMware Tools | Broadcom 专有软件 | 脚本从官方站点下载 |
| Visual Studio Code、VS Code Server | Microsoft 专有许可，禁止 “share, publish”。[许可文本](https://code.visualstudio.com/license) | 脚本从 Microsoft 下载 |
| VS Code 扩展（VSIX） | 按各扩展的 Microsoft 许可处理，未确认可以再分发 | 脚本从 Marketplace 下载 |
| WSL MSI、`wsl_update_x64.msi` | Microsoft 分发的二进制包。WSL 源码是 MIT，内核是 GPLv2，但未逐项确认包内全部组件都可以再分发，因此从严处理 | 脚本从 Microsoft 下载 |

取得这些文件（需要联网）：

```bash
bash 10_INSTALLATION_SCRIPTS/recovery/fetch_url_placeholders.sh
```

Windows 上用 `fetch_url_placeholders.ps1`。脚本会校验 SHA256；需要登录的文件会列出来，由你手动下载。

## 存放在仓库或 Release 中

| 组件 | 许可 |
|---|---|
| Ubuntu ISO、WSL 镜像、APT 软件包 | 各软件包自身的开源或可再分发许可，未作任何修改。[Ubuntu 知识产权政策](https://ubuntu.com/legal/intellectual-property-policy) |
| Node.js | MIT 及其捆绑组件的许可 |
| Python wheels | 各项目的开源许可，见 `07_PYTHON_BASE_ENVIRONMENT/wheelhouse/WHEEL_SOURCES.tsv` 中的 PyPI 页面 |
| 本库的脚本和文档 | 本库作者所有 |

GPL 软件包的源代码由 Ubuntu 在 [archive.ubuntu.com](https://archive.ubuntu.com/ubuntu/) 提供，本库不重复存放。

## APT 软件包索引的改动

本地仓库的 `Packages` 索引沿用 Ubuntu 官方条目，只删除了 `Phased-Update-Percentage` 字段，以免离线升级被随机推迟。`.deb` 文件本身未作改动，可用 `verify_repo_against_official.py` 离线核对。
