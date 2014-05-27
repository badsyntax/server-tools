#Monitoring

## Introduction

We want to do some basic monitoring on both the host OS and the containers. Nagios is the obvious choice because it's probably
the most popular monitoring software and supports remote monitoring. We'll be using Nagios Version 3 as it's the default supported version in Ubuntu 12.04.

We don't want to install the full Nagios3 package on the host OS or containers as it has many depedencies we'd rather not install, like Apache. Instead, we're going to the use the `nagios-nrpe-server` package to run checks on the remote servers, and install the full Nagios3 web package onto a seperate machine. 

We'll be using the backup machine for installing the main nagios web package and runnng checks on the remote servers.

## Installing Nagios on the monitoring/backup server

Before we setup monitoring on the host OS and containers, we need to install nagios on our monitoring/backup server:

```
sudo apt-get update
sudo apt-get install nagios3 nagios-nrpe-plugin
```

Navigate to monitoringserver/nagios3 with your browser.

## Installing the nagios server within a container or the host OS

```
sudo apt-get update
sudo apt-get install nagios-nrpe-server
```

Check that the plugins were installed:

```
ls -l /usr/lib/nagios/plugins/
```

### Adjusting the config

```
vi /etc/nagios/nrpe_local.cfg
```

Add the following, but change X.X.X.X to the ip address of the backup server. 

```
######################################
# Do any local nrpe configuration here
######################################

allowed_hosts=127.0.0.1,X.X.X.X

command[check_users]=/usr/lib/nagios/plugins/check_users -w 5 -c 10
command[check_load]=/usr/lib/nagios/plugins/check_load -w 15,10,5 -c 30,25,20
command[check_rootfs_disk]=/usr/lib/nagios/plugins/check_disk -w 20 -c 10 /
command[check_zombie_procs]=/usr/lib/nagios/plugins/check_procs -w 5 -c 10 -s Z
command[check_total_procs]=/usr/lib/nagios/plugins/check_procs -w 150 -c 200
command[check_swap]=/usr/lib/nagios/plugins/check_swap -w 20 -c 10
```

Restart the nrpe service:

```
service nagios-nrpe-server restart
```

## Forwarding ports for nagios installed in containers

If you installed the nrpe-server on a container, then we need to port-forward an 'outside' port on the host OS to an 'internal' container port. I leave the default port setting in `/etc/nagios/nrpe.cfg', which is 5666. I then port-forward ports starting from 5667 to port 5666 on the various containers.


```
iptables -t nat -A PREROUTING -p tcp -d <EXTERNAL_HOST_IP> -j DNAT --dport 5667 --to-destination <CONTAINER_IP>:5666
```

Save the rules:

```
iptables-save > /etc/iptables.conf
```

View the rules:

```
iptables -t nat -L
```

Now on your backup/monitoring server, check that we can connect to the nagios nrpe server within the container:

```
/usr/lib/nagios/plugins/check_nrpe -H 148.251.88.203 -p 5667
```

Adding a new host to the nagios monitoring server:

cd /etc/nagios3/conf.d
cp localhost_nagios2.cfg container.yourhost.com_nagios2.cfg
vi container.yourhost.com

Add the following: (change X.X.X.X to your host machine ip address, change <port> to the port where nagios-npre-server is listening.)

```
# A simple configuration file for monitoring the local host
# This can serve as an example for configuring other servers;
# Custom services specific to this host are added here, but services
# defined in nagios2-common_services.cfg may also apply.
# 

define host{
        use                     generic-host            ; Name of host template to use
        host_name              	container.yourhost.com
        alias                   container.yourhost.com
        address                 X.X.X.X -p <port>
        }

# Define a service to check the disk space of the root partition
# on the local machine.  Warning if < 20% free, critical if
# < 10% free space on partition.

define service{
        use                             generic-service         ; Name of service template to use
        host_name                       container.yourhost.com
        service_description             RootFS Disk Space
        check_command                   check_nrpe_1arg!check_rootfs_disk
        }



# Define a service to check the number of currently logged in
# users on the local machine.  Warning if > 20 users, critical
# if > 50 users.

define service{
        use                             generic-service         ; Name of service template to use
        host_name                       container.yourhost.com
        service_description             Current Users
        check_command                   check_nrpe_1arg!check_users
        }


# Define a service to check the number of currently running procs
# on the local machine.  Warning if > 250 processes, critical if
# > 400 processes.

define service{
        use                             generic-service         ; Name of service template to use
        host_name                       container.yourhost.com
        service_description             Total Processes
	check_command                   check_nrpe_1arg!check_total_procs
        }



# Define a service to check the load on the local machine. 

define service{
        use                             generic-service         ; Name of service template to use
        host_name                       container.yourhost.com
        service_description             Current Load
	check_command                   check_nrpe_1arg!check_load
        }

```

Restart nagios:

```
service nagios3 restart
```
