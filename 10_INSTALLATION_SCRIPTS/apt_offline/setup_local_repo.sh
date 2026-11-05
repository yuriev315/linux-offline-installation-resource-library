#!/bin/bash
# Add the local repository as a permanent APT source. Idempotent. Existing source files are never changed.
# usage: sudo ./setup_local_repo.sh [--remove]
set -euo pipefail
. "$(cd "$(dirname "$0")/../dependency_installation" && pwd)/lib_offline.sh"
need_root; check_target
DST=/etc/apt/sources.list.d/linux-offline-noble.sources
KEY=/usr/share/keyrings/linux-offline-repo.gpg
if [ "${1:-}" = --remove ]; then
  # Only ever removes the two files this script itself created.
  rm -f "$DST" "$KEY"; log "removed $DST and $KEY"; exit 0
fi
check_repo_files
install -m 644 "$REPO/repository_keys/offline-repo-signing-key.gpg" "$KEY"
NEW=$(mktemp); trap 'rm -f "$NEW"' EXIT
cat > "$NEW" <<EOS
# Managed by Linux_Offline_Installation_Resource_Library/10_INSTALLATION_SCRIPTS/apt_offline/setup_local_repo.sh
Types: deb
URIs: file:$REPO
Suites: $SUITE
Components: main universe
Architectures: amd64
Signed-By: $KEY
EOS
if cmp -s "$NEW" "$DST" 2>/dev/null; then log "$DST already up to date"; else install -m 644 "$NEW" "$DST"; log "wrote $DST"; fi
log "done. On a machine with no internet, 'apt-get update' will warn about other configured sources; that is harmless."
