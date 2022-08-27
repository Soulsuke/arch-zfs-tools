# zfs-snapshotter

A simple bash script to take snapshots of ZFS dataset.  
Just a handy way to manage a maximum number of snapshots.  

### Help reference
```
zfs-snapshotter usage:
  zfs-snapshotter <dataset name> <max snapshots #> <snapshot suffix>
```

### Sample usage as a pacman hook for periodic snapshots on kernel update
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
Exec = /usr/bin/sh -c '/path/to/zfs-snapshotter zroot/e/ROOT/arch 3 "$(uname -r)"'
```

