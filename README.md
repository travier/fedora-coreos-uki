# Fedora CoreOS UKI PoC


# How to reproduce

## Get a secureboot VM
See under secureboot

## 1 setup systemdboot

```
curl https://dl.fedoraproject.org/pub/fedora/linux/updates/40/Everything/x86_64/Packages/s/systemd-boot-unsigned-255.10-3.fc40.x86_64.rpm \ 
  --output systemd-boot-unsigned-255.10-3.fc40.x86_64.rpm
rpm-ostree usroverlay
rpm -i systemd-boot-unsigned-255.10-3.fc40.x86_64.rpm

sudo mount /dev/disk/by-partlabel/EFI-SYSTEM /boot/efi
bootctl install
# default sd-boot is 0 and default will boot firmware
echo "timeout 30" >> /boot/efi/loader/loader.conf

# get systemd boot signed with our SB key
curl https://raw.githubusercontent.com/travier/fedora-coreos-uki/main/secureboot/systemd-bootx64-signed.efi \
  --output /boot/efi/EFI/systemd/systemd-bootx64.efi

```
## 2 Download signed composeFS fedora coreOS 

Firstly, we enable fs-verity on the ostree repository
```
# turn on fsverity on filesystem
sudo tune2fs -O verity /dev/vda4
# enable fsverity in the ostree repo
ostree config set ex-fsverity.required true
  
```

Then, we download and deploy the ostree build 
```
# create a new mount namespace
unshare -m

# remount /sysroot to writeable
mount -o remount,rw /sysroot

osversion="$(skopeo inspect docker://quay.io/travier/fedora-coreos-uki:latest | jq -r '.Labels."org.opencontainers.image.version"')"
# extract ostree commit from image to a new reference : fedora/coreos/uki/$version.
ostree container unencapsulate \
  --repo /sysroot/ostree/repo \
  --write-ref "fedora/coreos/uki/${osversion}" \
  ostree-unverified-image:registry:quay.io/travier/fedora-coreos-uki:latest

# deploy the ostree commit we just unencapsulated
ostree admin deploy --stage "fedora/coreos/uki/${osversion}"

ostree admin post-copy

```

## Install the UKI
```
# container to extract the UKI
podman create --name uki quay.io/travier/fedora-coreos-uki:uki
podman cp uki:/uki uki
podman rm -f uki
podman rmi quay.io/travier/fedora-coreos-uki:uki

# copy the uki to /boot
mount -o remount,rw /boot
machine_id=$(cat /etc/machine-id)
kernelver=$(uname -r)
mv uki /boot/efi/EFI/Linux/$machine_id-$kernelver.efi
```
Reboot !

See fsverity-success to check if all is working as expected.
## License

See [LICENSE](LICENSE) or [CC0](https://creativecommons.org/public-domain/cc0/).
