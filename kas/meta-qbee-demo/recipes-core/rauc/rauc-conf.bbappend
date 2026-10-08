FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

RDEPENDS:${PN}:append = " e2fsprogs-mke2fs e2fsprogs-resize2fs"
RDEPENDS:${PN}:append:qemux86-64 = " grub-editenv"
