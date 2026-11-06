# 下载与解压说明（Linux 通用科研 Python 离线资源库）

Release `python-offline-2026.11.06` 有 26 个**不压缩 tar 包**，合计约 29.5 GiB。wheel、deb 和系统镜像本身已经压缩，再压缩几乎不省空间。所有包都解压到**同一个目录**，彼此不重叠，可以只下需要的部分。

> 这些资源是给 **Linux x86-64（glibc，参考 Ubuntu 22.04/24.04）** 和 ARM 开发板用的，不能在 Windows 上安装。在 Windows 上下载、解压，可以离线阅读全部说明；真正使用时，请把资源拷到 Linux 机器上。

## 按需下载

| 包 | 用途 | 是否必需 |
| --- | --- | --- |
| `linux_python_offline_01_common_docs_runtimes_cn_en.tar` | 离线首页 `index_cn.html`、全部说明与登记表、guides、Python 运行时（python-build-standalone 3.10/3.12、CPython 源码、pandoc）、scripts | **必下**（193 MiB） |
| `…_02_system_debs_ubuntu_…` | Ubuntu 22.04 / 24.04 系统依赖 deb | 目标机缺系统库时下载 |
| `…_03–07_env_py310_part*` | Python 3.10 的环境组（每个 part 只含完整的组） | 用 3.10 时按需下载 |
| `…_08–12_env_py312_part*` | Python 3.12 的环境组 | 用 3.12 时按需下载 |
| `…_13–14_embedded_tools_boards_part*` | 嵌入式：电脑端工具链、开发板核心、树莓派 ARM wheel/deb、MicroPython/CircuitPython 固件、清单 | 做嵌入式时下载 |
| `…_15–25_board_images_part*` | 开发板系统镜像（Armbian、Raspberry Pi OS、BeagleBoard、Radxa、StarFive、OpenWrt） | 只下所用板卡所在的 part |
| `…_26_update_supplement_signal_…` | 信号处理定向补充 | 需要 EMD / Kalman 时下载 |

NVIDIA Jetson L4T 包受 NVIDIA 许可约束，本库不分发：`embedded/linux_sbcs/_shared/images/jetson_*` 下是 `.url` 占位文件，内含官方下载地址、字节数和 SHA-256，按地址下载后可以核对。全部占位文件见 `restricted_placeholders_cn.csv`。

各包的完整内容见下表；每个文件属于哪个包，见附件 `archive_index_cn.csv`。

| 包 | 内容 | 大小 |
| --- | --- | ---: |
| `linux_python_offline_01_common_docs_runtimes_cn_en.tar` | 离线首页 index_cn.html、库根说明与登记表、guides、Python 运行时（runtimes/、external_runtimes/）、scripts、state、受限文件占位清单（必下） | 193 MiB |
| `linux_python_offline_02_system_debs_ubuntu_cn_en.tar` | Ubuntu 22.04 / 24.04 系统依赖 deb（运行、编译、扩展三类） | 762 MiB |
| `linux_python_offline_03_env_py310_part1_cn_en.tar` | Python 3.10 环境组：01_scientific_notebook_py310 … 06_bayesian_mcmc_py310 | 1,428 MiB |
| `linux_python_offline_04_env_py310_part2_cn_en.tar` | Python 3.10 环境组：07_tensorflow_cpu_py310 … 08_rl_basics_py310 | 1,526 MiB |
| `linux_python_offline_05_env_py310_part3_cn_en.tar` | Python 3.10 环境组：09_huggingface_llm_py310 … 13_stats_timeseries_py310 | 1,420 MiB |
| `linux_python_offline_06_env_py310_part4_cn_en.tar` | Python 3.10 环境组：14_ml_tooling_py310 … 20_documents_py310 | 1,514 MiB |
| `linux_python_offline_07_env_py310_part5_cn_en.tar` | Python 3.10 环境组：21_viz_dashboard_py310 … 23_general_utils_py310 | 619 MiB |
| `linux_python_offline_08_env_py312_part1_cn_en.tar` | Python 3.12 环境组：01_scientific_notebook_py312 … 06_bayesian_mcmc_py312 | 1,436 MiB |
| `linux_python_offline_09_env_py312_part2_cn_en.tar` | Python 3.12 环境组：07_tensorflow_cpu_py312 … 08_rl_basics_py312 | 1,529 MiB |
| `linux_python_offline_10_env_py312_part3_cn_en.tar` | Python 3.12 环境组：09_huggingface_llm_py312 … 12_data_storage_py312 | 1,171 MiB |
| `linux_python_offline_11_env_py312_part4_cn_en.tar` | Python 3.12 环境组：13_stats_timeseries_py312 … 17_web_services_py312 | 1,478 MiB |
| `linux_python_offline_12_env_py312_part5_cn_en.tar` | Python 3.12 环境组：18_database_py312 … 23_general_utils_py312 | 1,019 MiB |
| `linux_python_offline_13_embedded_tools_boards_part1_cn_en.tar` | 嵌入式（电脑端工具链、开发板核心与 ARM wheel/deb、固件、清单、Jetson L4T 占位链接）：README_cn.html … esp32s3-libs-3.3.9.zip | 1,480 MiB |
| `linux_python_offline_14_embedded_tools_boards_part2_cn_en.tar` | 嵌入式（电脑端工具链、开发板核心与 ARM wheel/deb、固件、清单、Jetson L4T 占位链接）：esptool-v5.3.0-linux-amd64.tar.gz … Tegra_Linux_Sample-Root-Filesystem_R35.5.0_aarch64.tbz2.url | 811 MiB |
| `linux_python_offline_15_board_images_part1_cn_en.tar` | 开发板系统镜像：armbian_bananapif3_trixie … armbian_cuboxi_trixie | 1,316 MiB |
| `linux_python_offline_16_board_images_part2_cn_en.tar` | 开发板系统镜像：armbian_mba8mpxl_trixie … armbian_odroidm1s_trixie | 1,328 MiB |
| `linux_python_offline_17_board_images_part3_cn_en.tar` | 开发板系统镜像：armbian_odroidm2_trixie … armbian_orangepi3b_trixie | 1,340 MiB |
| `linux_python_offline_18_board_images_part4_cn_en.tar` | 开发板系统镜像：armbian_orangepi3lts_trixie … armbian_orangepipc_trixie | 1,285 MiB |
| `linux_python_offline_19_board_images_part5_cn_en.tar` | 开发板系统镜像：armbian_orangepizero3_trixie … beagle_ai64_debian12 | 1,178 MiB |
| `linux_python_offline_20_board_images_part6_cn_en.tar` | 开发板系统镜像：beagle_bbb_debian12 … beagle_bbb_debian12 | 406 MiB |
| `linux_python_offline_21_board_images_part7_cn_en.tar` | 开发板系统镜像：beagle_play_debian12 … openwrt_bpi_r3 | 1,436 MiB |
| `linux_python_offline_22_board_images_part8_cn_en.tar` | 开发板系统镜像：radxa_rock5b_bookworm … radxa_rock5b_bookworm | 1,472 MiB |
| `linux_python_offline_23_board_images_part9_cn_en.tar` | 开发板系统镜像：radxa_rockpi4b_bookworm … radxa_rockpi4b_bookworm | 1,371 MiB |
| `linux_python_offline_24_board_images_part10_cn_en.tar` | 开发板系统镜像：raspios_bookworm_lite_arm64 … raspios_bookworm_lite_armhf | 918 MiB |
| `linux_python_offline_25_board_images_part11_cn_en.tar` | 开发板系统镜像：starfive_vf2_debian … starfive_vf2_debian | 1,395 MiB |
| `linux_python_offline_26_update_supplement_signal_cn_en.tar` | 信号处理定向补充（EMD-signal、filterpy、pykalman 及 aarch64/armv7l 板端 wheel），与 Release `python-offline-signal-v1-2026.11.06` 的两个 zip 内容相同 | 360 MiB |

## 在 Windows 上离线阅读

Windows 10/11 自带 `tar`，在 PowerShell 或 cmd 中都能用：

```powershell
mkdir D:\lpo
cd D:\lpo
tar -xf "$env:USERPROFILE\Downloads\linux_python_offline_01_common_docs_runtimes_cn_en.tar"
# 其余下载的包同样解压到 D:\lpo
```

然后用浏览器打开 `D:\lpo\index_cn.html`，不需要联网：

- 每个 `.md` 说明和指南都有同名 `.html`，其中存在的本地路径可以点击，跳到本地文件或目录。
- 每个 CSV 登记表都有同名 `.html` 表格视图。
- 只有 http(s) 链接（上游来源和官方文档）需要联网。
- 链接指向的包没有下载时，该链接打不开，这是正常的。

包内最长相对路径为 174 个字符，解压到 `D:\lpo\` 这样的短目录时不会超过 Windows 的 260 字符限制。7-Zip 也可以解压。包内没有符号链接和硬链接。

## 在 Linux 上使用

**建议把 tar 包本身拷到 Linux 上再解压**：Linux 的 `tar` 会还原可执行权限，而 Windows 上解压再拷过去，`.sh` 脚本和工具链二进制会丢失可执行位。

```bash
mkdir -p ~/lpo && cd ~/lpo
for t in /path/to/linux_python_offline_*_cn_en.tar; do tar -xf "$t"; done
```

如果已经是在 Windows 上解压后拷过去的，就用 `bash install_offline_en.sh` 运行脚本，工具链目录用 `chmod -R u+x` 补回权限。

安装步骤见 `guides/离线安装与使用_cn.html`；每个环境组的 `README_cn.html` 给出该组的安装命令。

## 校验

`archive_index_cn.csv` 列出每个文件所在的包、大小和 SHA256；Release 附件 `SHA256SUMS.txt` 列出每个 tar 包的 SHA256。

```bash
sha256sum -c SHA256SUMS.txt --ignore-missing
sha256sum environments/04_pytorch_cpu_py312/wheelhouse/*.whl
```

## 不在包内的内容

- `state/pip_cache/`：pip 的 HTTP 缓存，不能当 wheelhouse 用；所需 wheel 都已在各组 `wheelhouse/` 中。
- 各下载工具留下的未完成 `.part` 文件。
- Playwright 浏览器内核（官方地址下载失败，见 `external_dependencies_cn.csv`）。

## 状态

50 个 Python 环境组已在一台 x86-64 Linux 主机（Ubuntu 26.04，glibc 2.43）上用各组的 `install_offline_en.sh` 做了离线安装测试：50 组全部装成，32 组检查脚本全部通过，其余失败原因（仅有源码包、测试主机缺系统库等）见 `offline_install_test_cn.md`。系统 deb、嵌入式资源与开发板镜像只做了下载与校验，**没有安装、烧录或上板验证**。

## 增量更新 1（Release `python-offline-update1-2026.11.06`）

Release `python-offline-update1-2026.11.06` 补齐了 `missing_items_cn.md` 中可以补齐的项目：Playwright Firefox / WebKit、CmdStan 源码包、slycot，`ta` / `lime` / `jieba` / `langdetect` 的 wheel（由官方源码包构建），TA-Lib，ESP32 全部芯片库、dfu-util、stlink、picotool、USBImager，以及几项固件和 Arduino 库的现行版本；同时更新了相关环境组的锁定清单、清单表、说明和测试报告。逐条明细见 `missing_filled_cn.csv`。

用法：先按上文解压 `python-offline-2026.11.06` 的 tar 包，**最后**把 `linux_python_offline_27_update1_cn_en.tar` 解压到同一目录并覆盖同名文件。更新包里只有新增和改动的文件。`archive_index_cn.csv` 中，这些文件的“所在 tar”已改为更新包。
