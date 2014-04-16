#RESTORE

Restoring backup zfs snapshots is pretty straighforward.

Example:

```
gunzip container@0.1.gz
zfs receive lxc/container < container@0.1 -F
zfs destroy lxc/container@0.1
```
