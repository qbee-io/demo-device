#!/usr/bin/env bash

set -e
BASEDIR="$(cd "$(dirname "$0")" && pwd)"

#declare -a ARCHS=("amd64" "arm64")
#declare -a ARCHS=("amd64")
declare -a ARCHS=("arm64")

QBEE_AGENT_VERSION=${QBEE_AGENT_VERSION:-latest}

install_image() {
  BASEIMAGE="debian-12-genericcloud-$1.qcow2"

  if [[ ! -f "$BASEDIR/$BASEIMAGE" ]]; then
    wget "https://cloud.debian.org/images/cloud/bookworm/latest/$BASEIMAGE"
  fi

  cp "$BASEDIR/$BASEIMAGE" "$BASEDIR/build/vmimage.$1.qcow2"
  bash "$BASEDIR/build/build.sh" "$QBEE_AGENT_VERSION" "$1"

  mv "$BASEDIR/build/vmimage.$1.qcow2" "$BASEDIR/files"
}

#install_image

for ARCH in "${ARCHS[@]}"; do
  echo "Building for architecture: $ARCH"
#  install_image "$ARCH"
  docker buildx build --platform "linux/$ARCH" -t "qbeeio/qbee-demo:$QBEE_AGENT_VERSION" -f "$BASEDIR/Dockerfile.$ARCH" "$BASEDIR/files" --load
done

#docker build -t qbeeio/qbee-demo:$QBEE_AGENT_VERSION -f $BASEDIR/Dockerfile $BASEDIR/files
