# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.14

FROM python:${PYTHON_VERSION}-alpine AS builder

ARG WIC_REPO=https://git.yoctoproject.org/wic
ARG WIC_REF=master

RUN apk add --no-cache git

RUN git clone --depth 1 --branch "${WIC_REF}" "${WIC_REPO}" /src/wic

WORKDIR /src/wic
# PEP 517 build using the hatchling backend declared in pyproject.toml
RUN pip install --no-cache-dir build \
    && python -m build --wheel --outdir /dist

FROM python:${PYTHON_VERSION}-alpine

# Host tools wic shells out to for partitioning and filesystem creation
RUN apk add --no-cache \
        dosfstools \
        e2fsprogs \
        e2fsprogs-extra \
        mtools \
        parted \
        sfdisk \
        swtpm \
        bash

ARG TARGETARCH
ARG GUEST_ARCH=${TARGETARCH}
ENV GUEST_ARCH=${GUEST_ARCH}
RUN case "${GUEST_ARCH}" in \
        amd64) qemu=qemu-system-x86_64 ;; \
        arm64) qemu=qemu-system-aarch64 ;; \
        *) echo "Unsupported GUEST_ARCH: ${GUEST_ARCH}" >&2; exit 1 ;; \
    esac \
    && apk add --no-cache "${qemu}"

RUN --mount=type=bind,from=builder,source=/dist,target=/dist \
    pip install --no-cache-dir --no-compile /dist/*.whl

COPY /images /qbee-demo/images
COPY /start.sh /qbee-demo/start.sh

WORKDIR /qbee-demo
CMD ["/bin/bash", "/qbee-demo/start.sh" ]
