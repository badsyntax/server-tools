#RESTORE

Restoring backup zfs snapshots is pretty straighforward.

Example:

```
gunzip container@0.1.gz
zfs receive lxc/container < container@0.1 -F
zfs destroy lxc/container@0.1
```

## Restore locally

The following instructions assume you're restoring the backup on an ubuntu host.

Ensure you are root:

```
sudo -s
```

Create a temporary 10GB file.

```
dd if=/dev/zero of=/tmp/disk1.img bs=1024 count=10485760
```

Then create a zfs pool on that file:

```
zpool create lxc /tmp/disk1.img
```

Extract the backup file on your local machine:

```
gunzip sascha@0.1.gz
```

Now lets create a new container for the backup restoration:

```
lxc-create -t ubuntu -n sascha -B zfs
```

Import the backup:

```
zfs receive lxc/sascha < sascha@0.1 -F
zfs destroy lxc/sascha@0.1
```

Start and login into the container:

```
lxc-start -n sascha 
```

Links:

http://zef.me/6023/who-needs-git-when-you-got-zfs
