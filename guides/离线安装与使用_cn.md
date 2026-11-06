# 离线安装与使用

本文档说明本库各部分（环境组 01–23、Ubuntu 系统 deb、Python 运行时、嵌入式 `embedded/`）如何配合，以及如何在目标机离线安装。

本轮只下载与静态检查，**没有**在目标 Linux 上创建 venv、导入包或连接硬件。下文步骤供日后在目标机执行；示例均标为未验证。

## 1. 各部分如何配合

| 部分 | 路径 | 内容 | 说明 |
| --- | --- | --- | --- |
| 基础环境组 | `environments/01_*` … `11_*`、`07b_*` | 科学计算、传统 ML、信号、PyTorch/TF CPU、HF 库、ONNX/API、优化 | 每组单独建 venv 安装 |
| 扩展环境组 | `environments/12_*` … `23_*` | 数据存储、量化、ML 工具、NLP、媒体/OCR、Web、数据库、爬虫、文档、可视化、PySide6、工程工具、通用工具 | 每组单独建 venv 安装 |
| 嵌入式 | `embedded/` | 主机串口/CAN/MQTT 与板端资源、开发板系统镜像 | **不是** x86-64 科学计算环境 |
| 运行时 | `runtimes/` | python-build-standalone 3.10.22 / 3.12.16；官方 CPython 源码 | 两套解释器 |
| 系统 deb | `system_dependencies/ubuntu_22.04/`、`ubuntu_24.04/` | FFmpeg、Tesseract、Poppler、Cairo 等 | 按发行版选用，不能混装 |
| 说明文档 | `guides/` | 本页、用途索引、任务入门 | 离线阅读 |

未完成、不要当作已交付：

- Jetson CUDA、Playwright 浏览器内核、CmdStan 可执行文件、多数模型权重：未纳入默认集合。
- NVIDIA Jetson L4T 包受 NVIDIA 许可约束，库中只有 `.url` 占位文件，见 `restricted_placeholders_cn.csv`。

## 2. 选择解释器

目标机：`uname -m` 为 `x86_64`，glibc 系统（Ubuntu 22.04 / 24.04 为参考）。不要用 musl、ARM64 主机解释器安装这些 manylinux x86-64 wheel。

| 环境后缀 | 需要的解释器 | 推荐运行时文件 | 说明 |
| --- | --- | --- | --- |
| `*_py310` | CPython **3.10** x86-64 | `runtimes/python_build_standalone/cpython-3.10.22+20261001-x86_64-unknown-linux-gnu-install_only.tar.gz` | 第三方可解压运行时，**不是** python.org 官方 Linux 二进制 |
| `*_py312` | CPython **3.12** x86-64 | `runtimes/python_build_standalone/cpython-3.12.16+20261026-x86_64-unknown-linux-gnu-install_only.tar.gz` | 新项目优先用 3.12 |

```bash
# 示例：解压 3.10 运行时（示例未验证）
tar -xzf runtimes/python_build_standalone/cpython-3.10.22+20261001-x86_64-unknown-linux-gnu-install_only.tar.gz -C /opt
export PYTHON_BIN=/opt/python/bin/python3
"$PYTHON_BIN" -V    # 应显示 3.10.22
```

备选：`runtimes/cpython_official_source/Python-3.10.22.tar.xz`（或 3.12.16）是**源码**，不能直接运行，需要本机编译器与 `system_dependencies/*/build_debs`。本轮未编译。

不要：

- 把 3.10 与 3.12 的 wheel 装进同一个 venv。
- 用系统 `python3`（若版本不是 3.10/3.12）强行安装。
- 把 ARM 板端 wheel 装到 x86-64 主机，或反过来。

## 3. 选择环境组（不要合并安装）

按任务选**一组**，不要把多组 lock 装进同一 venv。

| 任务 | 优先环境 | 不要混入 |
| --- | --- | --- |
| 表格 / Notebook / 绘图 | `01_scientific_notebook_*` | 深度学习框架 |
| 列存 / Parquet / DuckDB | `12_data_storage_*` | — |
| 量化指标 / 回测 | `13_stats_timeseries_*` | 实时行情源（需联网） |
| 树模型 / sklearn | `02_ml_stats_timeseries_em_*` | PyTorch / TensorFlow |
| 特征 / SHAP / Optuna | `14_ml_tooling_*` | 训练框架 |
| PyTorch CPU | `04_pytorch_cpu_*` | CUDA 构建 |
| TensorFlow CPU | `07_tensorflow_cpu_*` | `07b`（TF 2.18 + numpy&lt;2） |
| GPflow | `07b_gpflow_tf218_*` | `07`（TF 2.21） |
| 中文分词 / RAG 库 | `15_nlp_retrieval_*` | 权重、spaCy 模型 |
| PDF / Office | `20_documents_*` | 无 Pandoc 时不要用 pypandoc |
| 音视频 / OCR | `16_media_ocr_*` | 无 Tesseract/FFmpeg 时功能不完整 |
| 浏览器自动化 | `19_scraping_automation_*` | 无浏览器内核时 Playwright/Selenium 不能跑 |
| 串口 / 开发板（主机） | `embedded/host_linux_x86_64/python_host_comms_py310` 或 `_py312` | 不要拷到树莓派 |

同一编号的 `py310` 与 `py312` 选一个即可。包版本可能不同（例如 NumPy 3.10 环境为 2.2.6，3.12 环境为 2.5.4）。

## 4. 创建环境并离线安装 Python 包

在目标机进入某一环境目录：

```bash
cd environments/01_scientific_notebook_py310
export PYTHON_BIN=/path/to/python3.10    # 必须匹配本目录的 3.10
bash ./install_offline_en.sh
./venv/bin/python ./check_environment_en.py
```

脚本行为（已写在各目录 `install_offline_en.sh`，本轮未执行）：

- 用 `PYTHON_BIN` 新建 `venv/`（可用 `VENV_DIR` 改路径）。
- `pip install --no-index --find-links wheelhouse -r requirements_lock_en.txt`
- 失败即停止，**不会**回退到 PyPI。
- 不使用 sudo，不改系统 site-packages。

增量组（12–21b）用法相同。源码包（如 `15_*` 的 `sdist_needs_build/jieba-0.42.1.tar.gz`）**不在** lock 的默认 wheel 安装里；需要时再对 sdist 单独 `pip install --no-index`，且本轮未验证能否纯离线装上。

主机通信环境目前只有 wheelhouse，没有 `install_offline_en.sh`。自行：

```bash
# 示例未验证
"$PYTHON_BIN" -m venv /tmp/host_comms
/tmp/host_comms/bin/python -m pip install --no-index \
  --find-links embedded/host_linux_x86_64/python_host_comms_py310/wheelhouse \
  pyserial paho-mqtt pymodbus python-can pymavlink
```

`esptool`、`rshell` 仅有 sdist，见该目录 `sdist_needs_build/`。

## 5. 外部程序与系统库

Python wheel 装成功 **不等于** 下列工具可用。按 Ubuntu 版本安装对应 deb 目录，不要交叉安装 22.04/24.04 的包。本轮 **没有** 在本机 `apt install`。

| 用途 | 需要的外部程序 | 本库位置 | 安装后仍缺什么 |
| --- | --- | --- | --- |
| 音视频解码 | FFmpeg | `system_dependencies/<suite>/runtime_debs` 与 expansion_debs | 需目标机 dpkg/apt 安装 |
| OCR（pytesseract） | Tesseract + 语言包 | expansion_debs 中的 `tesseract-ocr`、`tesseract-ocr-chi-sim` 等 | 未执行安装；未验证中文语言包路径 |
| PDF 转图（pdf2image） | Poppler `pdftoppm` | expansion_debs | 同上 |
| WeasyPrint | Cairo / Pango / GDK-Pixbuf | expansion_debs | 缺系统库会导入失败 |
| pypandoc | Pandoc 可执行文件 | `external_runtimes/pandoc/` 目前主要是元数据，**不能**当成已齐备的 pandoc 二进制 | 需自行准备 pandoc |
| Playwright | 浏览器内核 | **未下载** | 官方 `playwright install` 默认要联网 |
| Selenium | 浏览器 + 驱动 | **未下载**；`webdriver-manager` 会试图联网取驱动 | 离线需自备浏览器 |
| Prophet / cmdstanpy | CmdStan | **未下载** | 仅有 Python 包 |
| Graphviz 出图 | `dot` | runtime_debs | python 绑定不够 |
| 官方 CPython 源码构建 | gcc 等 | `build_debs` | 未编译 |

调用外部工具的原则：先确认 `$PATH` 中有可执行文件，再跑 Python 包装器。不要把 “wheel 已下载” 写成 “开箱即用”。

## 6. 模型权重、语料与账号

下列库**只含代码**：

- `09_huggingface_llm_*`：`transformers` 5.x + PyTorch CPU。`from_pretrained(...)` 默认访问 Hugging Face Hub，需要联网或事先放到本地缓存。
- `15_nlp_retrieval_*`：`spacy`、`nltk` 无语料/模型包；Chroma/LanceDB 是库，不是已建好的向量库。
- RapidOCR：wheel 较大，可能带 ONNX 文件，**本轮未推理**，不能承诺完全离线。
- 量化：`quantstats` 依赖 `yfinance`，拉行情要联网。

GPU/CUDA 见 `pending_not_in_default/gpu_optional_cn.md`，未下载。

## 7. 开发板与微控制器

- 主机调试：`embedded/host_linux_x86_64/`（x86-64 glibc）。
- 树莓派板端：`embedded/boards/raspberry_pi/`（Python 3.11，arm64/armhf），**不能**用主机 3.10/3.12 wheel。
- Arduino / ESP32 / Pico / STM32 固件在 `embedded/firmware/`，不计入 Linux 开发板 CPython 环境。
- 未连接硬件、未烧录。串口示例见 `guides/常见任务快速入门_cn.md`。

## 8. 检查是否安装成功

只有在**目标 Linux** 上 `check_environment_en.py` 写出 `ok: true` 时，才把该组记为“已安装验证”。  
当前仓库内各组状态仍是：**已下载、未做目标机验证**。
