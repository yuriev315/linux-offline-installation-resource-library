#!/bin/bash
# Runs inside the freshly installed VM at first boot, on a machine with no network device at all.
mkdir -p /mnt/lib /mnt/out; mount -o ro /dev/disk/by-label/OFFLINELIB /mnt/lib; mount /dev/disk/by-label/TESTRESULT /mnt/out
K=$(cat /proc/cmdline | tr ' ' '\n' | grep '^offtest=' | cut -d= -f2); : "${K:=$(cat /etc/offtest-kind)}"
O=/mnt/out/$K; mkdir -p "$O"; exec >>"$O/console.log" 2>&1
export LOG_DIR=$O/log LIB_ROOT=/mnt/lib
S=/mnt/lib/10_INSTALLATION_SCRIPTS
if [ -f /var/lib/offtest-stage1-done ]; then
  echo "=== stage 2 after reboot"; uname -r; systemctl is-system-running; systemctl --failed --no-legend | head -20
  systemctl is-active open-vm-tools 2>&1; dpkg -l open-vm-tools | tail -1
  if [ "$K" = desktop ]; then echo "=== graphical login"; systemctl set-default graphical.target; systemctl start gdm3; sleep 75; systemctl is-active gdm3 gnome-remote-desktop 2>&1 | head -2; loginctl list-sessions --no-legend | head -5; pgrep -a gnome-shell | head -2 | cut -c1-100; dpkg-query -W ubuntu-desktop-minimal gdm3 gnome-shell; fi
  echo STAGE2-DONE; sync; systemctl disable offline-test.service; umount /mnt/out; systemctl poweroff; exit 0
fi
echo "=== kind=$K"; date -u; . /etc/os-release; echo "$PRETTY_NAME"; uname -r; cat /etc/machine-id >/dev/null
echo "=== network proof"; ip -o link; ip route; if timeout 5 bash -c 'exec 3<>/dev/tcp/185.125.190.81/80' 2>/dev/null; then echo 'NETWORK REACHABLE - TEST INVALID'; else echo 'no route to the internet (expected)'; fi
echo "=== packages at first boot"; dpkg-query -W | wc -l
echo "=== native script"; bash $S/ubuntu_native/setup_ubuntu_native.sh --profile server --with-kernel --enable-ssh --timezone Asia/Shanghai; echo "native rc=$?"
echo "=== rerun (idempotency)"; bash $S/ubuntu_native/setup_ubuntu_native.sh --profile server --with-kernel --enable-ssh --timezone Asia/Shanghai >/dev/null 2>&1; echo "rerun rc=$?"
echo "=== full dev environment"; bash $S/dependency_installation/install_dev_environment.sh --profile fulldev; echo "dev rc=$?"
echo "=== extra packages"; bash $S/dependency_installation/offline_install.sh --profile extras --profile apt-tools; echo "extras rc=$?"; apt-offline --version 2>&1 | head -1; aptly version 2>&1 | head -1; apt-rdepends --help 2>&1 | head -1 | cut -c1-60
echo "=== vmware guest packages (installed under QEMU; only package-level verification)"; bash $S/ubuntu_vmware/setup_vmware_guest.sh $( [ "$K" = desktop ] && echo --desktop ); echo "vmware rc=$?"
echo "=== vscode"; bash $S/dependency_installation/install_vscode.sh; echo "vscode rc=$?"
echo "=== dpkg audit"; dpkg --audit; echo "audit lines: $(dpkg --audit | wc -l)"
echo "=== verify"; bash /mnt/lib/13_TESTS/dev_environment/verify_dev_environment.sh --report "$O/verify.csv"; echo "verify rc=$?"
echo "=== system tools"; bash /mnt/lib/13_TESTS/system_tests/verify_system_tools.sh --report "$O/system.csv"; echo "system rc=$?"
touch /var/lib/offtest-stage1-done; echo "=== rebooting to check the installed kernel boots"; sync; systemctl reboot
