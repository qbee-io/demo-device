#!/usr/bin/env bash


BASEDIR=$(cd $(dirname $0) && pwd)

BASEIMAGE="Fedora-Cloud-Base-Generic.x86_64-40-1.14.qcow2"
BASEURL="https://download.fedoraproject.org/pub/fedora/linux/releases/40/Cloud/x86_64/images"

if [[ ! -f "$BASEDIR/$BASEIMAGE" ]]; then
  wget -q "$BASEURL/$BASEIMAGE"
fi

cp $BASEIMAGE $BASEDIR/build/vmimage.qcow2

bash $BASEDIR/build/build.sh

mv $BASEDIR/build/vmimage.qcow2 $BASEDIR/files

docker build -t qbeeio/qbee-demo:latest-fedora -f $BASEDIR/Dockerfile $BASEDIR/files
