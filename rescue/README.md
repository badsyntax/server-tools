# RESCUE

Hetzner provides a pretty handy rescue system which allows you to re-install your operating system, as well as partition your disk and setup RAID.

For our setup, we have 2 x 2TB disks. We want to use 128GB in RAID-1 for the host operation system and leave the reset unparitioned (for now).

The only changes we made to the installimage config was to change the root (/) size to 128GB and change the hostname. After saving the install image config, the rescue system will partition the disk, setup RAID-1 and install the operating system.

## Parition disks

Once you've booted into your OS for the first time, we'll want to parition the free space on each of the drives.

(All the commands below should be run as root.)

Run: `cfdisk /dev/sda`

Scroll down to the Free Space, Create new partition, use all the space, write changes and exit.

Repeat for the other disk:

Run: `cfdisk /dev/sdb`

Scroll down to the Free Space, Create new partition, use all the space, write changes and exit.

**Now reboot the machine.**

Log back into the machine, and check the partitions:

`cat /proc/partitions`

You should have "sda1,sda2,sda3,sda4 and sdb1,sdb2,sdb3,sdb4" as well as raid paritions

## Install LXC

Install lxc

apt-get install python-software-properties -y
apt-add-repository ppa:ubuntu-lxc/daily
apt-get update
sudo apt-get install lxc -y


## Setup ZFS

Install:
  
```bash
apt-get install python-software-properties -y
add-apt-repository ppa:zfs-native/stable
apt-get update
apt-get install ubuntu-zfs -y
```

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

Show snapshots:

```bash
zpool set listsnapshots=on lxc
```

