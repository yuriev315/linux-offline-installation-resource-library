# Linux 通用科研 Python 离线环境总览

默认目标：**Linux x86-64 + glibc**，参考 Ubuntu 22.04/24.04 LTS，**CPU**。
这不是“全部 Linux”环境。ARM64、musl、其他发行版、GPU 见 `pending_not_in_default/`。

Windows 资源在 `windows_python_offline_resources/`，两套安装包不混用。

## Python 运行时

| 版本 | 类型 | 文件 | 官方 python.org 二进制 | 本轮是否执行 |
| --- | --- | --- | --- | --- |
| 3.10.22 | python-build-standalone 第三方可解压运行时 | `runtimes/python_build_standalone/cpython-3.10.22+20261001-x86_64-unknown-linux-gnu-install_only.tar.gz` | 否 | 否 |
| 3.12.16 | python-build-standalone 第三方可解压运行时 | `runtimes/python_build_standalone/cpython-3.12.16+20261026-x86_64-unknown-linux-gnu-install_only.tar.gz` | 否 | 否 |
| 3.10.22 | CPython 官方源码 | `runtimes/cpython_official_source/Python-3.10.22.tar.xz` | 否（源码） | 否 |
| 3.12.16 | CPython 官方源码 | `runtimes/cpython_official_source/Python-3.12.16.tar.xz` | 否（源码） | 否 |

选择依据：3.10 已于 2026-10-01 结束上游支持，仅作兼容环境；3.12 安全支持至 2028-10，科学计算 wheel 覆盖较 3.13/3.14 更稳。

## 环境分组

| 目录 | Python | 框架 | wheel 数 | 总字节 | 最低 glibc | 下载状态 | 目标机安装验证 |
| --- | --- | --- | ---: | ---: | --- | --- | --- |
| `01_scientific_notebook_py310` | 3.10 | NumPy / SciPy stack | 128 | 230220970 | 2.34 | downloaded | 未做 |
| `01_scientific_notebook_py312` | 3.12 | NumPy / SciPy stack | 124 | 234684247 | 2.34 | downloaded | 未做 |
| `02_ml_stats_timeseries_em_py310` | 3.10 | scikit-learn / statsmodels | 35 | 359768673 | 2.28 | downloaded | 未做 |
| `02_ml_stats_timeseries_em_py312` | 3.12 | scikit-learn / statsmodels | 34 | 282846930 | 2.28 | downloaded | 未做 |
| `03_signal_audio_image_py310` | 3.10 | scikit-learn / statsmodels | 73 | 269143293 | 2.28 | downloaded | 未做 |
| `03_signal_audio_image_py312` | 3.12 | scikit-learn / statsmodels | 68 | 266580658 | 2.28 | downloaded | 未做 |
| `04_pytorch_cpu_py310` | 3.10 | PyTorch CPU | 17 | 234093533 | 2.28 | downloaded | 未做 |
| `04_pytorch_cpu_py312` | 3.12 | PyTorch CPU | 17 | 248024144 | 2.28 | downloaded | 未做 |
| `05_gpr_bayesopt_py310` | 3.10 | PyTorch CPU + GPyTorch/BoTorch | 35 | 291326295 | 2.28 | downloaded | 未做 |
| `05_gpr_bayesopt_py312` | 3.12 | PyTorch CPU + GPyTorch/BoTorch | 31 | 303298975 | 2.28 | downloaded | 未做 |
| `06_bayesian_mcmc_py310` | 3.10 | PyMC / ArviZ | 45 | 107114510 | 2.28 | downloaded | 未做 |
| `06_bayesian_mcmc_py312` | 3.12 | PyMC / ArviZ | 42 | 164473847 | 2.28 | downloaded | 未做 |
| `07_tensorflow_cpu_py310` | 3.10 | TensorFlow CPU | 33 | 340715252 | 2.28 | downloaded | 未做 |
| `07_tensorflow_cpu_py312` | 3.12 | TensorFlow CPU | 33 | 337151276 | 2.28 | downloaded | 未做 |
| `07b_gpflow_tf218_py310` | 3.10 | GPflow + TensorFlow CPU | 53 | 976273858 | 2.31 | downloaded | 未做 |
| `07b_gpflow_tf218_py312` | 3.12 | GPflow + TensorFlow CPU | 52 | 969705661 | 2.31 | downloaded | 未做 |
| `08_rl_basics_py310` | 3.10 | PyTorch CPU + SB3 | 37 | 282878190 | 2.31 | downloaded | 未做 |
| `08_rl_basics_py312` | 3.12 | PyTorch CPU + SB3 | 35 | 296718183 | 2.31 | downloaded | 未做 |
| `09_huggingface_llm_py310` | 3.10 | PyTorch CPU + Hugging Face | 63 | 323173674 | 2.28 | downloaded | 未做 |
| `09_huggingface_llm_py312` | 3.12 | PyTorch CPU + Hugging Face | 59 | 341095654 | 2.28 | downloaded | 未做 |
| `10_onnx_api_ui_py310` | 3.10 | ONNX Runtime CPU | 84 | 231755451 | 2.28 | downloaded | 未做 |
| `10_onnx_api_ui_py312` | 3.12 | ONNX Runtime CPU | 76 | 231517200 | 2.28 | downloaded | 未做 |
| `11_optimization_control_py310` | 3.10 | CVXPY / CasADi | 28 | 220633166 | 2.28 | downloaded | 未做 |
| `11_optimization_control_py312` | 3.12 | CVXPY / CasADi | 30 | 241506141 | 2.28 | downloaded | 未做 |

## 本轮扩展（数据处理、工程与应用）

本段为增量扩展，未重新审计原 01–11 组。

| 目录 | Python | 用途 | wheel 数 | 总字节 | 最低 glibc | 下载状态 | 目标机安装验证 |
| --- | --- | --- | ---: | ---: | --- | --- | --- |
| `12_data_storage_py310` | 3.10 | 数据处理与存储 | 88 | 411926968 | 2.28 | downloaded | 未做 |
| `12_data_storage_py312` | 3.12 | 数据处理与存储（新 Python） | 91 | 413298641 | 2.28 | downloaded | 未做 |
| `13_stats_timeseries_py310` | 3.10 | 统计、计量与时间序列 | 95 | 299816380 | 2.28 | partial | 未做 |
| `13_stats_timeseries_py312` | 3.12 | 统计、计量与时间序列（新 Python） | 101 | 389171619 | 2.28 | partial | 未做 |
| `14_ml_tooling_py310` | 3.10 | 机器学习工程工具 | 199 | 388843918 | 2.28 | partial | 未做 |
| `14_ml_tooling_py312` | 3.12 | 机器学习工程工具（新 Python） | 193 | 329700505 | 2.28 | partial | 未做 |
| `15_nlp_retrieval_py310` | 3.10 | NLP 与检索 / RAG 基础 | 194 | 381246053 | 2.28 | partial | 未做 |
| `15_nlp_retrieval_py312` | 3.12 | NLP 与检索 / RAG 基础（新 Python） | 186 | 389867160 | 2.28 | partial | 未做 |
| `16_media_ocr_py310` | 3.10 | 图像、音视频与 OCR | 50 | 370952317 | 2.28 | downloaded | 未做 |
| `16_media_ocr_py312` | 3.12 | 图像、音视频与 OCR（新 Python） | 46 | 364902581 | 2.28 | downloaded | 未做 |
| `17_web_services_py310` | 3.10 | Web 与服务 | 137 | 49759814 | 2.28 | downloaded | 未做 |
| `17_web_services_py312` | 3.12 | Web 与服务（新 Python） | 138 | 53017696 | 2.28 | downloaded | 未做 |
| `18_database_py310` | 3.10 | 数据库与数据接入 | 46 | 157425274 | 2.28 | downloaded | 未做 |
| `18_database_py312` | 3.12 | 数据库与数据接入（新 Python） | 43 | 160986161 | 2.28 | downloaded | 未做 |
| `19_scraping_automation_py310` | 3.10 | 爬虫与自动化 | 75 | 87699127 | 2.28 | partial | 未做 |
| `19_scraping_automation_py312` | 3.12 | 爬虫与自动化（新 Python） | 73 | 88683128 | 2.28 | partial | 未做 |
| `20_documents_py310` | 3.10 | 文档处理 | 66 | 128972632 | 2.28 | downloaded | 未做 |
| `20_documents_py312` | 3.12 | 文档处理（新 Python） | 67 | 175883102 | 2.28 | downloaded | 未做 |
| `21_viz_dashboard_py310` | 3.10 | 可视化与仪表板 | 152 | 182375564 | 2.34 | downloaded | 未做 |
| `21_viz_dashboard_py312` | 3.12 | 可视化与仪表板（新 Python） | 148 | 173967817 | 2.34 | downloaded | 未做 |
| `21b_desktop_pyside6_py310` | 3.10 | 桌面 GUI（PySide6） | 17 | 289677054 | 2.34 | downloaded | 未做 |
| `21b_desktop_pyside6_py312` | 3.12 | 桌面 GUI（PySide6）（新 Python） | 16 | 289588522 | 2.34 | downloaded | 未做 |
| `22_engineering_py310` | 3.10 | 工程工具 | 146 | 114400107 | 2.34 | downloaded | 未做 |
| `22_engineering_py312` | 3.12 | 工程工具（新 Python） | 145 | 116200303 | 2.34 | downloaded | 未做 |
| `23_general_utils_py310` | 3.10 | 通用工具与云存储 SDK | 117 | 60734124 | 2.28 | downloaded | 未做 |
| `23_general_utils_py312` | 3.12 | 通用工具与云存储 SDK（新 Python） | 115 | 60998193 | 2.28 | downloaded | 未做 |

## 离线安装步骤（目标 Linux）

1. 确认 `uname -m` 为 `x86_64`，`ldd --version` 显示 glibc ≥ 本环境最低要求，且发行版为 glibc（非 musl）。
2. 解压对应 python-build-standalone：`tar -xzf runtimes/python_build_standalone/cpython-*.tar.gz`
3. `export PYTHON_BIN=/path/to/python/bin/python3`
4. 进入某一 `environments/<id>/`，执行 `bash install_offline_en.sh`
5. 用该 venv 运行 `check_environment_en.py`
6. 按需用发行版包管理器安装 `external_dependencies_cn.csv` 中的系统库。当前机器 **没有** apt install。

## 静态检查与未完成

- 已做：下载、wheel 文件名/METADATA/manylinux 标签检查、Ubuntu Packages 索引解析。
- 未做：解压或执行运行时、创建 venv、导入测试、训练、部署、GPU 包下载。
- 系统 `.deb` 若已下载，也 **不能** 宣称跨发行版离线系统依赖已经齐备；22.04 与 24.04 必须分别安装对应目录中的包。

## 嵌入式（增量）

详见 `embedded/README_cn.md` 与 `embedded/inventories/`。不以 Python wheel 数量代表嵌入式套件完整。
