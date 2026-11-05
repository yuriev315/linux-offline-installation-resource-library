#!/bin/bash
# Install Visual Studio Code and extensions from local files. Microsoft's license applies; the repository only has
# .url placeholders, so fetch them first with recovery/fetch_url_placeholders.sh --only vscode while online.
# usage: sudo ./install_vscode.sh [--extensions-for USER]
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd); . "$HERE/lib_offline.sh"
E="$LIB_ROOT/15_DEVELOPMENT_ENVIRONMENT/editors"; U=""
[ "${1:-}" = --extensions-for ] && U=${2:?}
DEB=$(ls "$E"/vscode/code_*_amd64.deb 2>/dev/null | head -1) || true
[ -n "$DEB" ] || die "VS Code package not found in $E/vscode. Run recovery/fetch_url_placeholders.sh --only vscode while online." 40
bash "$HERE/offline_install.sh" --deb "$DEB"
if [ -n "$U" ]; then
  for x in "$E"/vsix/*.vsix; do runuser -u "$U" -- code --install-extension "$x" --force; done
fi
log "VS Code installed"
