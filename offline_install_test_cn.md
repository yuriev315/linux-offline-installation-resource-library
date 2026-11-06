# 离线安装测试（2026-11-06）

测试主机：Ubuntu 26.04.1 LTS x86-64，glibc 2.43，python-build-standalone 3.10.22 / 3.12.16。每个环境组用其 `install_offline_en.sh`（`--no-index`，不联网）新建 venv 安装，再运行组内 `check_environment_en.py`；测试后删除 venv。
这台主机不是 Ubuntu 22.04/24.04 参考系统，也没有安装各组需要的系统 deb，所以依赖系统库的导入失败不代表 wheel 有问题。开发板资源、系统镜像和 deb 没有做安装测试。

- 离线安装成功：50 / 50 组
- 检查脚本全部通过：32 / 50 组；其余组的失败原因见下表

## 测试前做的修正

第一次测试有 12 组安装失败。准备脚本生成的锁定清单按 wheelhouse 中每个包的最高版本生成，wheelhouse 里同一个包有多个版本时会互相冲突。下列各组的 `requirements_lock_en.txt` 已改为用本组目标解释器在本 wheelhouse 内离线解析（`pip install --dry-run --no-index`）的结果；`wheel_inventory_cn.csv` 与 `package_inventory_cn.csv` 已同步更新。

| 用途组（3.10 与 3.12） | 修正 |
| --- | --- |
| `02_ml_stats_timeseries_em` | xgboost 的 manylinux_2_28 wheel 依赖 NVIDIA NCCL GPU wheel（已排除），改用官方 CPU 版 `xgboost-cpu`（同版本）；`xgboost` wheel 移入 `rejected_not_default/` |
| `09_huggingface_llm` | 锁定清单改为在本 wheelhouse 内用目标解释器离线解析的结果（脚本生成的清单按每个包的最高版本生成，fsspec 版本互相冲突） |
| `10_onnx_api_ui` | 锁定清单离线重新解析，并加约束 `huggingface-hub<1.0`（gradio 仍导入 1.0 已删除的 `HfFolder`） |
| `13_stats_timeseries` | wheelhouse 中 sktime 与 pykalman 的版本无法同时满足；按同样的平台与 glibc 限制补下一组可共同解析的 wheel 后离线重新解析 |
| `14_ml_tooling` | 锁定清单离线重新解析，并加约束 `setuptools<81`（featuretools 仍需 `pkg_resources`） |
| `15_nlp_retrieval` | 锁定清单离线重新解析；3.10 补下 `async-timeout` 4.x（langchain-classic 要求 <5） |
| `22_engineering` | `nvidia-ml-py` 是纯 Python 的 NVML 绑定（BSD），不是 GPU 二进制，准备脚本的 GPU 过滤误移到 `rejected_not_default/`；scalene 需要它，已放回 wheelhouse，并离线重新解析锁定清单 |
| `23_general_utils` | 锁定清单离线重新解析，并加约束 `setuptools<81`（hydra 仍需 `pkg_resources`） |

## 结果

| 环境组 | 离线安装 | 检查脚本 | 说明 |
| --- | --- | --- | --- |
| `01_scientific_notebook_py310` | ok | ok | pip check 无冲突 |
| `01_scientific_notebook_py312` | ok | ok | pip check 无冲突 |
| `02_ml_stats_timeseries_em_py310` | ok | ok | pip check 无冲突 |
| `02_ml_stats_timeseries_em_py312` | ok | ok | pip check 无冲突 |
| `03_signal_audio_image_py310` | ok | ok | pip check 无冲突 |
| `03_signal_audio_image_py312` | ok | ok | pip check 无冲突 |
| `04_pytorch_cpu_py310` | ok | ok | pip check 无冲突 |
| `04_pytorch_cpu_py312` | ok | ok | pip check 无冲突 |
| `05_gpr_bayesopt_py310` | ok | ok | pip check 无冲突 |
| `05_gpr_bayesopt_py312` | ok | ok | pip check 无冲突 |
| `06_bayesian_mcmc_py310` | ok | ok | pip check 无冲突 |
| `06_bayesian_mcmc_py312` | ok | ok | pip check 无冲突 |
| `07_tensorflow_cpu_py310` | ok | ok | pip check 无冲突 |
| `07_tensorflow_cpu_py312` | ok | ok | pip check 无冲突 |
| `07b_gpflow_tf218_py310` | ok | ok | pip check 无冲突 |
| `07b_gpflow_tf218_py312` | ok | ok | pip check 无冲突 |
| `08_rl_basics_py310` | ok | ok | pip check 无冲突 |
| `08_rl_basics_py312` | ok | ok | pip check 无冲突 |
| `09_huggingface_llm_py310` | ok | ok | pip check 无冲突 |
| `09_huggingface_llm_py312` | ok | ok | pip check 无冲突 |
| `10_onnx_api_ui_py310` | ok | ok | pip check 无冲突 |
| `10_onnx_api_ui_py312` | ok | ok | pip check 无冲突 |
| `11_optimization_control_py310` | ok | ok | pip check 无冲突 |
| `11_optimization_control_py312` | ok | ok | pip check 无冲突 |
| `12_data_storage_py310` | ok | ok | pip check 无冲突 |
| `12_data_storage_py312` | ok | ok | pip check 无冲突 |
| `13_stats_timeseries_py310` | ok | FAIL | pip check 无冲突；ta：仅有源码包，未构建，见 `sdist_needs_build/` |
| `13_stats_timeseries_py312` | ok | FAIL | pip check 无冲突；ta：仅有源码包，未构建，见 `sdist_needs_build/` |
| `14_ml_tooling_py310` | ok | FAIL | pip check 无冲突；lime：仅有源码包，未构建，见 `sdist_needs_build/` |
| `14_ml_tooling_py312` | ok | FAIL | pip check 无冲突；lime：仅有源码包，未构建，见 `sdist_needs_build/`；evidently：evidently 与本组 pandas 版本不兼容（导入 pandas 内部函数失败），未修正 |
| `15_nlp_retrieval_py310` | ok | FAIL | pip check 无冲突；jieba：仅有源码包，未构建，见 `sdist_needs_build/` |
| `15_nlp_retrieval_py312` | ok | FAIL | pip check 无冲突；jieba：仅有源码包，未构建，见 `sdist_needs_build/` |
| `16_media_ocr_py310` | ok | FAIL | pip check 无冲突；cv2：测试主机缺系统库 libGL.so.1，见 `system_dependencies/`（libgl1）；rapidocr_onnxruntime：测试主机缺系统库 libGL.so.1，见 `system_dependencies/`（libgl1） |
| `16_media_ocr_py312` | ok | FAIL | pip check 无冲突；cv2：测试主机缺系统库 libGL.so.1，见 `system_dependencies/`（libgl1）；rapidocr_onnxruntime：测试主机缺系统库 libGL.so.1，见 `system_dependencies/`（libgl1） |
| `17_web_services_py310` | ok | FAIL | pip check 无冲突；检查脚本固定做 numpy 运算，本组不含 numpy，属检查脚本误报；全部目标导入成功 |
| `17_web_services_py312` | ok | FAIL | pip check 无冲突；检查脚本固定做 numpy 运算，本组不含 numpy，属检查脚本误报；全部目标导入成功 |
| `18_database_py310` | ok | ok | pip check 无冲突 |
| `18_database_py312` | ok | ok | pip check 无冲突 |
| `19_scraping_automation_py310` | ok | FAIL | pip check 无冲突；检查脚本固定做 numpy 运算，本组不含 numpy，属检查脚本误报；全部目标导入成功 |
| `19_scraping_automation_py312` | ok | FAIL | pip check 无冲突；检查脚本固定做 numpy 运算，本组不含 numpy，属检查脚本误报；全部目标导入成功 |
| `20_documents_py310` | ok | FAIL | pip check 无冲突；weasyprint：测试主机缺系统库 Pango，见 `system_dependencies/*/expansion_debs/` |
| `20_documents_py312` | ok | FAIL | pip check 无冲突；weasyprint：测试主机缺系统库 Pango，见 `system_dependencies/*/expansion_debs/` |
| `21_viz_dashboard_py310` | ok | ok | pip check 无冲突 |
| `21_viz_dashboard_py312` | ok | ok | pip check 无冲突 |
| `21b_desktop_pyside6_py310` | ok | FAIL | pip check 无冲突；pyqtgraph：测试主机缺系统库 libGL.so.1，见 `system_dependencies/`（libgl1） |
| `21b_desktop_pyside6_py312` | ok | FAIL |  |
| `22_engineering_py310` | ok | ok | pip check 无冲突 |
| `22_engineering_py312` | ok | ok | pip check 无冲突 |
| `23_general_utils_py310` | ok | FAIL | pip check 无冲突；检查脚本固定做 numpy 运算，本组不含 numpy，属检查脚本误报；全部目标导入成功 |
| `23_general_utils_py312` | ok | FAIL | pip check 无冲突；检查脚本固定做 numpy 运算，本组不含 numpy，属检查脚本误报；全部目标导入成功 |

逐组明细：`offline_install_test_cn.csv`。
