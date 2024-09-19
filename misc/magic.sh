#!/bin/bash
set -euxo pipefail

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

echo "setting up systemd-boot..."

curl https://dl.fedoraproject.org/pub/fedora/linux/updates/40/Everything/x86_64/Packages/s/systemd-boot-unsigned-255.10-3.fc40.x86_64.rpm \
  --output systemd-boot-unsigned-255.10-3.fc40.x86_64.rpm
rpm-ostree usroverlay
rpm -i systemd-boot-unsigned-255.10-3.fc40.x86_64.rpm

sudo mount /dev/disk/by-partlabel/EFI-SYSTEM /boot/efi
bootctl install
# default sd-boot is 0 and default will boot firmware
echo "timeout 30" >> /boot/efi/loader/loader.conf


echo "Download signed composeFS fedora coreOS"

tune2fs -O verity /dev/vda4
ostree config set ex-fsverity.required true
  
unshare -m
mount -o remount,rw /sysroot

osversion="$(skopeo inspect docker://quay.io/travier/fedora-coreos-uki:latest | jq -r '.Labels."org.opencontainers.image.version"')"
ostree container unencapsulate \
  --repo /sysroot/ostree/repo \
  --write-ref "fedora/coreos/uki/${osversion}" \
  ostree-unverified-image:registry:quay.io/travier/fedora-coreos-uki:latest

ostree admin deploy --stage "fedora/coreos/uki/${osversion}"
ostree admin post-copy

echo "setting up the UKI"

podman create --name uki quay.io/travier/fedora-coreos-uki:uki
podman cp uki:/uki uki
podman cp uki:/systemd-bootx64-signed.efi systemd-bootx64-signed.efi
podman rm -f uki
podman rmi quay.io/travier/fedora-coreos-uki:uki

# copy the uki to /boot
mount -o remount,rw /boot
machine_id=$(cat /etc/machine-id)
kernelver=$(uname -r)
mv uki /boot/efi/EFI/Linux/"$machine_id"-"$kernelver".efi

echo "rewrite systemd-boot binary with the secureboot-signed one"
mv systemd-bootx64-signed.efi /boot/efi/EFI/systemd/systemd-bootx64.efi

echo "All done, now you can just reboot"
