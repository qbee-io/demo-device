FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Reboot immediately (shutdown -r now) instead of after a 1 minute grace period
SRC_URI += "file://0001-reboot-without-grace-period.patch;patchdir=src/${GO_IMPORT}"
