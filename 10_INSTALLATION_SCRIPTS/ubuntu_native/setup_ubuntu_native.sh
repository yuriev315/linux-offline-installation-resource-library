#!/bin/bash
# After installing Ubuntu 24.04 from ISO: check the system, install offline packages, and optionally configure it.
# Safe to re-run. Options that change configuration are opt-in, and never overwrite existing files.
# usage: sudo ./setup_ubuntu_native.sh [--profile server] [--with-kernel] [--enable-ssh] [--timezone Area/City] [--locale xx_YY.UTF-8] [--netplan-dhcp IFACE]
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd); . "$HERE/../dependency_installation/lib_offline.sh"
PROFILE=server; KERNEL=0; SSH=0; TZV=""; LOC=""; NETIF=""
while [ $# -gt 0 ]; do case "$1" in
 --profile) PROFILE=$2; shift 2;; --with-kernel) KERNEL=1; shift;; --enable-ssh) SSH=1; shift;;
 --timezone) TZV=$2; shift 2;; --locale) LOC=$2; shift 2;; --netplan-dhcp) NETIF=$2; shift 2;;
 *) die "unknown argument: $1" 2;; esac; done
need_root; check_target
log "== system"; uname -a | tee -a "$LOG_FILE"; grep -m1 'model name' /proc/cpuinfo | tee -a "$LOG_FILE" || true; free -h | tee -a "$LOG_FILE"
log "== storage"; lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT 2>/dev/null | tee -a "$LOG_FILE" || true; df -hT -x tmpfs -x devtmpfs -x squashfs | tee -a "$LOG_FILE"
A=(--profile "$PROFILE"); [ "$KERNEL" = 1 ] && A+=(--profile kernel)
bash "$HERE/../dependency_installation/offline_install.sh" "${A[@]}"
if [ "$SSH" = 1 ]; then
  D=/etc/ssh/sshd_config.d/50-offline-library.conf
  [ -e "$D" ] || install -m 644 "$LIB_ROOT/11_CONFIGURATIONS/ssh/50-offline-library.conf" "$D"
  sshd -t && systemctl enable --now ssh; log "ssh enabled"
fi
if [ -n "$TZV" ]; then timedatectl set-timezone "$TZV" && log "timezone $TZV"; fi
if [ -n "$LOC" ]; then locale-gen "$LOC" >/dev/null && update-locale LANG="$LOC" && log "locale $LOC"; fi
if [ -n "$NETIF" ]; then
  N=/etc/netplan/60-offline-$NETIF.yaml
  if [ -e "$N" ]; then log "$N exists; left alone"; else
    sed "s/IFACE/$NETIF/" "$LIB_ROOT/11_CONFIGURATIONS/networking/60-offline-dhcp.yaml.template" > "$N"; chmod 600 "$N"; netplan generate && log "wrote $N; run 'netplan apply' to activate"
  fi
fi
log "native setup finished"
