#!/bin/bash
# Create a venv and install from the local wheelhouse only. Never touches the system Python.
# usage: python_offline_env.sh VENV_DIR [package ...]   (default packages: pytest pytest-cov build)
set -euo pipefail
LIB_ROOT="${LIB_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"; WH="$LIB_ROOT/07_PYTHON_BASE_ENVIRONMENT/wheelhouse"
V="${1:?usage: python_offline_env.sh VENV_DIR [package ...]}"; shift || true
[ $# -gt 0 ] || set -- pytest pytest-cov build
[ -x "$V/bin/python" ] || /usr/bin/python3 -m venv "$V"
"$V/bin/python" -m pip install --quiet --no-index --find-links "$WH" --upgrade pip setuptools wheel
"$V/bin/python" -m pip install --quiet --no-index --find-links "$WH" "$@"
"$V/bin/python" -m pip check
echo "venv ready: $V ($("$V/bin/python" --version), pip $("$V/bin/python" -m pip --version | cut -d' ' -f2))"
