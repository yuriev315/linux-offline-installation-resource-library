#!/bin/bash
# Install the full development environment from local files: APT profile, Node.js, PATH for Go and Rust.
# Safe to re-run. /usr/bin/python3 and other system files are never replaced.
# usage: sudo ./install_dev_environment.sh [--profile fulldev] [--skip-node]
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd); . "$HERE/lib_offline.sh"
P=fulldev; NODE=1
while [ $# -gt 0 ]; do case "$1" in --profile) P=$2; shift 2;; --skip-node) NODE=0; shift;; *) die "unknown argument: $1" 2;; esac; done
need_root; check_target
bash "$HERE/offline_install.sh" --profile "$P"
PD=/etc/profile.d/linux-offline-dev-paths.sh
cat > "$PD.tmp" <<'EOP'
# Versioned Ubuntu Go and Rust toolchains; added by the offline library.
for d in /usr/lib/go-1.26/bin /usr/lib/rust-1.91/bin /opt/node-current/bin; do
  case ":$PATH:" in *":$d:"*) ;; *) [ -d "$d" ] && PATH="$PATH:$d";; esac
done
export PATH
EOP
mv "$PD.tmp" "$PD"; chmod 644 "$PD"
if [ "$NODE" = 1 ]; then
  T=$(ls "$LIB_ROOT"/15_DEVELOPMENT_ENVIRONMENT/language_runtimes/node/node-*-linux-x64.tar.xz); V=$(basename "$T" -linux-x64.tar.xz)
  (cd "$(dirname "$T")" && grep " $(basename "$T")\$" SHASUMS256.txt | sha256sum -c - >/dev/null) || die "Node.js checksum failed" 30
  [ -x "/opt/$V-linux-x64/bin/node" ] || tar -xJf "$T" -C /opt
  [ -L /opt/node-current ] || [ ! -e /opt/node-current ] || die "/opt/node-current exists and is not a symlink; left alone" 31
  ln -sfn "/opt/$V-linux-x64" /opt/node-current
  log "Node.js $V at /opt/node-current"
fi
log "development environment installed. Open a new shell, or run: . $PD"
