# demo-device

Demo device images for trying out [qbee.io](https://qbee.io) device management, built for several
base systems. Each demo image bootstraps `qbee-agent` on first boot using a `BOOTSTRAP_KEY` from
your qbee.io account.

## Debian

```bash
docker run -it -e BOOTSTRAP_KEY=<bootstrap-key> qbeeio/qbee-demo:latest
```

QEMU inside the container doesn't have access to KVM by default, which makes it noticeably slower.
If `/dev/kvm` is available on your host (check with `kvm-ok`), pass it through for acceleration:

```bash
docker run --device /dev/kvm -it -e BOOTSTRAP_KEY=<bootstrap-key> qbeeio/qbee-demo:latest
```

## Yocto with RAUC OTA

```bash
docker run -it -e BOOTSTRAP_KEY=<bootstrap-key> qbeeio/qbee-demo:latest-yocto
```

QEMU inside the container doesn't have access to KVM by default, which makes it noticeably slower.
If `/dev/kvm` is available on your host (check with `kvm-ok`), pass it through for acceleration:

```bash
docker run --device /dev/kvm -it -e BOOTSTRAP_KEY=<bootstrap-key> qbeeio/qbee-demo:latest-yocto
```

Building the image from source requires a RAUC signing key, which isn't included in this
repository, so building locally isn't currently supported — use the published image or a released
bundle instead.

### Deploying a RAUC update via qbee-cli

Released builds publish a signed `*.raucb` bundle as a GitHub release asset on the
[demo-device releases page](https://github.com/qbee-io/demo-device/releases). You can grab one of
these bundles and roll it out to a device or group using [qbee-cli](https://github.com/qbee-io/qbee-cli)
instead of building Yocto yourself. The same two steps (file upload, configuration) can also be
done through the qbee web UI instead of the CLI: upload the bundle under **File manager**, then
set it on a device/group's **RAUC** configuration page.

As an example, the `qbee-demo-bundle-nano-qemux86-64.raucb` bundle below installs the `nano` text
editor into the image via an A/B update — after it's applied and the device reboots into the
updated partition, `nano` becomes available on the device.

1. **Verify `nano` isn't installed yet**

   Open an interactive terminal session on the device:

   ```bash
   qbee-cli term <device-id>
   ```

   In that session, run:

   ```bash
   nano --version
   ```

   This should report that `nano` is not found, confirming `nano` is absent before the update.

2. **Download the bundle from GitHub**

   ```bash
   wget https://github.com/qbee-io/demo-device/releases/latest/download/qbee-demo-bundle-nano-qemux86-64.raucb
   # or, with curl:
   curl -LO https://github.com/qbee-io/demo-device/releases/latest/download/qbee-demo-bundle-nano-qemux86-64.raucb
   ```

3. **Log in and upload the bundle to the qbee.io filemanager**

   ```bash
   qbee-cli login

   qbee-cli files upload \
     --source qbee-demo-bundle-nano-qemux86-64.raucb \
     --destination /rauc-bundles \
     --overwrite
   ```

4. **Enable the update by saving and committing a RAUC configuration**

   Create a config file for the `rauc` bundle, pointing at the uploaded file's filemanager path:

   ```json
   {
     "enabled": true,
     "rauc_bundle": "/rauc-bundles/qbee-demo-bundle-nano-qemux86-64.raucb"
   }
   ```

   Then apply it to the device and commit it so it takes effect:

   ```bash
   qbee-cli config save --config rauc-config.json --bundle rauc --node <device-id>
   qbee-cli config commit --commit-message "Deploy qbee-demo-bundle-nano-qemux86-64.raucb"
   ```

   The device installs the bundle to its inactive partition and reboots into it on the next agent
   check-in. To trigger this immediately instead of waiting for the next scheduled agent run, 
   run the agent on the device now:

   ```bash
   qbee-cli run --device-id <device-id>
   ```

5. **Verify `nano` is now installed**

   Once the device has rebooted into the updated partition, open a terminal session again:

   ```bash
   qbee-cli term <device-id>
   ```

   In that session, run:

   ```bash
   nano --version
   ```

   This should now print the installed `nano` version instead of an error.