FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

dirs755 += "/data"
dirs755:append:qemux86-64 = " /grubenv"

hostname = "qbeedemo"

do_install:append() {
    cat > ${D}${sysconfdir}/issue <<'EOF'
${DISTRO_NAME} (${DISTRO_CODENAME}) \n \l

***************************
*
* Qbee demo system:
*
* Username: qbee
* Password: qbee
*
***************************

EOF
}
