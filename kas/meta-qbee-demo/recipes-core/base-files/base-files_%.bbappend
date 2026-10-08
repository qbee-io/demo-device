FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"

dirs755 += "/data"
dirs755:append:qemux86-64 = " /grubenv"
