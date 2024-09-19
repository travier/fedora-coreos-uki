#!/bin/bash

rm -v VARS_CUSTOM.secboot.fd
GUID=$(cat ../GUID)

virt-fw-vars --input /run/host/usr/share/edk2/ovmf/OVMF_VARS.secboot.fd \
  --secure-boot  \
  --set-pk $GUID ../keys/PK/PK.pem \
  --add-kek $GUID ../keys/KEK/KEK.pem \
  --add-db $GUID ../keys/db/db.pem \
  -o VARS_CUSTOM.secboot.fd 

