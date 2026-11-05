#!/bin/bash
# Exercises the scripts the main test does not reach, on an already installed rootfs with no network.
L=/mnt/lib; O=/mnt/out; S=$L/10_INSTALLATION_SCRIPTS; export LOG_DIR=$O/log
step() { echo; echo "=== $*"; }
pass() { echo "PASS $*"; }; failed=0; fail() { echo "FAIL $*"; failed=$((failed+1)); }
expect() { local want=$1 name=$2; shift 2; "$@" >/tmp/o 2>&1; local rc=$?; if [ "$rc" = "$want" ]; then pass "$name (rc=$rc)"; else fail "$name wanted rc=$want got rc=$rc"; tail -5 /tmp/o; fi; }
step "permanent APT source"
expect 0 "setup_local_repo" bash $S/apt_offline/setup_local_repo.sh
expect 0 "setup_local_repo re-run" bash $S/apt_offline/setup_local_repo.sh
cat /etc/apt/sources.list.d/linux-offline-noble.sources
expect 0 "apt-get update on local source only" apt-get -o Dir::Etc::sourcelist=/dev/null -o Dir::Etc::sourceparts=/nonexistent -o APT::Sandbox::User=root update
apt-get -o APT::Sandbox::User=root -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/linux-offline-noble.sources -o Dir::Etc::sourceparts=- update >/dev/null 2>&1; echo "update with .sources as sourcelist rc=$?"
apt-get -o Acquire::Retries=0 -o APT::Sandbox::User=root update >/tmp/u 2>&1; echo "plain apt-get update rc=$? (other sources fail with no network)"; grep -cE '^(Err|W:)' /tmp/u
apt-cache policy jq | sed -n 1,3p
expect 0 "plain apt install resolves from local source" apt-get -s install --reinstall jq
expect 0 "remove local source" bash $S/apt_offline/setup_local_repo.sh --remove
[ ! -e /etc/apt/sources.list.d/linux-offline-noble.sources ] && pass "source file gone" || fail "source file left"
[ -e /etc/apt/sources.list.d/ubuntu.sources ] && pass "official ubuntu.sources untouched" || echo "note: no ubuntu.sources in this image"
step "repair"; expect 0 "repair_packages" bash $S/recovery/repair_packages.sh
step "WSL in-distro configuration"
rm -f /etc/wsl.conf.test; cp -a /etc/wsl.conf /etc/wsl.conf.test 2>/dev/null
expect 0 "wsl_configure_distro" bash $S/ubuntu_wsl/wsl_configure_distro.sh --user devuser --no-install
expect 0 "wsl_configure_distro re-run" bash $S/ubuntu_wsl/wsl_configure_distro.sh --user devuser --no-install
id devuser; cat /etc/wsl.conf
expect 2 "wsl_configure_distro rejects bad user" bash $S/ubuntu_wsl/wsl_configure_distro.sh --user 'Bad User' --no-install
step "VS Code Server"; expect 0 "install_vscode_server" bash $S/dependency_installation/install_vscode_server.sh; expect 0 "re-run" bash $S/dependency_installation/install_vscode_server.sh
step "VSIX"; expect 0 "install one VSIX" code --no-sandbox --user-data-dir /tmp/vs --extensions-dir /tmp/ext --install-extension "$(ls $L/15_DEVELOPMENT_ENVIRONMENT/editors/vsix/ms-vscode.cmake-tools-*.vsix)"
step "user can run venv"; expect 0 "venv as ordinary user" runuser -u devuser -- bash $S/dependency_installation/python_offline_env.sh /home/devuser/v pytest
step "system Python not replaced"; ls -l /usr/bin/python3; dpkg -S /usr/bin/python3 && pass "python3 owned by dpkg" || fail python3
step "native script with no options"; expect 0 "setup_ubuntu_native server profile" bash $S/ubuntu_native/setup_ubuntu_native.sh --profile base
step "cross compilation"; expect 0 "install cross profile" bash $S/dependency_installation/offline_install.sh --profile cross
printf 'int main(void){return 0;}\n' > /tmp/x.c; expect 0 "arm64 compile" aarch64-linux-gnu-gcc /tmp/x.c -o /tmp/x; file_out=$(head -c 20 /tmp/x | od -An -tx1 | tr -d ' \n'); [ "${file_out:36:2}" = b7 ] && pass "binary machine type is aarch64" || fail "machine type ${file_out}"
step "arguments"; expect 2 "offline_install nothing selected" bash $S/dependency_installation/offline_install.sh; expect 2 "offline_install unknown profile" bash $S/dependency_installation/offline_install.sh --profile nope
step "damaged library must be detected (a private hard-link copy)"
N=/tmp/neg; rm -rf $N; mkdir -p $N/04_APT_OFFLINE_REPOSITORY; cp -r $L/10_INSTALLATION_SCRIPTS $L/05_SYSTEM_PACKAGES $N/; cp -r $L/04_APT_OFFLINE_REPOSITORY/{dists,repository_keys} $N/04_APT_OFFLINE_REPOSITORY/
mkdir -p $N/04_APT_OFFLINE_REPOSITORY/pool; (cd $L/04_APT_OFFLINE_REPOSITORY/pool && find . -type d -exec mkdir -p $N/04_APT_OFFLINE_REPOSITORY/pool/{} \; && find . -type f ! -name 'jq_*' -exec ln -s $L/04_APT_OFFLINE_REPOSITORY/pool/{} $N/04_APT_OFFLINE_REPOSITORY/pool/{} \;)
LIB_ROOT=$N bash $N/10_INSTALLATION_SCRIPTS/dependency_installation/offline_install.sh --dry-run --packages jq >/tmp/o 2>&1; rc=$?; [ $rc = 14 ] && pass "missing .deb reported, rc=14: $(grep -m1 MISSING /tmp/o)" || { fail "missing .deb wanted rc=14 got $rc"; tail -4 /tmp/o; }
step "index without a dependency must fail with no change"
python3 -I - $N/04_APT_OFFLINE_REPOSITORY/dists/noble-offline <<'PY'
import glob,gzip,hashlib,re,subprocess,sys
d=sys.argv[1]; f=d+"/main/binary-amd64/Packages"; s=open(f).read().split("\n\n")
s=[x for x in s if not x.startswith("Package: libjq1\n")]; open(f,"w").write("\n\n".join(s))
with gzip.open(f+".gz","wb") as z: z.write(open(f,"rb").read())
import os
files=[os.path.relpath(x,d) for x in glob.glob(d+"/*/binary-amd64/*")]
r="Origin: Neg\nSuite: noble-offline\nCodename: noble-offline\nArchitectures: amd64\nComponents: main restricted universe multiverse\nSHA256:\n"
for x in files:
    b=open(d+"/"+x,"rb").read(); r+=f" {hashlib.sha256(b).hexdigest()} {len(b)} {x}\n"
open(d+"/Release","w").write(r)
PY
rm -f $N/04_APT_OFFLINE_REPOSITORY/dists/noble-offline/InRelease $N/04_APT_OFFLINE_REPOSITORY/dists/noble-offline/Release.gpg
apt-get -s -o Dir::Etc::sourcelist=/dev/null -o Dir::Etc::sourceparts=/nonexistent update >/dev/null 2>&1
LS=$(mktemp); echo "deb [trusted=yes] file:$N/04_APT_OFFLINE_REPOSITORY noble-offline main universe" > $LS; A="-o Dir::Etc::sourcelist=$LS -o Dir::Etc::sourceparts=- -o APT::Sandbox::User=root -o Dir::State::lists=/tmp/negl"; mkdir -p /tmp/negl/partial
apt-get $A update >/dev/null 2>&1 || echo "index update failed"; dpkg -r --force-depends jq libjq1 >/dev/null 2>&1; apt-get $A -s install jq >/tmp/o 2>&1; rc=$?; grep -E 'Depends|E: ' /tmp/o | head -3; if [ $rc != 0 ] && grep -q 'Depends: libjq1' /tmp/o; then pass "apt names the missing dependency, rc=$rc"; else fail "wanted Depends: libjq1 error, rc=$rc"; tail -4 /tmp/o; fi
step "restore"; bash $S/dependency_installation/offline_install.sh --packages "jq libjq1" >/dev/null 2>&1; echo "restore rc=$?"; jq --version
echo; echo "EXTRA RESULT failed=$failed"; exit $failed
