FROM alpine:latest AS build

WORKDIR "/image-build"

ENV IMAGE_RELEASE="23.05.3"
ENV IMAGE_FILE="openwrt-${IMAGE_RELEASE}-x86-64-generic-ext4-combined.img.gz"
ENV IMAGE_URL="https://downloads.openwrt.org/releases/${IMAGE_RELEASE}/targets/x86/64/openwrt-${IMAGE_RELEASE}-x86-64-generic-ext4-combined.img.gz"
ENV IMAGE_SHA256="7643950cbf6bf5d785525f300efc4e2ceaad613b5d0725886e7f5fcc5a9d18f9"

RUN apk add git curl qemu-img
RUN git clone --depth=1 --branch=kirkstone https://git.yoctoproject.org/poky /src/poky

RUN curl -L "${IMAGE_URL}" -o "${IMAGE_FILE}" && \
    sh -x -c '[ "$(sha256sum "${IMAGE_FILE}")" = "${IMAGE_SHA256}  ${IMAGE_FILE}" ]'
RUN gunzip --stdout "${IMAGE_FILE}" > vm-image.raw

FROM alpine:latest

WORKDIR "/qbee-demo"

RUN apk add qemu-system-x86_64 bash parted python3 e2fsprogs-extra swtpm qemu-img
COPY --from=build /src/poky/scripts /poky/scripts
COPY --from=build /image-build/vm-image.raw .
ADD https://downloads.openwrt.org/snapshots//packages/x86_64/packages/qbee-agent_2024.23-r1_x86_64.ipk qbee-agent.ipk
RUN rm -f /usr/share/qemu/edk2-*
COPY /run .

CMD ["/bin/sh","/qbee-demo/start.sh"]
