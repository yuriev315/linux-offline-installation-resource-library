# Linux 离线安装资源库

在没有互联网的电脑上安装 Ubuntu 24.04 并搭建完整开发环境所需的资源。仅支持 x86_64。

**大文件不在 git 仓库里。** ISO、APT 软件包等约 13 GB 的文件在 [Release](https://github.com/yuriev315/linux-offline-installation-resource-library/releases/tag/library-2026.11.05) 中。克隆后运行：

```bash
git clone https://github.com/yuriev315/linux-offline-installation-resource-library.git Linux_Offline_Installation_Resource_Library
cd Linux_Offline_Installation_Resource_Library
bash 10_INSTALLATION_SCRIPTS/recovery/assemble_from_github_release.sh
```

Windows 上用 `assemble_from_github_release.ps1`。

接下来阅读：

- [说明和目录结构](00_DOCUMENTATION/README.md)
- [离线使用说明](00_DOCUMENTATION/OFFLINE_INSTALLATION_GUIDE.md)
- [安装指南](00_DOCUMENTATION/INSTALLATION_GUIDE.md)
- [验证报告：测了什么，没测什么](00_DOCUMENTATION/VERIFICATION_REPORT.md)

**受许可限制的文件不在仓库里。** VMware、VS Code、WSL MSI 只有 `.url` 占位文件，取得方式见 [LICENSES.md](12_CHECKSUMS_AND_METADATA/LICENSES.md)。
