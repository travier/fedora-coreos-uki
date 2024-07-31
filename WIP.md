https://github.com/ostreedev/ostree-rs-ext/pull/556

sudo unshare -m
mount -o remount,rw /sysroot
osversion="$(skopeo inspect docker://quay.io/travier/fedora-coreos-uki:latest | jq -r '.Labels."org.opencontainers.image.version"')"
ostree container unencapsulate \
  --repo /sysroot/ostree/repo \
  --write-ref "fedora/coreos/uki/${osversion}" \
  ostree-unverified-image:registry:quay.io/travier/fedora-coreos-uki:latest

ostree admin deploy --stage "fedora/coreos/uki/${osversion}"

```
error: Staging deployment: Initializing deployment: Checking out deployment tree: Generated composefs image digest (573ad0fe84d7f61d2d632fee995c29acf3d72311eeed775b1f9a5af4dfb33001) doesn't match expected digest (172eb44f9640fdbc756a1570cc0ad8fb1a41f4b3f21dce4232b04112e7fcd8d2)
```


