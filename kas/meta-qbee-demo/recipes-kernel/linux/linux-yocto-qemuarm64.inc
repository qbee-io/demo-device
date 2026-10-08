# Kernel configuration required to access the u-boot environment in flash
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://mtd_flash.cfg"

KERNEL_EXTRA_ARGS += "LOADADDR=${UBOOT_ENTRYPOINT}"
