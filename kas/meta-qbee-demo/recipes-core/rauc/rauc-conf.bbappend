FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

RDEPENDS:${PN}:append = " e2fsprogs-mke2fs"
RDEPENDS:${PN}:append:qemux86-64 = " grub-editenv"
