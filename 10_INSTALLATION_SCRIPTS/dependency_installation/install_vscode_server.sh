#!/bin/bash
# Pre-install the matching VS Code Server for the current user, so Remote-SSH and Remote-WSL work with no internet.
# usage: ./install_vscode_server.sh      (run as the target user; root not needed)
set -euo pipefail
LIB_ROOT="${LIB_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"; E="$LIB_ROOT/15_DEVELOPMENT_ENVIRONMENT/editors/vscode_server"
T="$E/vscode-server-linux-x64.tar.gz"; [ -f "$T" ] || { echo "Not found: $T. Run recovery/fetch_url_placeholders.sh --only vscode while online." >&2; exit 40; }
C=$(cat "$E/COMMIT"); D="$HOME/.vscode-server/cli/servers/Stable-$C/server"
if [ -x "$D/bin/code-server" ]; then echo "already installed: $D"; exit 0; fi
mkdir -p "$D"; tar -xzf "$T" -C "$D" --strip-components=1
"$D/bin/code-server" --version
