sudo mount -o remount,rw /boot
Update /boot/grub2/grub.cfg & /boot/grub2/uki.cfg

sudo tune2fs -O verity /dev/vda4
sudo ostree admin post-copy

echo -e "[composefs]\nenabled=signed" > /etc/ostree/prepare-root.conf

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

sudo ln -snf boot.0 /ostree/boot.1
sudo ln -snf boot.1 /ostree/boot.0
ls -alh /ostree/

sync
sudo reboot

host="uki2.devel"
commit="669ba406ac3da677b290b550cb254a25864c3fecd890c7658916f40d7b0f8804"
kernver="$(ssh $host ls /sysroot/ostree/deploy/fedora-coreos/deploy/${commit}.0/usr/lib/modules/)"
scp ${host}:/sysroot/ostree/deploy/fedora-coreos/deploy/${commit}.0/usr/lib/modules/${kernver}/vmlinuz .
scp ${host}:/sysroot/ostree/deploy/fedora-coreos/deploy/${commit}.0/usr/lib/modules/${kernver}/initramfs.img .
scp ${host}:/sysroot/ostree/deploy/fedora-coreos/deploy/${commit}.0/usr/lib/os-release .

ukify build \
    --linux "vmlinuz" \
    --initrd "initramfs.img" \
    --cmdline "rw mitigations=auto,nosmt ignition.platform.id=qemu console=tty0 console=ttyS0,115200n8 ostree=/ostree/boot.0/fedora-coreos/$(cat vmlinuz initramfs.img | sha256sum | awk '{print $1}')/0" \
    --os-release "os-release" \
    --uname "$kernver" \
    --signtool sbsign \
    --secureboot-private-key "db.key" \
    --secureboot-certificate "db.pem" \
    --output "uki" \
    --measure

scp uki ${host}:
ssh ${host}
sudo mount -o remount,rw /boot
sudo mv uki /boot/ostree/uki


mount /dev/vda4 /sysroot
mount /dev/vda3 /sysroot/boot
/sysroot/boot/ostree-prepare-root /sysroot


```
Aug 01 10:27:17 ostree-prepare-root[744]: ostree-prepare-root: composefs: failed to mount: fsverity not enabled on composefs image
```

---

https://github.com/ostreedev/ostree-rs-ext/pull/556

```
error: Staging deployment: Initializing deployment: Checking out deployment tree: Generated composefs image digest (573ad0fe84d7f61d2d632fee995c29acf3d72311eeed775b1f9a5af4dfb33001) doesn't match expected digest (172eb44f9640fdbc756a1570cc0ad8fb1a41f4b3f21dce4232b04112e7fcd8d2)
```
