# Linux Python 3.10.22 信号处理定向补充

# 信号处理定向补充（Linux x86-64，Python 3.10 与 3.12）

本包是 Release `python-offline-2026.11.06` 的配套补充，单独发布在 Release `python-offline-signal-v1-2026.11.06`；不改各环境组的 `requirements_lock_en.txt`。

## 覆盖范围

| 能力 | 包 | 说明 |
| --- | --- | --- |
| 傅里叶 / 频谱 | NumPy、SciPy | 已在 **03 信号** 组，本包不重复下载 x86-64 二进制 |
| 小波分解与重构 | PyWavelets | 同上，03 组已有对应 CPython 版本的 wheel |
| EMD / EEMD / CEEMDAN | **EMD-signal** | pip 名 `EMD-signal`，**导入名 `PyEMD`** |
| Kalman 实时滤波 | filterpy | `predict` / `update`，因果 |
| Kalman 离线平滑 | pykalman | `filter` 因果；`smooth` 使用未来观测，仅离线 |

## 安装（在已有 03 环境上追加）

先按环境组目录装好 `03_signal_audio_image_*`，再在同一个 venv 中执行：

```bash
bash ./install_supplement_en.sh
```

脚本只会安装 `requirements_supplement_en.txt` 中的**新增**包，并从 `packages_wheel/` 以及03 组（及 13 组）wheelhouse 解析依赖。

必须使用 `runtimes/` 中对应的 CPython **3.10.22 / 3.12.16**，不要装进 3.14。

## 实时滤波 vs 离线平滑

- **实时 / 因果**：`filterpy.kalman.KalmanFilter.predict` + `update`，或 `pykalman.KalmanFilter.filter`。时刻 t 的输出只依赖 `z[0]..z[t]`。
- **离线平滑**：`pykalman.KalmanFilter.smooth`（RTS）。时刻 t 的输出依赖 `z[0]..z[N-1]`，含未来观测。滞后更小、误差通常更低，**不能**接到必须在采样时刻给出估计的控制回路。

## 开发板

库中开发板侧是 Raspberry Pi OS Bookworm **Python 3.11** 的 GPIO 通讯包，**不是** 3.10/3.12。
本包不为 3.11 板子补信号库，也不把 **x86-64** 二进制放进板端目录。
仅当存在 **aarch64 + 对应 CPython 3.10/3.12** 的 wheel 时，才写入 `embedded_boards/aarch64/`。
armv7l 若无官方 wheel，源码与构建依赖放在 `packages_sdist_unbuilt/`，状态为 **未构建、未验证**。

## 示例是否执行验证

`examples/` 下脚本仅作最小调用示意。本轮在下载主机上**未安装、未导入、未跑通**这些示例（状态：`未执行验证`）。

目标：Linux x86-64 glibc，CPython 3.10.22。
NumPy / SciPy / PyWavelets 复用原 03 组已有兼容 wheel，见 `reused_from_original_cn.csv` 仅记录本包实际硬链接到的文件。
本包新增主要是 EMD-signal（PyEMD）、filterpy、pykalman 及 pathos/scikit-base 等传递依赖。

