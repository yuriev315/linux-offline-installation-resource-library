# Linux 通用科研 Python 离线资源库（轻量分支）

本分支只包含**文本部分**：说明文档及其离线 HTML 版本、登记表、锁定清单、校验文件和脚本。wheel、deb、运行时、固件和系统镜像都不在本分支，它们在 Release [`python-offline-2026.11.06`](https://github.com/yuriev315/linux-offline-installation-resource-library/releases/tag/python-offline-2026.11.06) 的 tar 包中；信号处理定向补充在 Release [`python-offline-signal-v1-2026.11.06`](https://github.com/yuriev315/linux-offline-installation-resource-library/releases/tag/python-offline-signal-v1-2026.11.06)。

- 下载与解压：[download_restore_cn.md](download_restore_cn.md)
- 中文说明：[README_cn.md](README_cn.md)
- 环境总览：[environments_overview_cn.md](environments_overview_cn.md)
- 受限文件占位清单：[restricted_placeholders_cn.csv](restricted_placeholders_cn.csv)
- 离线首页：下载并解压 tar 包后，用浏览器打开 `index_cn.html`

适用范围：Linux x86-64（glibc，参考 Ubuntu 22.04/24.04）CPU 环境与 ARM 开发板，不能用于 Windows 安装。50 个 Python 环境组已在一台 x86-64 Linux 主机上做了离线安装测试，结果见 [offline_install_test_cn.md](offline_install_test_cn.md)；开发板资源与镜像未上板验证。

English summary: offline Python environments (CPython 3.10/3.12, 50 groups), Ubuntu 22.04/24.04 system debs, runtimes and embedded/SBC resources for Linux x86-64. See `README_en.md`.
