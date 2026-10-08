IMAGE_INSTALL:append = " \
    u-boot-fw-utils \
    u-boot-default-env \
    kernel-image \
    devicetree-qemuarm \
    mtd-utils \
"

# Deploy the bootscript to the boot partition via the bootimg-partition plugin
IMAGE_BOOT_FILES = "boot.scr"

WKS_FILE = "qemuarm64.wks"

do_image_wic[depends] += "u-boot:do_deploy"
