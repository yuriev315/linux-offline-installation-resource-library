#!/bin/bash
# Inside an Ubuntu 24.04 VMware guest: install open-vm-tools from the local repository and configure shared folders.
# usage: sudo ./setup_vmware_guest.sh [--desktop] [--no-hgfs]
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd); . "$HERE/../dependency_installation/lib_offline.sh"
DESKTOP=0; HGFS=1
while [ $# -gt 0 ]; do case "$1" in --desktop) DESKTOP=1; shift;; --no-hgfs) HGFS=0; shift;; *) die "unknown argument: $1" 2;; esac; done
need_root; check_target
V=$(systemd-detect-virt 2>/dev/null || true); [ "$V" = vmware ] || log "WARNING: virtualization is '$V', not vmware. Continuing, but tools will not be active here."
P="open-vm-tools fuse3"; [ "$DESKTOP" = 1 ] && P="$P open-vm-tools-desktop xserver-xorg-video-vmware"
bash "$HERE/../dependency_installation/offline_install.sh" --packages "$P"
if [ "$HGFS" = 1 ]; then
  mkdir -p /mnt/hgfs
  grep -q '^vmhgfs-fuse /mnt/hgfs' /etc/fstab || { cp -n /etc/fstab /etc/fstab.before-offline-library; echo 'vmhgfs-fuse /mnt/hgfs fuse defaults,allow_other,nofail,x-systemd.automount 0 0' >> /etc/fstab; log "added /mnt/hgfs to /etc/fstab"; }
  grep -qE '^\s*user_allow_other' /etc/fuse.conf 2>/dev/null || echo user_allow_other >> /etc/fuse.conf
fi
systemctl enable --now open-vm-tools 2>/dev/null || log "open-vm-tools not started (needs a VMware guest with systemd)"
log "vmware guest setup finished; reboot to activate desktop integration"
