#CONTAINER MANAGEMENT

Ensure you have followed all the steps in the zfs-lxc-setup README before continuing. This guide assumes you have your host OS setup, your disks setup, lxc and zfs installed.

##Base Containers

Base containers will be used as a skeleton for other containers.

###Create the first base container

Create a base container with ZFS backing store:

```
lxc-create -t ubuntu -n ubuntu-base -B zfs
```

Start the container as a daemon:

```
lxc-start -n ubuntu-base -d
```

Log into the container:

```
lxc-console -n ubuntu-base
```

Username: ubuntu
Password: ubuntu

Start new shell as root user:

```
sudo -s
```

Add a new user, add user to sudo group:

```
adduser <username>
usermod -aG sudo <username>
```

*Now log out, and log back in using the credentials for the user you just created.*

Start new shell as root user:

```
sudo -s
```

Remove the ubuntu user:

```
userdel -r ubuntu
```

Change the apt mirror for faster software installs:


Example `/etc/apt/sources.list`:

```
#######################################################################################
# Hetzner APT-Mirror

deb http://mirror.hetzner.de/ubuntu/packages precise main restricted universe multiverse
deb http://mirror.hetzner.de/ubuntu/packages precise-backports main restricted universe multiverse
deb http://mirror.hetzner.de/ubuntu/packages precise-updates main restricted universe multiverse
deb http://mirror.hetzner.de/ubuntu/security precise-security main restricted universe multiverse
```

Install basic software:

```
apt-get update  
apt-get install vim curl wget bash-completion build-essential python-software-properties -y
```

Install mail utils:

```
apt-get install postfix mailutils -y
```

If you need to reconfigure postfix:

```
dpkg-reconfigure postfix
```

Check mail is working:

```
echo "Hello, world" | mail -s "Anybody out there?" YOUR@EMAIL.COM
```

*Log out, and stop the container:*

```
lxc-stop -n ubuntu-base
```

Now snapshot the ubuntu-base filesystem. We'll be builing up from this point using different snapshots of this OS:

```
zfs snapshot lxc/ubuntu-base@v0.1
```

###Create a base LAMP container.

See lamp-container

###Create a base Node.js container

See nodejs-container

##User containers

Now that we have created our base containers, we can start creating containers for users. 

We don't want to clone containers to create user containers as it makes restoring the backups a bit more cumbersome.

First thing to is create the container:

```
lxc-create -t ubuntu -n my-conainer -B zfs
```

Now we replace the filesystem with a copy of a base container:


```
zfs send lxc/ubuntu-lamp@v0.1 | zfs receive lxc/my-container -F
```

At this point zfs would have auto-created the v0.1 snapshot of the 'my-container' container. You'll want to remove this snapshot:

```
zfs destroy lxc/my-container@v01
```


Set quotas on the disk:

```
zfs set quota=10G lxc/my-container
```

Auto-start the container on host boot:

```
vi /var/lib/lxc/my-container/config
# Add lxc.start.auto = 1
```

Adjust networking for container (for example):

```
vi /var/lib/lxc/my-container/config
lxc.network.ipv4 = 10.0.3.132
```

Now we need to port-forward a random port to the container's SSH port:

```
iptables -t nat -A PREROUTING -p tcp -d <EXTERNAL_HOST_IP> -j DNAT --dport 2222 --to-destination <CONTAINER_IP>:22
```

Save the rules:

```
iptables-save > /etc/iptables.conf
```

View the rules:

```
iptables -t nat -L
```

Auto load iptables rules on boot:

```
vi /etc/network/interfaces
```

```
iface eth0 inet static
  pre-up iptables-restore < /etc/iptables.conf
```

Retart the container:

```
lxc-stop -n my-container
lxc-start -n my-conainer
```

Change mysql root password:

```
mysqladmin -u root -p'root' password NEWPASSWORD
```

## General notes

If you try to destroy a container, the `lxc-destroy' command will fail if the zfs filesystem has any snapshots. When I run:

```
lxc-destroy -n sascha
```

This is the error message I get:


```
root@proxima:~# lxc-destroy -n sascha
cannot destroy 'lxc/sascha': filesystem has children
use '-r' to destroy the following datasets:
lxc/sascha@first
lxc_container: Error destroying rootfs for sascha
Destroying sascha failed
```

You need to first destroy the zfs filesystem and all snapshots:

```
zfs destroy lxc/sascha -r
```

And then you can destroy the container:

```
lxc-destroy -n sascha
```

If you get "dataset is buy" error when trying destroy a zfs filesystem then I found rebooting solves this.
