#!/bin/bash
set -euxo pipefail

IMAGE="${HOME}/Downloads/fedora-coreos-40.20240701.3.0-qemu.x86_64.qcow2"

IGNITION_CONFIG="${HOME}/cosa/ign-configs/ssh-and-autologin.ign"

SB_VARS=$(pwd)/ovmf/VARS_CUSTOM.fd
SB_VARS_TEMPLATE=/usr/share/edk2/ovmf/OVMF_VARS.secboot.fd
SB_CODE=/usr/share/OVMF/OVMF_CODE.fd

IGNITION_DEVICE_ARG=(--qemu-commandline="-fw_cfg name=opt/com.coreos/config,file=${IGNITION_CONFIG}")

virt-install --connect="qemu:///system" \
    --name="fcos-uki" \
    --vcpus=2 \
    --memory=2048 \
    --machine q35 \
    --features smm.state=on \
    --os-variant="fedora-coreos-stable" \
    --import \
    --graphics=none \
    --disk="size=10,backing_store=${IMAGE}" \
    --boot loader=${SB_CODE},loader.readonly=yes,loader.type=pflash,nvram.template="${SB_VARS_TEMPLATE}",nvram="${SB_VARS}",loader_secure=yes \
    --network bridge=virbr0 "${IGNITION_DEVICE_ARG[@]}"

# qemu-kvm -m 2048 -cpu host -nographic   -machine q35,smm=on  \
#      -global driver=cfi.pflash01,property=secure,value=on   \
#      -drive if=pflash,format=qcow2,unit=0,readonly=on,file=$SB_CODE \
#      -drive if=pflash,format=qcow2,unit=1,file=$SB_VARS \
#      -drive if=virtio,file=$IMAGE\
#      -nic user,model=virtio,hostfwd=tcp::2222-:22
