FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Keep all Docker state on the data partition
SRC_URI += " \
    file://daemon.json \
    file://10-data-partition.conf \
"

do_install:append() {
    install -m 0644 ${UNPACKDIR}/daemon.json ${D}${sysconfdir}/docker/daemon.json

    if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
        install -d ${D}${systemd_system_unitdir}/docker.service.d
        install -m 0644 ${UNPACKDIR}/10-data-partition.conf ${D}${systemd_system_unitdir}/docker.service.d/
    fi
}

FILES:${PN} += "${systemd_system_unitdir}/docker.service.d"
CONFFILES:${PN} += "${sysconfdir}/docker/daemon.json"
