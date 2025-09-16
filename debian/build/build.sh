#!/usr/bin/env bash
set -e

declare -A ARCH_MAP=( ["amd64"]="x86_64" ["arm64"]="aarch64" )

BUILD_ARCH=${1:-"amd64"}
QEMU_ARCH=${ARCH_MAP[$BUILD_ARCH]:-"x86_64"}

BASEDIR="$(cd "$(dirname "$0")" && pwd)"

IMG="$BASEDIR/vmimage.$BUILD_ARCH.qcow2"
MAC=$(echo "$HOSTNAME" | md5sum | sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/02:\1:\2:\3:\4:\5/')

envsubst < "$BASEDIR/cloud-init/user-data.template" > "$BASEDIR/cloud-init/user-data"
cloud-localds "$BASEDIR/cloud-init/seed.img" "$BASEDIR/cloud-init/user-data"

QEMU_OPTIONS=""

if [[ "$BUILD_ARCH" == "arm64" ]]; then
  #QEMU_OPTIONS="$QEMU_OPTIONS -machine virt,gic-version=3 -cpu cortex-a57 -bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd"
  rm -f $BASEDIR/varstore.img
  truncate -s 64M $BASEDIR/varstore.img

  rm -f $BASEDIR/efi.img
  truncate -s 64M $BASEDIR/efi.img
  dd if=/usr/share/qemu-efi-aarch64/QEMU_EFI.fd of=$BASEDIR/efi.img conv=notrunc

  qemu-system-${QEMU_ARCH} \
    -m 2G \
    -cpu max \
    -M virt \
    -nographic \
    -drive if=pflash,format=raw,file=$BASEDIR/efi.img,readonly=on \
    -drive if=pflash,format=raw,file=$BASEDIR/varstore.img \
    -drive if=none,file=$IMG,id=hd0 \
    -device virtio-blk-device,drive=hd0 \
    -drive if=none,format=raw,file=$BASEDIR/cloud-init/seed.img,id=cloud \
    -device virtio-blk-device,drive=cloud \
    -device virtio-net-pci,netdev=net0,mac=$MAC \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    $QEMU_OPTIONS
elif [[ "$BUILD_ARCH" == "amd64" ]] && [[ -c /dev/kvm ]]; then
  QEMU_OPTIONS="$QEMU_OPTIONS -machine type=pc,accel=kvm -smp 4 -cpu host -nographic"
  #QEMU_OPTIONS="$QEMU_OPTIONS -machine type=pc -smp 4 -cpu max -nographic"
  qemu-system-${QEMU_ARCH} \
  -m 1G \
    -device virtio-net-pci,netdev=net0,mac=$MAC \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -drive if=virtio,format=qcow2,file=$IMG \
    -drive if=virtio,format=raw,file=$BASEDIR/cloud-init/seed.img \
    $QEMU_OPTIONS
fi