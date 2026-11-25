FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# dockerd uses the system containerd, which (with Docker's default containerd image
# store) holds the image content and snapshots, so keep its state on the data partition too
SRC_URI += " \
    file://config.toml \
    file://10-data-partition.conf \
"

do_install:append() {
    # ctr is containerd's debug CLI; Docker doesn't use it, so save the space
    rm -f ${D}${bindir}/containerd-ctr ${D}${bindir}/ctr ${D}${bindir}/docker-containerd-ctr

    install -d ${D}${sysconfdir}/containerd
    install -m 0644 ${UNPACKDIR}/config.toml ${D}${sysconfdir}/containerd/config.toml

    if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
        install -d ${D}${systemd_system_unitdir}/containerd.service.d
        install -m 0644 ${UNPACKDIR}/10-data-partition.conf ${D}${systemd_system_unitdir}/containerd.service.d/
    fi
}

FILES:${PN} += "${systemd_system_unitdir}/containerd.service.d"
CONFFILES:${PN} += "${sysconfdir}/containerd/config.toml"
