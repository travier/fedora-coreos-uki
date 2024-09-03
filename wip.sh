
# Add grub entries for the UKI and uefi shell

sudo mount -o remount,rw /boot
Update /boot/grub2/grub.cfg & /boot/grub2/uki.cfg

# turn on fsverity on filesystem
sudo tune2fs -O verity /dev/vda4
# enable fsverity in the ostree repo
ostree config set ex-fsverity.required true
# apply the fs-verity to the files
sudo ostree admin post-copy

# tell ostree to verify composeFS 
echo -e "[composefs]\nenabled=signed" > /etc/ostree/prepare-root.conf

# create a new mount namespace
sudo unshare -m
# remount /sysroot to writeable
mount -o remount,rw /sysroot
# get version from container image (e.g 40.20240827.dev.0)
osversion="$(skopeo inspect docker://quay.io/travier/fedora-coreos-uki:latest | jq -r '.Labels."org.opencontainers.image.version"')"
# extract ostree commit from image to a new reference : fedora/coreos/uki/$version.
ostree container unencapsulate \
  --repo /sysroot/ostree/repo \
  --write-ref "fedora/coreos/uki/${osversion}" \
  ostree-unverified-image:registry:quay.io/travier/fedora-coreos-uki:latest

# deploy the ostree commit we just unencapsulated
ostree admin deploy --stage "fedora/coreos/uki/${osversion}"

# container to extract the UKI
podman create --name uki quay.io/travier/fedora-coreos-uki:uki
podman cp uki:/uki uki
podman rm -f uki
podman rmi quay.io/travier/fedora-coreos-uki:uki
# copy the uki to /boot
sudo mount -o remount,rw /boot
sudo mv uki /boot/ostree/uki

# Fix missing entry (the UKI will try to boot ostree/boot.1)
cd /ostree
sudo ln -snf boot.0 /ostree/boot.1
sudo ln -snf /ostree/boot.0.0 boot.1
ls -alh /ostree/

sync
sudo reboot

# below are steps to build the UKI

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

---

