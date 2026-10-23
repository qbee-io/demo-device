FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Reboot immediately (shutdown -r now) instead of after a 1 minute grace period
# Surrounding spaces are required: meta-qbee's qbee-agent.inc uses SRC_URI:append without a leading space
SRC_URI:append = " file://0001-reboot-without-grace-period.patch;patchdir=src/${GO_IMPORT} "
