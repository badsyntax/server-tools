#!/usr/bin/env bash

### ADJUST VALUE BELOW ###
# Location of .prox-monitor
export HOME=/root
### LEAVE THE REST UNTOUCHED ###

if [ "$UID" -ne 0 ]; then
	echo "Please run as root."
	exit
fi

usage() {
	echo "Usage: $0 -n <container> <-h>"
	echo "Example: $0 -n richard"
	exit 1
}

# Parse options
while getopts ":n:h:" o; do
	case "${o}" in
		n)
			opt_container=${OPTARG}
			;;
		h)
			usage
			;;
	esac
done
shift $((OPTIND-1))

if [ -z "${opt_container}" ]; then
	opt_container="all"
fi

# Check the container is valid
if [ "$opt_container" != "all" ]; then
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
fi

# Attempt to load the monitor config
configfile="$HOME/.prox-monitor"
source "$configfile"
if [ -z "$enabled_containers" ]; then
	enabled_containers=""
fi

check_container() {
	container=$1
	echo -n "$container: "
	found=0
	for enabled_container in $enabled_containers; do
		if [ "$enabled_container" = "$container" ]; then
			found=1
		fi
	done 
	if [ $found -eq 1 ]; then
		echo "enabled!"
	else
		echo "not enabled"
	fi
}

if [ "$opt_container" = "all" ]; then
	for container in $(lxc-ls)
	do
		check_container "$container"
	done
else
	check_container "$opt_container"
fi

