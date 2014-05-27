#!/usr/bin/env bash

### ADJUST VALUE BELOW ###
# Location of .prox-server-cfg
export HOME=/root
### LEAVE THE REST UNTOUCHED ###

name="$1"
base="$2"
port="$3"

if [ "$UID" -ne 0 ]; then
        echo "Please run as root."
        exit
fi
if [ -z "$name" ] || [ -z "$base" ] || [ -z "$port" ]; then
	echo "Usage: new-container.sh <name> <base-container> <port>"
	echo "Example: ./new-container.sh richard ubuntu-lamp 2222"
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

check_base_container() {

	found=0
	for container in $(lxc-ls)
	do
		if [ "$base" = "$container" ]; then
			found=1
		fi
	done

	if [ $found -eq 0 ]; then
		echo "Base container does not exist!"
		exit 1
	fi
}

create_container() {

	lxc-create -t ubuntu -n "$name" -B zfs

	zfs send "$zfspool"/"$base"@v0.1 | zfs receive "$zfspool"/"$name" -F
	zfs destroy "$zfspool"/"$name"@v0.1
	zfs set sync=disabled "$zfspool"/"$name"
	zfs set quota=10G "$zfspool"/"$name"

	echo "lxc.start.auto = 1" >> /var/lib/"$zfspool"/"$name"/config

	lxc-start -n "$name" -d

	# give some time for the container to start and for dhcp to assign
	# and ip address.
	echo "Waiting 10s for container to start..."
	sleep 10
	
	ip=$(lxc-info -n "$name" -i | sed 's/IP:\s*//')

	echo "IP is: $ip"
	
	iptables -t nat -A PREROUTING -p tcp -d "$serverip" -j DNAT --dport "$port" --to-destination "$ip":22
	iptables-save > /etc/iptables.conf
}

check_base_container
create_container
echo "Done."
