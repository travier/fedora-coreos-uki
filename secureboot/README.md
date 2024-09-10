In a toolbox : 

Dependencies
```
dnf install -y python3-virt-firmware
```

Genreate NVRAM vars with secureboot keys enrolled : 
```
./ovmf/generate-ovmf-vars.sh
```

Launch a VM with `./vm.sh`
