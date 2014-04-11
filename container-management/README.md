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

## Cloning containers

Now that our base container is setup, let's snapshot it and start creating different container environments.

### Creating a base LAMP container

```
lxc-clone -s -o ubuntu-base -n ubuntu-lamp
```

Check the zfs partitions have been created correctly:

```
zfs list
```

Now start and log into the ubunt-lamp container:

```
lxc-start -n ubuntu-lamp -d
lxc-console -n ubuntu-lamp
```

Install LAMP stuff:

```
apt-get install mysql-server apache2 php5 php-pear php5-curl php5-dev php5-mcrypt php5-mysql php5-gd php-apc phpmyadmin -y
```

During this install process, mysql will ask for a root password. Set it to a default value, but remember to change it when setting up new containers as clones of this lamp container.

Set Apache ServerName:

```
echo "ServerName HOSTNAME" >> /etc/apache2/apache2.conf
```

Set ServerTokens (apache info headers):

```
echo "ServerTokens Prod" >> /etc/apache2/apache2.conf
```

Set ServerSignature (server info on dir listings or error pages):

```
echo "ServerSignature Off" >> /etc/apache2/apache2.conf
```

Enable Apache modules:

```
a2enmod headers
a2enmod rewrite
a2enmod ssl
```

Edit PHP config

```
vi /etc/php5/apache2/php.ini
```

..and update the following:

```
upload_max_filesize = 32M
post_max_size = 64M
date.timezone = "Europe/London"
memory_limit = 128M
```

Test Apache config

```
apache2ctl configtest
```

Restart Apache

```
service apache2 restart
```

*Now exit out of the container.*
