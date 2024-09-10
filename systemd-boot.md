sudo dnf install -y python3-virt-firmware

sbsign --key secureboot/keys/db/db.key --cert secureboot/keys/db/db.pem systemd-bootx64.efi
pe-listsigs systemd-bootx64.efi.signed

sudo mount -o remount,rw /boot/ && sudo mount /dev/vda2 /boot/efi/
sudo cp systemd-bootx64.efi.signed /boot/efi/EFI/sdboot.efi
efibootmgr --create-only --label sdboot --disk /dev/vda --part 2 --loader "\EFI\sdboot.efi"
efibootmgr --bootnext 0003
efibootmgr --bootorder 0003,0002,0001,0000

--- Notes from JB

# get systemd-boot binary
# in a toolbox
sudo dnf download systemd-boot-unsigned
rpm-ostree usroverlay
rpm -i systemd-boot-unsigned-255.10-3.fc40.x86_64.rpm

# sign sd-boot with our own secureboot key
sudo dnf install -y sbsigntools pesign
git clone https://github.com/travier/fedora-coreos-uki
cp fedora-coreos-uki/secureboot/keys/db/* .
sbsign --key db.key --cert db.pem /usr/lib/systemd/boot/efi/systemd-bootx64.efi \
  --output systemd-bootx64-signed.efi

# mount efi
sudo mount /dev/disk/by-partlabel/EFI-SYSTEM /boot/efi

#install systemdboot
bootctl install
# default sd-boot is 0 and default will boot firmware
echo "timeout 30" >> /boot/efi/loader/loader.conf


# overwrite sd-boot with our signed sd-boot EFI binary
sudo cp systemd-bootx64-signed.efi /boot/efi/EFI/systemd/systemd-bootx64.efi


machine_id=$(cat /etc/machine-id)
kernelver=$(uname -r)
cp /boot/ostree/uki /boot/efi/EFI/Linux/$machine_id-$kernelver.efi


https://blog.dowhile0.org/2022/09/04/booting-fedora-with-sd-boot-and-secure-boot-enabled/

https://wiki.archlinux.org/title/Unified_kernel_image
https://man.archlinux.org/man/sd-boot.7#FILES
https://uapi-group.org/specifications/specs/boot_loader_specification/#type-2-efi-unified-kernel-images


 ----

Missing fields in os-release data from unified kernel image /boot/efi/EFI/Linux/21da3a4990ab46ffa83f3df147b2a98a-6.9.9-200.fc40.x86_64.efi, refusing.

https://github.com/systemd/systemd/pull/21285/commits/c2caeb5d54b6065d46f7be9dccd46ebed3775e80
https://github.com/systemd/systemd/blob/f2129f1d8c1a92f4ca98bfc06795d9cb5ed0acd2/src/shared/bootspec.c#L674

fix : 
https://github.com/travier/coreos-assembler/commit/1998c8774f924bf734f7d1e0f500fcc64684f41c

