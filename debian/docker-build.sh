#!/usr/bin/env bash

set -e
BASEDIR="$(cd "$(dirname "$0")" && pwd)"

BUILD_ARCH=${1:-"amd64"}

QBEE_AGENT_VERSION=${QBEE_AGENT_VERSION:-latest}

install_image() {

  local ARCH=$1

  BASEIMAGE="debian-13-genericcloud-$ARCH.qcow2"

  if [[ ! -f "$BASEDIR/$BASEIMAGE" ]]; then
    wget --quiet \
      --output-document="$BASEDIR/$BASEIMAGE" \
      "https://cloud.debian.org/images/cloud/trixie/latest/$BASEIMAGE"
  fi

  cp "$BASEDIR/$BASEIMAGE" "$BASEDIR/build/vmimage.$ARCH.qcow2"
  bash "$BASEDIR/build/build.sh" "$ARCH" 

  mv "$BASEDIR/build/vmimage.$ARCH.qcow2" "$BASEDIR/files"
}

echo "Building for architecture: $BUILD_ARCH"
install_image "$BUILD_ARCH"
