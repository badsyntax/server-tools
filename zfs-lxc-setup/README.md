# ZFS and LXC setup

(You should be root when exeucting any of the commands below.)

## Prep

First, update your packages and ensure you add apt-add-repository installed:

```bash
apt-get update
apt-get install python-software-properties -y
```

## Install LXC

```bash
apt-add-repository ppa:ubuntu-lxc/daily
apt-get update
apt-get install lxc -y
```

## Install ZFS

```bash
add-apt-repository ppa:zfs-native/stable
apt-get update
apt-get install ubuntu-zfs -y
```

## Setup ZFS

Create the mirrored zfs pool from the partitions you created in previous steps:

`zpool create lxc mirror /dev/disk/by-id/wwn-......-part4 /dev/disk/by-id/wwn-......-part4`

Now an `/lxc` directory should exist.

Symlink the `/lxc` directory:

```bash
rmdir /var/lib/lxc
ln -s /lxc /var/lib/
```

Disable deduplication:

``` bash
zfs set dedup=off lxc
```

Show snapshots when listing the zfs paritions.

```bash
zpool set listsnapshots=on lxc
```

