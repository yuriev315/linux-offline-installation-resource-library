# Linux offline Python resources for research (x86-64, glibc, CPU)

Offline package sets for Linux x86-64 with glibc (reference: Ubuntu 22.04 and 24.04 LTS):

- 50 Python environment groups (CPython 3.10 and 3.12, one wheelhouse, lock file, offline install script and check script per group)
- Python runtimes: python-build-standalone 3.10.22 / 3.12.16 and the official CPython source tarballs
- Ubuntu 22.04 / 24.04 system `.deb` closures (runtime, build, expansion)
- Embedded development: host toolchains, Arduino/ESP cores, Raspberry Pi board wheels and debs, MicroPython/CircuitPython firmware, Linux SBC system images

Everything here was downloaded and statically checked only; nothing was installed or run on a target machine or board.
Chinese documentation starts at `README_cn.md` and `index_cn.html` (open it in a browser after extracting the tar files).
Download and extraction instructions: `download_restore_cn.md`.
Files that may not be redistributed (NVIDIA Jetson L4T packages, NVIDIA NCCL wheels) are `.url` placeholders with the official link, size and SHA-256; see `restricted_placeholders_cn.csv`.
