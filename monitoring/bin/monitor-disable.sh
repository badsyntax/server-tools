#!/usr/bin/env bash

### ADJUST VALUE BELOW ###
# Location of .prox-server-cfg
export HOME=/root
### LEAVE THE REST UNTOUCHED ###

if [ "$UID" -ne 0 ]; then
	echo "Please run as root."
	exit
fi

usage() {
	echo "Usage: $0 -n <container> -p <port>"
	echo "Example: $0 -n richard -p 5667"
	exit 1
}

# Parse options
while getopts ":n:h:p:" o; do
	case "${o}" in
		n)
			opt_container=${OPTARG}
			;;
		p)
			opt_port=${OPTARG}
			;;
		h)
			usage
			;;
		*)
			usage
			;;
	esac
done
shift $((OPTIND-1))

if [ -z "${opt_container}" ] || [ -z "${opt_port}" ]; then
	usage
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
monitor_configfile="$HOME/.prox-monitor"
source "$monitor_configfile"
if [ -z "$enabled_containers" ]; then
        enabled_containers=""
fi

# Check the container is valid
found=0
for container in $(lxc-ls)
do
	if [ "$opt_container" = "$container" ]; then
		found=1
	fi
done
if [ $found -eq 0 ]; then
	echo "Container does not exist!"
	exit 1
fi

# Remove the nrpe package
package="nagios-nrpe-server"
lxc-run-command.sh -n "$opt_container" -c "apt-get remove -y $package"
if [ $? -ne 0 ]; then
	echo "Unable to remove package $package in container $opt_container"
	exit 1
fi

echo "Removing port forward rule to iptables..."
container_ip=$(lxc-info -n "$opt_container" -i | sed 's/IP:\s*//')
iptables -t nat -D PREROUTING -p tcp -d "$serverip" -j DNAT --dport "$opt_port" --to-destination "$container_ip":5666
iptables-save > /etc/iptables.conf

# Re-generate the .prox-monitor config
_enabled_containers=""
for enabled_container in $enabled_containers; do
	if [ "$enabled_container" != "$opt_container" ]; then
		_enabled_containers=" $_enabled_containers $enabled_container"
	fi
done
_enabled_containers=$(echo "$_enabled_containers" | sed 's/^ *//g')
_enabled_containers="enabled_containers=\"$_enabled_containers\""
echo "$_enabled_containers" > "$monitor_configfile" 

echo "Done."
