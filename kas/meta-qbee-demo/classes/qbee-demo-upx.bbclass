# Compress selected executables in the image rootfs with UPX.
#
# Usage (e.g. from local.conf):
#   IMAGE_CLASSES += "qbee-demo-upx"
#   UPX_COMPRESS_FILES = "${bindir}/foo ${bindir}/bar"
#
# Compression is done on the assembled rootfs, i.e. after the packages have been
# stripped, so packages and sstate keep the regular binaries.
#
# Trade-off: a UPX-compressed binary is decompressed into anonymous memory on every
# exec. Startup is slower, and the pages can neither be shared between processes nor
# evicted and re-read from disk, so RAM usage goes up.
#
# upx-native is provided by meta-virtualization.

# Absolute paths in the rootfs; symlinks are rejected, list their targets instead
UPX_COMPRESS_FILES ?= ""
UPX_FLAGS ?= "--best --lzma"
UPX_PARALLEL ?= "${@oe.utils.cpu_count()}"

do_rootfs[depends] += "upx-native:do_populate_sysroot"

ROOTFS_POSTPROCESS_COMMAND += "upx_compress_rootfs"

upx_compress_rootfs() {
    files=""
    for f in ${UPX_COMPRESS_FILES}; do
        path="${IMAGE_ROOTFS}$f"
        if [ -L "$path" ]; then
            bbfatal "UPX: $f is a symlink, list its target in UPX_COMPRESS_FILES instead"
        elif [ ! -f "$path" ]; then
            bbfatal "UPX: $f listed in UPX_COMPRESS_FILES does not exist in the rootfs"
        fi
        files="$files $path"
    done
    if [ -z "$files" ]; then
        return 0
    fi

    printf '%s\n' $files | xargs -P ${UPX_PARALLEL} -n 1 upx ${UPX_FLAGS} -q
    upx -t -q $files
}
upx_compress_rootfs[vardepsexclude] += "UPX_PARALLEL"
