sudo dnf install -y python3-virt-firmware

sbsign --key secureboot/keys/db/db.key --cert secureboot/keys/db/db.pem systemd-bootx64.efi
pe-listsigs systemd-bootx64.efi.signed

sudo mount -o remount,rw /boot/ && sudo mount /dev/vda2 /boot/efi/
sudo cp systemd-bootx64.efi.signed /boot/efi/EFI/sdboot.efi
efibootmgr --create-only --label sdboot --disk /dev/vda --part 2 --loader "\EFI\sdboot.efi"
efibootmgr --bootnext 0003
efibootmgr --bootorder 0003,0002,0001,0000
