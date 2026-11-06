# 缺失与未完成项汇总

本页汇总库中**没有**的内容，以及下载了但不能直接用的内容。逐项细节见各登记表。

## 1. 不分发的受限文件（只有 `.url` 占位）

| 内容 | 位置 | 原因 |
| --- | --- | --- |
| NVIDIA Jetson L4T BSP 与 Sample RootFS（Nano 32.7.4、Xavier NX 35.5.0、Orin 36.4.4，共 6 个） | `embedded/linux_sbcs/_shared/images/jetson_*/*.url` | NVIDIA Software License |
| NVIDIA NCCL wheel（`nvidia-nccl-cu12` / `cu13`，已被排除在默认 CPU 集合外） | `environments/02_ml_stats_timeseries_em_*/rejected_not_default/*.url` | NVIDIA 专有许可 |

占位文件内含官方链接、字节数与 SHA-256，清单见 `restricted_placeholders_cn.csv`。

## 2. Python 包：只有源码包，未构建

| 包 | 环境组 | 位置 |
| --- | --- | --- |
| `ta` | 13_stats_timeseries（3.10、3.12） | `sdist_needs_build/` |
| `pandas-ta` | 13_stats_timeseries_py310（3.10 无兼容 wheel） | 见该组 README |
| `lime` | 14_ml_tooling（3.10、3.12） | `sdist_needs_build/` |
| `jieba`、`langdetect` | 15_nlp_retrieval（3.10、3.12） | `sdist_needs_build/` |

需要在目标机用编译工具构建后再装，状态 **未构建、未验证**。

## 3. 装得上但导入失败

- `evidently`（14_ml_tooling_py312）：与本组 pandas 版本不兼容，未修正。
- 需要系统库的包（OpenCV、rapidocr、pyqtgraph 要 libGL；weasyprint 要 Pango）：在目标机装上 `system_dependencies/` 中对应 deb 后才能导入。

详见 `offline_install_test_cn.md`。

## 4. 外部程序与系统包

| 内容 | 状态 |
| --- | --- |
| Playwright Chromium / Firefox / WebKit 浏览器内核 | 官方 CDN 下载失败，未获取；只有 Playwright 的 ffmpeg |
| CmdStan（prophet、cmdstanpy 需要） | 未下载 |
| CUDA / GPU 驱动 | 不在默认 CPU 范围，未下载 |
| slycot（控制工具箱可选依赖） | 未下载 |
| Ubuntu 扩展 deb：22.04 的 `libtesseract5`、24.04 的 `libleptonica6` | 依赖闭包中未能解析，见 `system_dependencies/*/expansion_missing_en.txt` |

见 `external_dependencies_cn.csv`。

## 5. 嵌入式

| 内容 | 状态 |
| --- | --- |
| Arduino 工具 `dfu-util@0.11.0-arduino5` | 包索引中没有 Linux x86-64 构建 |
| ESP32-C5/C6/H2/P4 芯片库 | 不在基础套件内，未下载 |
| Arduino 库 Adafruit_NeoPixel、DallasTemperature | 指定版本的源码地址 404 |
| stlink、picotool 主机二进制 | 上游 Release 没有 Linux 二进制；picotool 只有源码包 |
| MicroPython STM32F405DISC 固件 | 官方地址 404 |
| CircuitPython ESP32 DevKitC v4、STM32F411 BlackPill 固件，10.x 库合集 | 官方地址无此文件 |
| USBImager | 预编译包与源码包地址均无效 |
| Jetson CUDA / TensorRT / JetPack 完整组件 | 需要 NVIDIA 账号，未下载 |

见 `embedded/inventories/missing_cn.csv` 与 `embedded/linux_sbcs/OVERVIEW_cn.md`。

## 6. 版本说明

ODROID-M1S、Orange Pi 3B、Orange Pi PC、Orange Pi Zero 3 的 Armbian 镜像是社区每日构建（community trunk）。上游只保留最新几版，库中是 `26.11.0-trunk.120`。其余 Armbian 镜像是带版本号的稳定构建。

## 7. 未做的验证

系统 deb、嵌入式工具链、固件和开发板镜像只做了下载与校验和核对，没有安装、烧录或上板。Python 环境组的测试主机是 Ubuntu 26.04（glibc 2.43），不是 22.04/24.04 参考系统。
