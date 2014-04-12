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

###Create a base LAMP container.

See lamp-container

###Create a base Node.js container

See nodejs-container

##User containers

Now that we have created our base containers, we can start creating containers for users.

If a user would like a LAMP environment, simply clone the base LAMP container:


```
lxc-clone -s -o ubuntu-lamp -n my-container
```

Auto-start the container on host boot:

```
ln -s /var/lib/lxc/my-container/config /etc/lxc/auto/my-container
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
