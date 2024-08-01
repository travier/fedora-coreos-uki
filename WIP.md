sudo unshare -m
mount -o remount,rw /sysroot
osversion="$(skopeo inspect docker://quay.io/travier/fedora-coreos-uki:latest | jq -r '.Labels."org.opencontainers.image.version"')"
ostree container unencapsulate \
  --repo /sysroot/ostree/repo \
  --write-ref "fedora/coreos/uki/${osversion}" \
  ostree-unverified-image:registry:quay.io/travier/fedora-coreos-uki:latest

ostree admin deploy --stage "fedora/coreos/uki/${osversion}"
exit

podman create --name uki quay.io/travier/fedora-coreos-uki:uki
podman cp uki:/uki uki
podman rm -f uki
podman rmi quay.io/travier/fedora-coreos-uki:uki
sudo mount -o remount,rw /boot
sudo mv uki /boot/ostree/uki

sync
sudo reboot



ukify build \
    --linux "vmlinuz" \
    --initrd "initramfs.img" \
    --cmdline "rw mitigations=auto,nosmt ignition.platform.id=qemu console=tty0 console=ttyS0,115200n8 ostree=/ostree/boot.1/fedora-coreos/$(cat vmlinuz initramfs.img | sha256sum)/0" \
    --os-release "os-release" \
    --uname "$kernver" \
    --signtool sbsign \
    --secureboot-private-key "db.key" \
    --secureboot-certificate "db.pem" \
    --output "uki" \
    --measure


---

https://github.com/ostreedev/ostree-rs-ext/pull/556

```
error: Staging deployment: Initializing deployment: Checking out deployment tree: Generated composefs image digest (573ad0fe84d7f61d2d632fee995c29acf3d72311eeed775b1f9a5af4dfb33001) doesn't match expected digest (172eb44f9640fdbc756a1570cc0ad8fb1a41f4b3f21dce4232b04112e7fcd8d2)
```
