#!/usr/bin/env bash

#if [[ -z $BOOTSTRAP_KEY ]]; then
#  echo "ERROR: No bootstrap key has been provided"
#  exit 1
#fi

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

setup_emulated_tpm

# Generate the bootstrap-env file for this device

printf '{"bootstrap_key":"%s","server":"%s"' ${BOOTSTRAP_KEY} ${QBEE_DEMO_DEVICE_HUB_HOST} >> qbee-agent.json

cat > /run/S99qbee-agent-bootstrap << EOF
#!/bin/sh /etc/rc.common

START=99
STOP=1

start() {
  opkg update
  opkg install kmod-tpm-tis

  mkdir -p /etc/qbee
  mv /etc/qbee-agent.json /etc/qbee/
  opkg install /etc/qbee-agent.ipk

}

EOF

chmod 755 /run/S99qbee-agent-bootstrap

QEMU_OPTIONS=""

if [[ -c /dev/kvm ]]; then
  QEMU_OPTIONS="$QEMU_OPTIONS -machine type=pc,accel=kvm -smp 4 -cpu host"
fi

if [[ -S $QBEE_TPM2_DIR/swtpm-sock ]]; then
  QEMU_OPTIONS="$QEMU_OPTIONS -chardev socket,id=chrtpm,path=$QBEE_TPM2_DIR/swtpm-sock -tpmdev emulator,id=tpm0,chardev=chrtpm -device tpm-tis,tpmdev=tpm0"
  printf ',"tpm_device":"/dev/tpm0"' >> qbee-agent.json
fi

printf '}' >> qbee-agent.json

BASE_IMG="$BASEDIR/vm-image.raw"

#/poky/scripts/wic rm $BASE_IMG:2/etc/rc.local
/poky/scripts/wic cp /run/S99qbee-agent-bootstrap $BASE_IMG:2/etc/rc.d/
/poky/scripts/wic cp qbee-agent.json $BASE_IMG:2/etc/
/poky/scripts/wic cp qbee-agent.ipk $BASE_IMG:2/etc/

IMAGE="$BASEDIR/vm-image.qcow2"

qemu-img convert -f raw -O qcow2 $BASE_IMG $IMAGE
qemu-img resize $IMAGE 8G

qemu-system-x86_64 \
  -m 512 \
  -smp 4 \
  -nographic \
  -nic "user,model=virtio,restrict=on,ipv6=off,net=192.168.1.0/24,host=192.168.1.2" \
  -nic "user,model=virtio,net=172.16.0.0/24,hostfwd=tcp::30022-:22,hostfwd=tcp::30080-:80,hostfwd=tcp::30443-:443" \
  -drive if=virtio,format=qcow2,file=$IMAGE \
  $QEMU_OPTIONS

