#!/usr/bin/env bash

### ADJUST VALUE BELOW ###
# Location of .prox-server-cfg
export HOME=/root
### LEAVE THE REST UNTOUCHED ###

name="$1"
sshport="$2"

if [ "$UID" -ne 0 ]; then
	echo "Please run as root."
	exit
fi
if [ -z "$name" ] || [ -z "$sshport" ]; then
	echo "Usage: destroy-container.sh <container-name> <ssh-port>"
	echo "Example: ./destroy-container.sh richard 2222"
	exit 1
fi

# Attempt to load the config
configfile="$HOME/.prox-server-cfg"
if [ ! -e "$configfile" ]; then
	echo "Error: config file does not exist at location: $configfile"
	exit 1
fi
source "$configfile"
if [ -z "$serverip" ] || [ -z "$zfspool" ]; then
	echo "Invalid config!"
	exit 1
fi

# Check the container is valid
found=0
for container in $(lxc-ls)
do
	if [ "$name" = "$container" ]; then
		found=1
	fi
done
if [ $found -eq 0 ]; then
	echo "Container does not exist!"
	exit 1
fi

# Now we can destroy the container

container_ip=$(lxc-info -n "$name" -i | sed 's/IP:\s*//')

lxc-stop -n "$name"

# First lets destroy the zfs filesystem
zfs destroy "$zfspool"/"$name" -r

# Now we can destroy the container
lxc-destroy -n "$name"

# Remove the ssh port-forward rule from iptables
iptables -t nat -D PREROUTING -p tcp -d "$serverip" -j DNAT --dport "$sshport" --to-destination "$container_ip":22
iptables-save > /etc/iptables.conf

echo "Done."
