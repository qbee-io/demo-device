#!/usr/bin/env bash

set -e
BASEDIR=$(cd $(dirname $0) && pwd)

install_image() {
  BASEIMAGE="debian-12-genericcloud-amd64.qcow2"

  if [[ ! -f "$BASEDIR/$BASEIMAGE" ]]; then
    wget "https://cloud.debian.org/images/cloud/bookworm/latest/$BASEIMAGE"
  fi

  cp $BASEIMAGE $BASEDIR/build/vmimage.qcow2

  QBEE_AGENT_VERSION=${QBEE_AGENT_VERSION:-latest}

  bash $BASEDIR/build/build.sh $QBEE_AGENT_VERSION

  mv $BASEDIR/build/vmimage.qcow2 $BASEDIR/files
}

install_image

docker build -t qbeeio/qbee-demo:$QBEE_AGENT_VERSION -f $BASEDIR/Dockerfile $BASEDIR/files
