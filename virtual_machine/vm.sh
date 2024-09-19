#!/bin/bash
set -euxo pipefail


#IMAGE="/var/lib/libvirt/images/fedora-coreos-40.20240701.3.0-qemu.x86_64"
IMAGE="$HOME/Downloads/fedora-coreos-40.20240701.3.0-qemu.x86_64.qcow2"

IGNITION_CONFIG=$(pwd)/"uki.ign"

SB_VARS=$(pwd)/secureboot/ovmf/VARS_CUSTOM.secboot.fd
SB_VARS_TEMPLATE=/usr/share/edk2/ovmf/OVMF_VARS.secboot.fd
SB_CODE=/usr/share/OVMF/OVMF_CODE.secboot.fd

IGNITION_DEVICE_ARG=(--qemu-commandline="-fw_cfg name=opt/com.coreos/config,file=${IGNITION_CONFIG}")

virt-install \
    --connect="qemu:///system" \
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

