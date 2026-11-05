#!/bin/bash
# usage: make_seed.sh KIND OUTDIR  — writes the autoinstall user-data for KIND=server|desktop
K=$1; O=$2; mkdir -p "$O"
# Test-only account for an isolated VM: tester / OfflineTest1!
PW='$6$offlinetest$.236Em/ylwXx/zcRdCRoY3LkHx2O/V.2.2HOScmZqBrWWEYPn.NKGjwZXomtlQHoXTEUhntnPFdvdMHaYBSpH.'
cat > "$O/meta-data" <<M
instance-id: offline-$K
M
{ cat <<U
#cloud-config
autoinstall:
  version: 1
  interactive-sections: []
  identity: {hostname: offline-$K, username: tester, password: "$PW"}
  storage: {layout: {name: direct}}
  apt: {fallback: offline-install, geoip: false}
  updates: security
  shutdown: poweroff
  late-commands:
    - mkdir -p /target/mnt/testscripts
    - sh -c 'echo $K > /target/etc/offtest-kind'
    - mount -o ro /dev/disk/by-label/OFFLINELIB /mnt && cp /mnt/13_TESTS/installation_tests/guest_test.sh /target/usr/local/sbin/guest_test.sh; umount /mnt || true
    - chmod +x /target/usr/local/sbin/guest_test.sh
    - sh -c 'printf "[Unit]\nDescription=offline test\nAfter=local-fs.target systemd-udev-settle.service\n[Service]\nType=oneshot\nExecStart=/usr/local/sbin/guest_test.sh\nStandardOutput=journal+console\nTimeoutStartSec=0\n[Install]\nWantedBy=multi-user.target\n" > /target/etc/systemd/system/offline-test.service'
    - chroot /target systemctl enable offline-test.service
U
[ "$K" = desktop ] && printf '  source: {id: ubuntu-desktop-minimal}\n'; true; } > "$O/user-data"
