# Sourcing OVMF template files

```
cp usr/share/edk2/ovmf/OVMF_CODE.secboot.fd .
cp /usr/share/edk2/ovmf/OVMF_VARS.secboot.fd .
```

# Inject secureboot cert

IMPORTANT NOTE: at least for libvirt, this must be regenerated each
time you create a VM. SELinux labels change and the the VM silently ignore 
the custom vars on subsequent uses. 
```
dnf install python3-virt-firmware

GUID=$(cat ../GUID)
virt-fw-vars --input /run/host/usr/share/edk2/ovmf/OVMF_VARS.secboot.fd \
  --secure-boot  \
  --set-pk $GUID ../keys/PK/PK.pem \
  --add-kek $GUID ../keys/KEK/KEK.pem \
  --add-db $GUID ../keys/db/db.pem \
  -o VARS_CUSTOM.secboot.fd 
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

## Virtmanager

To load custom VARS files trough virtmanager, here is the relevant part

```
  <os firmware='efi'>
    <type arch='x86_64' machine='pc-q35-8.2'>hvm</type>
    <firmware>
      <feature enabled='yes' name='enrolled-keys'/>
      <feature enabled='yes' name='secure-boot'/>
    </firmware>
    <loader readonly='yes' secure='yes' type='pflash'>/usr/share/edk2/ovmf/OVMF_CODE.secboot.fd</loader>
    <nvram template='/usr/share/edk2/ovmf/OVMF_VARS.secboot.fd'>/path/to/VARS_CUSTOM.qcow2</nvram>
    <boot dev='hd'/>
  </os>
```
 
# Links

https://gitlab.com/kraxel/virt-firmware
https://wiki.debian.org/SecureBoot/VirtualMachine
https://github.com/rhuefi/qemu-ovmf-secureboot
