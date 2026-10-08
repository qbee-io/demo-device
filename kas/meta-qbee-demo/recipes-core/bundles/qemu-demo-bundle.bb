inherit bundle

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

COMPATIBLE_MACHINE = "^qemuarm64$|^qemux86-64$"

RAUC_BUNDLE_FORMAT = "verity"

RAUC_IMAGE_FSTYPE = "tar.bz2"

RAUC_SLOT_rootfs = "core-image-minimal"

RAUC_BUNDLE_COMPATIBLE:qemuarm64 = "qemuarm demo"
RAUC_BUNDLE_SLOTS:qemuarm64 = "rootfs"

RAUC_BUNDLE_COMPATIBLE:qemux86-64 = "qemux86-64 demo platform"
RAUC_BUNDLE_SLOTS:qemux86-64 = "efi rootfs"
# uncomment for enabling adaptive update method 'block-hash-index'
#RAUC_SLOT_rootfs[fstype] = "ext4"
#RAUC_SLOT_rootfs[adaptive] = "block-hash-index"

# flags can't be combined with a MACHINE override on the same line, but these
# are only consulted for qemux86-64 since RAUC_SLOT_efi is otherwise unset
RAUC_SLOT_efi:qemux86-64 = "boot-image"
RAUC_SLOT_efi[file] = "efi-boot.vfat"
RAUC_SLOT_efi[type] = "boot"
