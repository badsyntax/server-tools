#Monitoring

## Introduction

We want to do some basic monitoring on both the host OS and the containers. Nagios is the obvious choice because it's probably
the most popular monitoring software and supports remote monitoring. We'll be using Nagios Version 3 as it's the default supported version in Ubuntu 12.04.

We don't want to install the full Nagios3 package on the host OS or containers as it has many depedencies we'd rather not install, like Apache. Instead, we're going to the use the `nagios-nrpe-server` package to run checks on the remote servers, and install the full Nagios3 web package onto a seperate machine. 

We'll be using the backup machine for installing the main nagios web package and runnng checks on the remote servers.

## Installing the nagios server within a container

```bash
sudo apt-get update
sudo apt-get install nagios-nrpe-server
```

Check that the plugins were installed:

```bash
ls -l /usr/lib/nagios/plugins/
```

## Adjusting the config

```bash
vi /etc/nagios/nrpe_local.cfg
```

Add the following, but change X.X.X.X to the ip address of the backup server. 

```
######################################
# Do any local nrpe configuration here
######################################

allowed_hosts=127.0.0.1,37.187.47.140

command[check_users]=/usr/lib/nagios/plugins/check_users -w 5 -c 10
command[check_load]=/usr/lib/nagios/plugins/check_load -w 15,10,5 -c 30,25,20
command[check_rootfs_disk]=/usr/lib/nagios/plugins/check_disk -w 20 -c 10 /
command[check_zombie_procs]=/usr/lib/nagios/plugins/check_procs -w 5 -c 10 -s Z
command[check_total_procs]=/usr/lib/nagios/plugins/check_procs -w 700 -c 900
command[check_swap]=/usr/lib/nagios/plugins/check_swap -w 20 -c 10
```

Restart the nrpe service:

```bash
service nagios-nrpe-server restart
```
