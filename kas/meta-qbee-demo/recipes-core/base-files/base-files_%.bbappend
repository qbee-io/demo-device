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
