#!/bin/bash
# Host harness (run inside a chroot that has qemu). Install Ubuntu from the local ISO in KVM with NO network device,
# then boot it. A watchdog stops the VM if host memory runs low, because this machine also runs live services.
# usage: run_vm_test.sh server|desktop WORK LIBIMG RESIMG ISO
K=$1; W=$2; LIB=$3; RES=$4; ISO=$5; MEM=${MEM:-4096}; MINAVAIL_KB=$((12*1024*1024))
mkdir -p "$W"; cd "$W" || exit 1; D=$(dirname "$0")
bash "$D/make_seed.sh" "$K" seed
xorriso -as mkisofs -quiet -V CIDATA -J -r -o seed.iso seed/user-data seed/meta-data
[ -f disk.qcow2 ] || qemu-img create -q -f qcow2 disk.qcow2 ${DISK:-45G}
cp --update=none /usr/share/OVMF/OVMF_VARS_4M.fd vars.fd
xorriso -osirrox on -indev "$ISO" -extract /casper/vmlinuz vmlinuz -extract /casper/initrd initrd >/dev/null 2>&1
chmod u+w vmlinuz initrd 2>/dev/null
COMMON=(-enable-kvm -cpu host -smp 4 -m "$MEM" -nic none -no-reboot -display none -vga virtio -monitor unix:mon.sock,server,nowait
 -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd -drive if=pflash,format=raw,file=vars.fd
 -drive file=disk.qcow2,if=virtio,format=qcow2,cache=writeback,discard=unmap
 -drive file="$LIB",if=virtio,format=raw,readonly=on -drive file="$RES",if=virtio,format=raw)
watch_mem() { while kill -0 "$1" 2>/dev/null; do a=$(awk '/MemAvailable/{print $2}' /proc/meminfo); if [ "$a" -lt $MINAVAIL_KB ]; then echo "WATCHDOG host MemAvailable=$a; stopping VM" | tee -a watchdog.log; kill "$1"; fi; sleep 10; done; }
run() { # run LOGNAME TIMEOUT args...
  local n=$1 t=$2; shift 2; nice -n 15 timeout "$t" qemu-system-x86_64 "${COMMON[@]}" "$@" -serial "file:$n.serial.log" & local p=$!; watch_mem $p &
  ( while kill -0 $p 2>/dev/null; do sleep 15; printf 'screendump %s.ppm.tmp\n' "$n" | socat - UNIX-CONNECT:mon.sock >/dev/null 2>&1; [ -s "$n.ppm.tmp" ] && mv -f "$n.ppm.tmp" "$n.ppm"; done ) &
  wait $p; echo "$n exit=$?" | tee -a phases.log; }
if [ ! -f installed.ok ]; then
  APPEND="console=tty0 console=ttyS0,115200 autoinstall ds=nocloud"
  [ "$K" = desktop ] && APPEND="boot=casper $APPEND"
  run install 3600 -kernel vmlinuz -initrd initrd -append "$APPEND" -device virtio-scsi-pci,id=s0 -drive id=c0,if=none,file="$ISO",format=raw,media=cdrom,readonly=on -device scsi-cd,bus=s0.0,drive=c0 -drive id=c1,if=none,file=seed.iso,format=raw,media=cdrom,readonly=on -device scsi-cd,bus=s0.0,drive=c1
  touch installed.ok
fi
run firstboot 3000
[ "$K" != vmwareimg ] && run secondboot 900
echo finished | tee -a phases.log
