#!/bin/bash
# Usage: collect.sh <arch>   (env BUNDLE_ONLY=true|false)
set -eu
arch="$1"
deploy=/ci/demo-device/$arch/tmp/deploy/images/qemu$arch
out=artifacts/$arch
rm -rf "$out" && mkdir -p "$out"
case "$arch" in
  arm64)
    bundle="update-bundle-qemuarm64.raucb"
    images="core-image-minimal-qemuarm64.rootfs.wic bootenv.img u-boot.bin" ;;
  x86-64)
    bundle="qemu-demo-bundle-qemux86-64.raucb"
    images="core-image-minimal-qemux86-64.rootfs.wic ovmf.qcow2" ;;
esac
machine="qemu${bundle##*-qemu}"
# -L dereferences the deploy dir symlinks
if [ "${BUNDLE_ONLY:-false}" = "true" ]; then
  cp -L "$deploy/$bundle" "$out/qbee-demo-bundle-nano-$machine"
else
  cp -L "$deploy/$bundle" "$out/qbee-demo-bundle-$machine"
  for f in $images; do
    cp -L "$deploy/$f" "$out/"
  done
fi
ls -l "$out"
