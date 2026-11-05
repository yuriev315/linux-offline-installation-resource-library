#!/bin/bash
# Runs inside the isolated chroot.
L=/mnt/lib; O=/mnt/out; S=$L/10_INSTALLATION_SCRIPTS/dependency_installation; export LOG_DIR=$O/log
step() { echo "=== $*"; }
step "network proof"; if timeout 8 bash -c 'exec 3<>/dev/tcp/185.125.190.81/80' 2>/dev/null; then echo 'NETWORK REACHABLE - TEST INVALID'; exit 99; else echo 'no route to the internet (expected)'; fi; timeout 5 getent hosts archive.ubuntu.com || echo 'dns: unreachable (expected)'
step "negative: unknown package must fail"; bash $S/offline_install.sh --dry-run --packages this-package-does-not-exist; echo "rc=$?"
step "deep repo check + dry run fulldev"; bash $S/offline_install.sh --deep-check --dry-run --profile fulldev >/dev/null; echo "rc=$?"
step "install fulldev"; time bash $S/install_dev_environment.sh --profile fulldev; echo "install rc=$?"
step "re-run must be idempotent"; bash $S/install_dev_environment.sh --profile fulldev >/dev/null 2>&1; echo "rerun rc=$?"
step "repo-only check of all installed packages"; dpkg-query -W -f='${Package} ${Version} ${Status}\n' | awk '$3!="install"||$5!="installed"' | head; apt-get -s -o Dir::Etc::sourcelist=/dev/null check 2>&1 | tail -1
step "vmware guest packages"; bash $S/offline_install.sh --packages "open-vm-tools fuse3" >/dev/null 2>&1; echo "rc=$?"; vmhgfs-fuse --version 2>&1 | head -1
step "vscode"; bash $S/install_vscode.sh >/dev/null 2>&1; echo "rc=$?"
step "verify"; bash $L/13_TESTS/dev_environment/verify_dev_environment.sh --report $O/verify.csv; echo "verify rc=$?"
step "system tools"; bash $L/13_TESTS/system_tests/verify_system_tools.sh --report $O/system.csv; echo "system rc=$?"
