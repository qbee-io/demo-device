include ${BPN}-${MACHINE}.inc

inherit extrausers

IMAGE_INSTALL:append = " sudo"

# SHA-512 hash of "qbee"
QBEE_DEMO_PASSWD = "\$6\$qbeedemo\$VlzVqicoai8XTsYVUCBciMdzmlLt22oUfKGfUBb47jUb1UFVPVXqSwTE/tNaCCB7tVOnUn3FMI/aafG2wqM1/0"
EXTRA_USERS_PARAMS = "useradd -m -s /bin/sh -p '${QBEE_DEMO_PASSWD}' qbee;"

ROOTFS_POSTPROCESS_COMMAND += "qbee_demo_sudoers;"
qbee_demo_sudoers() {
    install -d -m 0750 ${IMAGE_ROOTFS}${sysconfdir}/sudoers.d
    echo 'qbee ALL=(ALL) NOPASSWD:ALL' > ${IMAGE_ROOTFS}${sysconfdir}/sudoers.d/qbee
    chmod 0440 ${IMAGE_ROOTFS}${sysconfdir}/sudoers.d/qbee
}
