# Linux 通用科研 Python 离线资源

目录：`linux_python_offline_resources/`

本仓库按用途准备 **Linux x86-64 / glibc / CPU** 科研 Python 离线环境，与 `windows_python_offline_resources/` 独立，不混用安装包。

- 总览：`environments_overview_cn.md`
- 运行时清单：`runtime_inventory_cn.csv`
- 包清单：`package_inventory_cn.csv`
- 系统/外部依赖：`external_dependencies_cn.csv`
- 兼容性问题：`compatibility_issues_cn.csv`
- 准备脚本：`scripts/prepare_offline_en.py`（支持断点续跑）

默认参考 Ubuntu 22.04 与 24.04 LTS。不要声称适用于全部 Linux。

## 扩展环境（增量）

原 01–11 组保持不动。新增 12–23 覆盖数据处理、统计时序、机器学习工程、NLP/检索、媒体 OCR、Web、数据库、爬虫、文档、可视化、桌面 GUI、工程工具与通用 SDK。

- 扩展准备脚本：`scripts/prepare_expansion_en.py`
- 外部运行时（Playwright 浏览器、Pandoc 等）：`external_runtimes/`
- Ubuntu 22.04/24.04 扩展 `.deb`：`system_dependencies/*/expansion_debs/`
## 嵌入式开发板

见 `embedded/README_cn.md`。电脑端工具与板端资源分开；固件不是 CPython wheel。

## 下载、阅读与受限文件

- 下载与解压：`download_restore_cn.md`；每个文件所在的 tar 包：`archive_index_cn.csv`
- 离线首页：解压后用浏览器打开 `index_cn.html`；每个 `.md` 和 `.csv` 都有同名 `.html`
- 中文使用说明：`guides/`；开发板总览：`embedded/linux_sbcs/OVERVIEW_cn.md`
- 不能再分发的文件（NVIDIA Jetson L4T、NVIDIA NCCL wheel）以 `.url` 占位，内含官方链接、字节数与 SHA-256，见 `restricted_placeholders_cn.csv`
- 全部资源只做了下载与静态检查，未在目标机安装、未上板验证
