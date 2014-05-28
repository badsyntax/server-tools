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

Show snapshots when listing the zfs partitions.

```bash
zpool set listsnapshots=on lxc
```

## LXC Networking

LXC should add the relevant iptables rule/s automatically, but if you remove them by mistake, then you need to have at least the following rules:

```
Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination         
MASQUERADE  all  --  10.0.3.0/24         !10.0.3.0/24 
```

Iptables Rules:

```
-A POSTROUTING -s 10.0.3.0/24 ! -d 10.0.3.0/24 -j MASQUERADE
-A POSTROUTING -j MASQUERADE
```
 
