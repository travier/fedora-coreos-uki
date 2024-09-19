# Fedora CoreOS UKI PoC


# How to reproduce

## Start a secureboot VM

See under [virtual_machine](./virtual_machine) to generate a volume containing
the secureboot keys. This can then be attached to the virtual machine as NVRAM.

The integrity demo requires the root disk to be formatted in ext.4. \
See [uki.bu](./uki.bu).

Once the coreOS VM is booted, follow these steps.\
_NOTE:_ Everything should be ran as *root*.

## 1 Download and unpack our signed build of coreOS

Enable FS verity on the root filesystem and the ostree repo:
``` 
tune2fs -O verity /dev/disk/by-partlabel/root
ostree config set ex-fsverity.required true
```
Download and unencapsulate the conter, then deploy the ostree commit. \
See [demo/1-ostree-commit](demo/1-ostree-commit).

## 2 Setup systemd-boot

Install systemd-boot with `bootctl install`. A package is missing in FCOS 
unfortunately. See [demo/2-install-sd-boot](demo/2-install-sd-boot).

## 3 Setup the UKI

You should be able to reboot into the new deployment and everything is sealed. 

## 4 Put it to the test !! 

In [demo/](demo) you will find two scripts named `4-demo-find-backing-file` and 
`5-demo-tamper-file-block` to show how fsverity will protect your system against 
tampering.


Firstly, find the backing file of your target : 
```
# 4-demo-find-backing-file /usr/lib/os-release
The repo file for /usr/lib/os-release is:
/ostree/repo/objects/75/591953b65dc61722f77f54e416fbeb7e342ad6bd53b80a07862475b662852d.file

```
This script is just a helper to locate the backing file of a checked out file in the 
ostree repo.


Then, tamper the backing file (make sure to be *root*):
```
# 5-demo-tamper-file-block /ostree/repo/objects/75/591953b65dc61722f77f54e416fbeb7e342ad6bd53b80a07862475b662852d.file
/ostree/repo/objects/75/591953b65dc61722f77f54e416fbeb7e342ad6bd53b80a07862475b662852d.file is at offset on device /dev/disk/by-partlabel/root
Original initial block:
NAME="Fedora Linux"
VERSION="40.

Modifying initial block

Modified initial block:
NAME="FOOBAR Linux"
VERSION="40.
```
This script does a little bit more magic : it flushes the caches then locate the position
of the file at the block level. This position is then overwrote with a few bytes to tamper the
file content.

If you try to read the deployed file again you will get an error:
```
 cat /usr/lib/os-release 
cat: /usr/lib/os-release: Input/output error

```  
And in the journal : 
```
[  156.086877] fs-verity (vda3, inode 426106): FILE CORRUPTED! pos=0, level=-1, want_hash=sha256:672df088670aaa61c35d14aa148168dc0e312ae9294f903ef85c8c0b5a17037a, real_hash=sha256:9bf652778a15df188e9318e6105f7a6e9154abb22a40dee4220fca8422b3d813

```
## License

See [LICENSE](LICENSE) or [CC0](https://creativecommons.org/public-domain/cc0/).
