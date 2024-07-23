# Sourcing OVMF files

```
cp usr/share/edk2/ovmf/OVMF_CODE.secboot.fd .
cp /usr/share/edk2/ovmf/OVMF_VARS.secboot.fd .
```


# Inject secureboot cert

```
dnf install python3-virt-firmware

virt-fw-vars --inplace OVMF_VARS.secboot.fd --enroll-cert ../keys/KEK/KEK.pem --secure-boot
```

# Start VM

```
IGNITION_DEVICE_ARG="-fw_cfg name=opt/com.coreos/config,file=ssh.ign"

qemu-kvm -m 2048 -cpu host -nographic \
  -machine q35,smm=on \
  -global driver=cfi.pflash01,property=secure,value=on \
  -drive if=pflash,format=raw,unit=0,readonly=on,file=./OVMF_CODE.secboot.fd \
  -drive if=pflash,format=raw,unit=1,file=./OVMF_VARS.secboot.fd \
  -drive file=${IMAGE},format=qcow2  ${IGNITION_DEVICE_ARG} \
  -nic user,model=virtio,hostfwd=tcp::2222-:22
```
 
# Links

https://gitlab.com/kraxel/virt-firmware
https://wiki.debian.org/SecureBoot/VirtualMachine
https://github.com/rhuefi/qemu-ovmf-secureboot
