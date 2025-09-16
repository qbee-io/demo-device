#!/usr/bin/env bash

if [[ -z $BOOTSTRAP_KEY ]]; then
  echo "ERROR: No bootstrap key has been provided"
  exit 1
fi

BASEDIR=$(cd $(dirname $0) && pwd)
QBEE_TPM2_DIR="/var/lib/qbee-tpm2"

MAC=$(echo $HOSTNAME | md5sum | sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/02:\1:\2:\3:\4:\5/')

generate_user_password() {
  < /dev/urandom tr -dc A-Z-a-z-0-9 | head -c 8
  echo
}

setup_emulated_tpm() {
  mkdir -p "$QBEE_TPM2_DIR"
  swtpm socket --tpmstate dir="$QBEE_TPM2_DIR" --ctrl type=unixio,path="$QBEE_TPM2_DIR/swtpm-sock" --tpm2 --log level=20 -d
}

setup_emulated_tpm 2>&1 > /dev/null

export QBEE_DEMO_USER="qbee"
export QBEE_DEMO_PASSWORD="qbee"
export QBEE_DEMO_BOOTSTRAP_KEY="${BOOTSTRAP_KEY}"
export QBEE_DEMO_PASSWORD_HASH=$(echo $QBEE_DEMO_PASSWORD | mkpasswd --method=SHA-512 --stdin)
export QBEE_DEMO_DEVICE_HUB_HOST=${QBEE_DEMO_DEVICE_HUB_HOST:-device.app.qbee.io}

envsubst > $BASEDIR/cloud-init/user-data < $BASEDIR/cloud-init/user-data.template

cloud-localds $BASEDIR/cloud-init/seed.img $BASEDIR/cloud-init/user-data $BASEDIR/cloud-init/meta-data

IMG="$BASEDIR/vmimage.qcow2"
qemu-img resize $IMG 8G

ARCH=$(uname -m)

TPM_OPTIONS=""

if [[ -S $QBEE_TPM2_DIR/swtpm-sock ]]; then
  TPM_OPTIONS=" -chardev socket,id=chrtpm,path=$QBEE_TPM2_DIR/swtpm-sock -tpmdev emulator,id=tpm0,chardev=chrtpm -device tpm-tis,tpmdev=tpm0"
fi


if [[ "$ARCH" == "aarch64" ]]; then

  truncate -s 64M $BASEDIR/varstore.img

  truncate -s 64M $BASEDIR/efi.img
  dd if=/usr/share/qemu/edk2-aarch64-code.fd of=$BASEDIR/efi.img conv=notrunc

  qemu-system-aarch64 \
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
    $TPM_OPTIONS

elif [[ "$ARCH" == "x86_64" ]]; then
  # Default options
  QEMU_OPTIONS=" -machine type=pc -smp 4 -cpu host"

  if [[ -c /dev/kvm ]]; then
    QEMU_OPTIONS=" -machine type=pc,accel=kvm -smp 4 -cpu host"
  fi
  
  qemu-system-x86_64 \
  -m 1024 \
  -nographic \
  -device virtio-net-pci,netdev=net0,mac=$MAC \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -drive if=virtio,format=qcow2,file=$IMG \
  -drive if=virtio,format=raw,file=$BASEDIR/cloud-init/seed.img \
  $QEMU_OPTIONS $TPM_OPTIONS
fi



