#!/usr/bin/env bash

if [[ -z $BOOTSTRAP_KEY ]]; then
  echo "ERROR: No bootstrap key has been provided"
  exit 1
fi

BASEDIR=$(cd $(dirname $0) && pwd)

IMAGE="$BASEDIR/images/vmimage.wic"
FLASH_IMG="$BASEDIR/images/ovmf.qcow2"
UBOOT_IMG="$BASEDIR/images/u-boot.bin"
UBOOT_ENV_IMG="$BASEDIR/images/bootenv.img"

MAC=$(echo "$HOSTNAME" | md5sum | sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/02:\1:\2:\3:\4:\5/')

# Defaults
QBEE_DEMO_DEVICE_HUB_HOST=${QBEE_DEMO_DEVICE_HUB_HOST:-device.app.qbee.io}
QBEE_DEMO_DEVICE_NAME_TYPE=${QBEE_DEMO_DEVICE_NAME_TYPE:-hostname}

# Generate the bootstrap-env file for this device
cat > /run/.bootstrap-env << EOF
BOOTSTRAP_KEY=${BOOTSTRAP_KEY}
DEVICE_NAME_TYPE=${QBEE_DEMO_DEVICE_NAME_TYPE}
DEVICE_HUB_HOST=${QBEE_DEMO_DEVICE_HUB_HOST}
CLEAN_SEEDING_INFO=true
EOF

start_x86_64() {
  qemu-system-x86_64 \
    -device virtio-net-pci,netdev=net0,mac="$MAC" \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -object rng-random,filename=/dev/urandom,id=rng0 \
    -device virtio-rng-pci,rng=rng0 \
    -drive if=none,id=hd,file="$IMAGE",format=raw \
    -device virtio-scsi-pci,id=scsi \
    -device scsi-hd,drive=hd \
    -usb -device usb-tablet -usb -device usb-tablet -usb -device usb-kbd \
    -drive if=pflash,format=qcow2,file="$FLASH_IMG" \
    -cpu max -machine q35,i8042=off -smp 4 -m 256 -serial mon:stdio -serial null -nographic \
    "${QEMU_OPTIONS[@]}" 2> /tmp/qemu.log
}

start_aarch64() {
  qemu-system-aarch64 \
  	-device virtio-net-pci,netdev=net0,mac="$MAC" \
  	-netdev user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22 \
    -object filter-dump,id=dump0,netdev=net0,file=/tmp/net.pcap \
  	-object rng-random,filename=/dev/urandom,id=rng0 \
  	-device virtio-rng-pci,rng=rng0 \
  	-drive id=disk0,file="$IMAGE",if=none,format=raw \
  	-device virtio-blk-device,drive=disk0 \
  	-drive if=pflash,format=raw,index=1,file="$UBOOT_ENV_IMG" \
  	-machine virt -cpu max \
  	-smp 4 -m 256 -serial mon:stdio -serial null -nographic \
  	-bios "$UBOOT_IMG" \
  	"${QEMU_OPTIONS[@]}" 2> /tmp/qemu.log
}

case "$(uname -m)" in
  x86_64) HOST_ARCH=amd64 ;;
  aarch64) HOST_ARCH=arm64 ;;
  *) HOST_ARCH=$(uname -m) ;;
esac
GUEST_ARCH=${GUEST_ARCH:-$HOST_ARCH}

QEMU_OPTIONS=()

# KVM can only accelerate a guest of the same architecture as the host
if [[ -c /dev/kvm && "$GUEST_ARCH" == "$HOST_ARCH" ]]; then
  QEMU_OPTIONS+=(-enable-kvm)
fi

## Disabled TPM2 setup
#QBEE_TPM2_DIR="/var/lib/qbee-tpm2"
#setup_emulated_tpm() {
#  mkdir -p "$QBEE_TPM2_DIR"
#  swtpm socket --tpmstate dir="$QBEE_TPM2_DIR" --ctrl type=unixio,path="$QBEE_TPM2_DIR/swtpm-sock" --tpm2 --log level=20 --seccomp action=none -d
#}
#
#setup_emulated_tpm
#
#if [[ -S $QBEE_TPM2_DIR/swtpm-sock ]]; then
#  QEMU_OPTIONS+=(
#    "-chardev" "socket,id=chrtpm,path=$QBEE_TPM2_DIR/swtpm-sock"
#    "-tpmdev" "emulator,id=tpm0,chardev=chrtpm"
#    "-device" "tpm-tis,tpmdev=tpm0"
#  )
#  echo "TPM_DEVICE=/dev/tpm0" >> /run/.bootstrap-env
#fi

if [[ "$GUEST_ARCH" == "amd64" ]]; then
  # First root partition is on partition 4 for amd64 guests
  wic cp /run/.bootstrap-env "$IMAGE":4/etc/qbee/yocto/
  clear
  start_x86_64
  exit $?
elif [[ "$GUEST_ARCH" == "arm64" ]]; then
  # First root partition is on partition 2 for arm64 guests
  wic cp /run/.bootstrap-env "$IMAGE":2/etc/qbee/yocto/
  # u-boot doesn't clear the screen like grub does, so clear it ourselves
  clear
  start_aarch64
  exit $?
else
  echo "Unsupported guest architecture: $GUEST_ARCH" >&2
  exit 1
fi


