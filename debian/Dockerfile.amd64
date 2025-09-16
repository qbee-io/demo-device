FROM alpine:latest
RUN apk add qemu-system-x86_64 cloud-utils-localds qemu-img envsubst swtpm
COPY . /qbee-demo

CMD ["/bin/sh", "/qbee-demo/start.sh" ]
