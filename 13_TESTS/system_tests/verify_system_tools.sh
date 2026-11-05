#!/bin/bash
# Functional checks of system, network, storage and archive tools. Works only inside a temporary directory.
# Loop-device checks need root and are skipped in containers. Exit code is the FAIL count.
# usage: verify_system_tools.sh [--report FILE]
REPORT=""; [ "${1:-}" = --report ] && REPORT=$2
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT; cd "$W" || exit 99
P=0; F=0; K=0
out() { echo "$1 $2${3:+  ($3)}"; [ -z "$REPORT" ] || echo "$1,$2,$3" >> "$REPORT"; }
check() { local n=$1 c=$2 o rc f="$W/.check_output"; timeout -k 10 120 bash -c "$c" >"$f" 2>&1 </dev/null; rc=$?; o=$(cat "$f"); if [ $rc = 0 ]; then out PASS "$n"; P=$((P+1)); else out FAIL "$n" "rc=$rc $(tail -1 <<<"$o" | cut -c1-150 | tr ',' ' ')"; F=$((F+1)); fi; }
for c in systemctl journalctl apt dpkg sudo locale htop tmux screen lsof strace rsync crontab logrotate smartctl sensors lspci lsusb dmidecode nvme hdparm iostat mpstat vmstat ip ping netstat dig traceroute tcpdump curl wget ssh sshd nc socat nmap ethtool nmcli fdisk parted gdisk mkfs.ext4 mkfs.xfs mkfs.btrfs mkfs.vfat mkfs.ntfs ntfs-3g mkfs.exfat lvm mdadm cryptsetup tar gzip bzip2 xz zstd zip unzip 7z iotop fio stress-ng; do
  check "cmd:$c" "command -v $c"
done
check "archive-roundtrip" 'head -c 300000 /dev/urandom > d; for a in "gzip -k" "bzip2 -k" "xz -k" "zstd -q"; do $a d; done; gzip -t d.gz && bzip2 -t d.bz2 && xz -t d.xz && zstd -qt d.zst && zip -q d.zip d && unzip -tq d.zip && 7z a -bd d.7z d >/dev/null && 7z t d.7z >/dev/null && tar -cf d.tar d && tar -tf d.tar'
check "openssl" 'openssl rand -hex 8 | grep -E "^[0-9a-f]{16}$" && openssl dgst -sha256 /etc/os-release'
check "gnupg" 'gpg --version | head -1'
check "ssh-keygen" 'ssh-keygen -q -t ed25519 -N "" -f k && test -s k.pub'
check "sshd-config" 'mkdir -p /run/sshd; sshd -t'
check "curl-local" 'echo hi > f; curl -fsS "file://$PWD/f" | grep -q hi'
check "rsync-local" 'mkdir s; echo a > s/a; rsync -a s/ t/ && test -f t/a'
check "loopback-ping" 'ip link set lo up 2>/dev/null; ping -c1 -W2 127.0.0.1'
check "socat-nc-loopback" '(socat -u TCP-LISTEN:45871,reuseaddr,bind=127.0.0.1 OPEN:r.txt,creat &) ; sleep 1; echo hi | nc -q1 127.0.0.1 45871; sleep 1; grep -q hi r.txt'
check "stress-ng" 'stress-ng --cpu 1 --timeout 2s --quiet'
check "fio" 'fio --name=t --filename=fio.dat --size=8m --bs=64k --rw=write --ioengine=sync --end_fsync=1 --output-format=terse'
check "sysstat" 'iostat -V; vmstat 1 1'
for fs in "ext4:mkfs.ext4 -q -F" "xfs:mkfs.xfs -q -f" "btrfs:mkfs.btrfs -q -f" "vfat:mkfs.vfat" "exfat:mkfs.exfat" "ntfs:mkfs.ntfs -q -F"; do n=${fs%%:*}; c=${fs#*:}; check "mkfs:$n" "truncate -s 512M i_$n; $c i_$n"; done
check "parted-gdisk-on-image" 'truncate -s 128M p.img; parted -s p.img mklabel gpt mkpart a ext4 1MiB 100%; sgdisk -p p.img | grep -q "Number"'
check "lvm-tools" 'lvm version'
check "mdadm-tools" 'mdadm --version'
check "cryptsetup-tools" 'cryptsetup --version'
if [ "$(id -u)" = 0 ] && [ -e /dev/loop-control ] && LOOP=$(losetup -f --show i_ext4 2>/dev/null); then
  mkdir m; check "mount-ext4-loop" "mount $LOOP m && touch m/x && umount m"; losetup -d "$LOOP"
else out SKIP mount-ext4-loop "no loop device here"; K=$((K+1)); fi
if [ -d /run/systemd/system ]; then check "journalctl" 'journalctl -n1 --no-pager'; check "cron-enabled" 'systemctl is-enabled cron'; else out SKIP systemd-live "systemd not running here"; K=$((K+1)); fi
echo "RESULT PASS=$P FAIL=$F SKIP=$K"; [ -z "$REPORT" ] || echo "RESULT,PASS=$P FAIL=$F SKIP=$K," >> "$REPORT"
exit "$F"
