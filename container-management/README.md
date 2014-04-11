# CONTAINER MANAGEMENT

Ensure you have followed all the steps in the zfs-lxc-setup README before continuing. This guide assumes you have your host OS setup, your disks setup, lxc and zfs installed.

## Creating the base container

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

Add a new user, add user to sudo group:

```
adduser <username>
usermod -aG sudo <username>
```

*Now log out, and log back in using the credentials for the user you just created.*

Remove the ubuntu user:

```
userdel -r ubuntu
```

Install basic software:

```
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

## Cloning containers

Now that our base container is setup, let's snapshot it and start creating different container environments.

### Creating a base LAMP container

```
lxc-clone -s -o ubuntu-base -n ubuntu-lamp
```


