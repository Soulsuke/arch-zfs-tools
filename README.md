# arch-zfs-tools

A collection of tools I use to manage Arch under ZFS, hoping they can help
somebody else :)  



### zbm-ucode-bundler.bash

Since ZfsBootMenu can't load the kernel while adding in the microcode, this
script ensures there will always be an additional image with the ucode bundled
with the initramfs.  

Sample pacman hook:
```
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
Description = Generating kernel image with bundled microcode...
When = PostTransaction
Exec = /path/to/zbm-ucode-bundler.bash linux intel-ucode
```



### zbm-update-github.bash

Downloads the latest release of ZfsBootMenu from github and places it within
the EFI folder.  
It should work as long as an EFI entry has been added calling
"zfsbootmenu.EFI".  



### zfs-snapshotter.bash

A simple bash script to take snapshots of ZFS dataset.  
Just a handy way to manage a maximum number of snapshots.  

##### Help reference
```
zfs-snapshotter usage:
  zfs-snapshotter <dataset name> <max snapshots # to keep> <snapshot suffix>
```

##### Sample usage as a pacman hook for periodic snapshots on kernel update
```
[Trigger]
Type = Package
Operation = Install
Operation = Upgrade
Target = linux

[Trigger]
Type = Path
Operation = Install
Operation = Upgrade
Target = usr/lib/modules/*/vmlinuz

[Action]
Description = Creating a backup BE...
When = PreTransaction
Exec = /usr/bin/sh -c '/path/to/zfs-snapshotter.bash zroot/e/ROOT/arch 3 "$(uname -r)"'
```

