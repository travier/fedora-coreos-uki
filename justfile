build:
    #!/bin/bash
    set -euo pipefail
    ./gen-ostree-signing-key
    podman build -t uki \
        --secret=id=key,src=secureboot/keys/db/db.key \
        --secret=id=cert,src=secureboot/keys/db/db.pem \
        --secret=id=ostree,src=ostree-sign.key \
        --secret=id=ostreepub,src=ostree-sign.pub \
        fcos-uki
