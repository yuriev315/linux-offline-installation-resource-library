# 缺失与未完成项汇总

本页汇总库中**没有**的内容，以及下载了但不能直接用的内容。增量更新包补齐的项目逐条列在 `missing_filled_cn.csv`（补了什么、路径、字节、SHA-256、来源）。

## 1. 不分发的受限文件（只有 `.url` 占位）

| 内容 | 位置 | 原因 |
| --- | --- | --- |
| NVIDIA Jetson L4T BSP 与 Sample RootFS（Nano 32.7.4、Xavier NX 35.5.0、Orin 36.4.4，共 6 个） | `embedded/linux_sbcs/_shared/images/jetson_*/*.url` | NVIDIA Software License |
| NVIDIA NCCL wheel（`nvidia-nccl-cu12` / `cu13`，默认 CPU 集合不用） | `environments/02_ml_stats_timeseries_em_*/rejected_not_default/*.url` | NVIDIA 专有许可 |
| Playwright Chromium 1248 = Chrome for Testing 156.0.8078.4（chrome 与 chrome-headless-shell） | `external_runtimes/playwright_browsers_linux_x64/cft-*.url` | Google Chrome 服务条款 |

占位文件内含官方链接、字节数与 SHA-256，清单见 `restricted_placeholders_cn.csv`。

## 2. 已不存在、改用同用途的新资料

| 原缺失项 | 现在库中 |
| --- | --- |
| `pandas-ta`（3.10）：PyPI 只剩要求 Python ≥3.12 的版本 | 13_stats_timeseries_py310 补 TA-Lib 0.8.1；`ta` 已由源码构建 |
| 4 块板子的 Armbian 社区每日构建 `trunk.108`：上游已删除 | `26.11.0-trunk.120`（ODROID-M1S、Orange Pi 3B、Orange Pi PC、Orange Pi Zero 3） |
| Adafruit_NeoPixel v1.12.5、DallasTemperature 3.11.0：标签不存在 | Adafruit_NeoPixel 1.15.5、DallasTemperature 4.0.6 |
| MicroPython STM32F405DISC：无此官方板名 | STM32F4DISC 1.26.1 |
| CircuitPython ESP32 DevKitC v4、BlackPill `.uf2`：板名或格式已变 | `espressif_esp32_devkitc_v4_wroom_32e` 10.0.3、`stm32f411ce_blackpill` 10.0.3 `.bin` |
| CircuitPython 10.x 库合集 20251029：已不存在 | 20261106 版 |

## 3. 仍然缺失

| 内容 | 原因 |
| --- | --- |
| Jetson CUDA / TensorRT / JetPack 完整组件 | 需要 NVIDIA 账号 |
| CUDA / GPU 驱动 | 不在默认 CPU 范围 |
| 多数模型权重 | 不在本库范围 |

## 4. 下载了但要在目标机再处理

- CmdStan 2.40.0 只有源码发行包（`external_runtimes/cmdstan/`），要在目标机用 C++ 工具链编译。
- `ta`、`lime`、`jieba`、`langdetect` 是本库用官方源码包构建的纯 Python wheel，见各组 `locally_built_wheels_cn.csv`；原源码包仍在 `sdist_needs_build/`。
- 依赖系统库的包（OpenCV、rapidocr、pyqtgraph 要 libGL；weasyprint 要 Pango）：在目标机装上 `system_dependencies/` 中对应 deb 后才能导入。

详见 `offline_install_test_cn.md`。

## 5. 未做的验证

系统 deb、嵌入式工具链、固件和开发板镜像只做了下载与校验和核对，没有安装、烧录或上板。Python 环境组的测试主机是 Ubuntu 26.04（glibc 2.43），不是 22.04/24.04 参考系统。
