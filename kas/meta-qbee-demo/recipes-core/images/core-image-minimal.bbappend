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

# os-release is built before qbee-agent's version is known, so stamp the real
# agent version into VERSION/VERSION_ID here, once qbee-agent's pkgdata exists.
ROOTFS_POSTPROCESS_COMMAND += "qbee_demo_os_release_version;"
qbee_demo_os_release_version() {
    local qbee_agent_version os_release
    qbee_agent_version="$(oe-pkgdata-util read-value PKGV qbee-agent)"
    os_release="${IMAGE_ROOTFS}${nonarch_libdir}/os-release"
    sed -i \
        -e "s/^VERSION_ID=.*/VERSION_ID=${qbee_agent_version}/" \
        -e "s/^VERSION=.*/VERSION=\"${qbee_agent_version} (${DISTRO_CODENAME})\"/" \
        "${os_release}"
}
