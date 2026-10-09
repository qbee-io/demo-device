IMAGE_INSTALL:append = " kernel-image kernel-modules"

WKS_FILE = "qemux86-64.wks"

do_image_wic[depends] += "boot-image:do_deploy"
