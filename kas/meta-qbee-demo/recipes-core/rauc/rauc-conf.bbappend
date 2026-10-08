FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

RDEPENDS:${PN}:append:qemux86-64 = " grub-editenv e2fsprogs-mke2fs"
