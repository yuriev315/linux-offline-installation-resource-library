#!/bin/bash
# Host-side test harness. Unpacks the official WSL rootfs and runs the offline install with NO network
# (empty network namespace, private mounts), with the library bind-mounted read-only. Host files are not changed.
# usage: run_isolated_wsl_rootfs_test.sh WORKDIR RESULTS_DIR
set -u
LIB=$(cd "$(dirname "$0")/../.." && pwd); W=${1:?}; OUT=${2:?}; mkdir -p "$W" "$OUT"
ROOTFS="$LIB/02_WSL2/ubuntu_rootfs/ubuntu-24.04.5-wsl-amd64.wsl"
[ -x "$W/bin/bash" ] || tar -xf "$ROOTFS" -C "$W" --numeric-owner --exclude='./dev/*'
export INNER="${INNER:-inside_isolated_test.sh}"
exec unshare -n -m -p -f --propagation private bash -c '
 W=$1; LIB=$2; OUT=$3
 mount -t proc proc "$W/proc"; mount -t tmpfs tmpfs "$W/dev"
 for d in null:1:3 zero:1:5 urandom:1:9 random:1:8 full:1:7 tty:5:0; do IFS=: read n a b <<<"$d"; mknod -m666 "$W/dev/$n" c $a $b; done
 ln -s pts/ptmx "$W/dev/ptmx";  ln -s /proc/self/fd "$W/dev/fd"; ln -s /proc/self/fd/0 "$W/dev/stdin"; ln -s /proc/self/fd/1 "$W/dev/stdout"; ln -s /proc/self/fd/2 "$W/dev/stderr"
 mkdir -p "$W/dev/pts" "$W/dev/shm" "$W/mnt/lib" "$W/mnt/out" "$W/run/lock"; mount -t devpts -o newinstance,ptmxmode=0666 devpts "$W/dev/pts"; mount -t tmpfs tmpfs "$W/dev/shm"
 mount --bind "$LIB" "$W/mnt/lib"; mount -o remount,ro,bind "$W/mnt/lib"
 mount --bind "$OUT" "$W/mnt/out"
 ip link set lo up 2>/dev/null
 ip -o link > "$OUT/network_namespace.txt"; ip route >> "$OUT/network_namespace.txt" 2>&1
 exec chroot "$W" env -i PATH=/usr/sbin:/usr/bin:/sbin:/bin HOME=/root LANG=C.UTF-8 TERM=dumb bash "/mnt/lib/13_TESTS/apt_dependency_tests/$INNER"
' -- "$W" "$LIB" "$OUT"
