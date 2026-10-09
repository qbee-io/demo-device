# ---
# qemuarm64 specific integration of u-boot for usage with RAUC
#
# This demo uses a bootscript-based approach. As the bootscript is provided
# alongside (and not as a part) of the u-boot binary, it needs to be deployed
# in a dedicated FAT partition.
#
# The bootloader environment is persisted in the built-in flash (pflash1)
# emulated by Qemu, see
#   https://github.com/u-boot/u-boot/blob/master/configs/qemu_arm_defconfig
# The kernel must be configured accordingly (MTD subsystem and physmap driver).

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://0001-qemu-arm-prefer-virtio-as-boot-source.patch \
    file://fw_env.config \
    file://boot.cmd.in \
"

# The boot script loads the devicetree from the rootfs
RDEPENDS:${PN} += "devicetree-qemuarm"
DEVICETREE_NAME = "${MACHINE}.dtb"

KERNEL_BOOTCMD = "booti"

# Compile the boot.scr and make it available in the DEPLOYDIR
UBOOT_ENV = "boot"
UBOOT_ENV_SUFFIX = "scr"

UBOOT_ENTRYPOINT = "0x00008000"
UBOOT_LOADADDRESS = "0x00008000"

# Provide the empty flash image to persist the bootloader environment
UBOOT_BOOTENV_FILE = "bootenv.img"

do_configure:prepend () {
    sed -e 's/@@DEVICETREE_NAME@@/${DEVICETREE_NAME}/' \
        -e 's/@@KERNEL_IMAGETYPE@@/${KERNEL_IMAGETYPE}/' \
        -e 's/@@KERNEL_BOOTCMD@@/${KERNEL_BOOTCMD}/' \
        "${UNPACKDIR}/boot.cmd.in" > "${UNPACKDIR}/boot.cmd"
}

do_deploy:append () {
    # The flash size is predefined by qemu
    qemu-img create -f raw ${UBOOT_BOOTENV_FILE} 64M
}

do_deploy[depends] += "qemu-system-native:do_populate_sysroot"
