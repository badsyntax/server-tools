#LAMP-CONTAINER

Now that our base container is setup, let's snapshot it and start creating different container environments.

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

Start new shell as root user:

```
sudo -s
```

Install LAMP stuff:

```
apt-get install mysql-server apache2 php5 php-pear php5-curl php5-dev php5-mcrypt php5-mysql php5-gd php-apc phpmyadmin -y
```

During this install process, mysql will ask for a root password. Set it to a default value, but remember to change it when setting up new containers as clones of this lamp container.

Enable mycrypt extension:

```
sudo php5enmod mcrypt
sudo service apache2 restart
```

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

Allow Apache (2.4) to read user home directory:

In /etc/apache/apache2.config:

```
<Directory /home/username/www/sites>
	Options Indexes FollowSymLinks
	AllowOverride None
	Require all granted
</Directory>
```

Enable Apache modules:

```
a2enmod headers
a2enmod rewrite
a2enmod ssl
```

Edit PHP config:

```
vi /etc/php5/apache2/php.ini
```

..and update the following:

```
upload_max_filesize = 32M
post_max_size = 64M
date.timezone = "Europe/London"
memory_limit = 128M
expose_php = Off
```

Test Apache config:

```
apache2ctl configtest
```

Restart Apache:

```
service apache2 restart
```

*You're done setting up the base LAMP container, now exit out of the container.*
