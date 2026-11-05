#!/bin/bash
# Host harness, run in a chroot that has qemu. Windows in KVM with NO network device.
# usage: run_windows_vm.sh WORK WINISO UNATTEND_ISO PAYLOAD_IMG
W=$1; ISO=$2; UN=$3; PL=$4; MEM=${MEM:-8192}; MINAVAIL_KB=$((10*1024*1024)); cd "$W" || exit 1
[ -f disk.qcow2 ] || qemu-img create -q -f qcow2 disk.qcow2 120G
cp --update=none /usr/share/OVMF/OVMF_VARS_4M.fd vars.fd
nice -n 15 timeout "${LIMIT:-28800}" qemu-system-x86_64 -enable-kvm -machine q35 -cpu host,+svm -smp 4 -m "$MEM" -nic none -display none -vga std \
 -monitor unix:mon.sock,server,nowait -global ICH9-LPC.disable_s3=1 \
 -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd -drive if=pflash,format=raw,file=vars.fd \
 -device ahci,id=a -drive id=d0,if=none,file=disk.qcow2,format=qcow2,cache=writeback -device ide-hd,drive=d0,bus=a.0,bootindex=0 \
 -drive id=d1,if=none,file="$PL",format=raw,cache=writeback -device ide-hd,drive=d1,bus=a.1 \
 -drive id=c0,if=none,file="$ISO",format=raw,media=cdrom,readonly=on -device ide-cd,drive=c0,bus=a.2,bootindex=1 \
 -drive id=c1,if=none,file="$UN",format=raw,media=cdrom,readonly=on -device ide-cd,drive=c1,bus=a.3 &
P=$!
# "Press any key to boot from CD": only until the disk has an operating system.
( if [ ! -f booted_once ]; then for i in $(seq 1 45); do sleep 2; printf 'sendkey ret\n' | socat - UNIX-CONNECT:mon.sock >/dev/null 2>&1; done; touch booted_once; fi ) &
( n=0; while kill -0 $P 2>/dev/null; do sleep 60; n=$((n+1)); printf 'screendump shot.ppm.tmp\n' | socat - UNIX-CONNECT:mon.sock >/dev/null 2>&1; [ -s shot.ppm.tmp ] && mv -f shot.ppm.tmp shot.ppm; a=$(awk '/MemAvailable/{print $2}' /proc/meminfo); [ "$a" -lt $MINAVAIL_KB ] && { echo "WATCHDOG MemAvailable=$a" >> watchdog.log; kill $P; }; done ) &
wait $P; echo "windows vm exit=$?" | tee -a phases.log
