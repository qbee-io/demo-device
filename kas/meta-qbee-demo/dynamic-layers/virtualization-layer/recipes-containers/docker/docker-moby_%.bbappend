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

# The image doesn't install all kernel modules (see kas-qbee-docker.yml), so recommend the
# netfilter modules dockerd's iptables rules use on top of the ones docker-moby and iptables
# already recommend: port publishing (DNAT), direct-access filtering (raw table) and IPv6.
# Recommends are soft, so modules that are built into the kernel are simply skipped.
RRECOMMENDS:${PN} += " \
    kernel-module-xt-nat \
    kernel-module-xt-tcpudp \
    kernel-module-xt-comment \
    kernel-module-iptable-raw \
    kernel-module-ip6table-raw \
    kernel-module-ip6table-nat \
    kernel-module-nf-defrag-ipv6 \
    kernel-module-ipt-reject \
    kernel-module-ip6t-reject \
    kernel-module-br-netfilter \
"
CONFFILES:${PN} += "${sysconfdir}/docker/daemon.json"
