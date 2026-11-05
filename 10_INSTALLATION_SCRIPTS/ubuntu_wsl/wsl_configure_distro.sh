#!/bin/bash
# Run INSIDE the imported Ubuntu distro as root. Creates the default user and installs offline packages.
# usage: wsl_configure_distro.sh --user NAME [--profile wsl|dev|base|...] [--no-install]
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd); . "$HERE/../dependency_installation/lib_offline.sh"
U=""; P=wsl; INST=1
while [ $# -gt 0 ]; do case "$1" in --user) U=$2; shift 2;; --profile) P=$2; shift 2;; --no-install) INST=0; shift;; *) die "unknown argument: $1" 2;; esac; done
[ -n "$U" ] || die "--user is required" 2
need_root; check_target
[[ "$U" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || die "invalid user name: $U" 2
if id "$U" >/dev/null 2>&1; then log "user $U exists"; else useradd -m -s /bin/bash -G sudo "$U"; passwd -l "$U" >/dev/null; log "created user $U (set a password with: passwd $U)"; fi
if [ -e /etc/wsl.conf ]; then
  grep -q '^\[user\]' /etc/wsl.conf || printf '\n[user]\ndefault=%s\n' "$U" >> /etc/wsl.conf
  log "kept existing /etc/wsl.conf (it must contain [user] default=$U to take effect)"
else
  sed "s/DEFAULT_USER/$U/" "$LIB_ROOT/11_CONFIGURATIONS/wsl/wsl.conf.template" > /etc/wsl.conf; log "wrote /etc/wsl.conf"
fi
[ "$INST" = 1 ] && bash "$HERE/../dependency_installation/offline_install.sh" --profile "$P"
log "distro configured. From Windows run: wsl --terminate <name>, then start it again."
