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
  
QEMU_OPTIONS=""

if [[ -c /dev/kvm ]]; then
  QEMU_OPTIONS="$QEMU_OPTIONS -machine type=pc,accel=kvm -smp 4 -cpu host"
fi

if [[ -S $QBEE_TPM2_DIR/swtpm-sock ]]; then
  QEMU_OPTIONS="$QEMU_OPTIONS -chardev socket,id=chrtpm,path=$QBEE_TPM2_DIR/swtpm-sock -tpmdev emulator,id=tpm0,chardev=chrtpm -device tpm-tis,tpmdev=tpm0"
fi

qemu-system-x86_64 \
  -m 512 \
  -smp 4 \
  -nographic \
  -device virtio-net-pci,netdev=net0,mac=$MAC \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -drive if=virtio,format=qcow2,file=$IMG \
  -drive if=virtio,format=raw,file=$BASEDIR/cloud-init/seed.img \
  $QEMU_OPTIONS

