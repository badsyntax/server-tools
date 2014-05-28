#/usr/bin/env bash

if [ "$UID" -ne 0 ]; then
	echo "Please run as root."
	exit
fi

usage() {
	echo "Usage: $0 -n <container> -c <command>"
	echo "Example: $0 -n richard -c apt-get update"
	exit 1
}

# Parse options
while getopts ":n:c:" o; do
	case "${o}" in
		n)
			opt_container=${OPTARG}
			;;
		c)
			opt_command=${OPTARG}
			;;
		*)
			usage
			;;
	esac
done
shift $((OPTIND-1))

if [ -z "${opt_container}" ] || [ -z "${opt_command}" ]; then
	usage
fi

if [ "$opt_container" != "all" ]; then
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
fi

if [ "$opt_container" = "all" ]; then
	echo "Running command '$opt_command' in *all* containers..."	
	for container in $(lxc-ls)
	do
		if [ "$container" != "ubuntu-base" ] && [ "$container" != "ubuntu-lamp" ]; then
			echo "Running command '$opt_command' in '$container'..."
			lxc-attach -n "$container" -- $opt_command	
		fi
	done
else
	echo "Running command '$opt_command' in '$opt_container'..."
	lxc-attach -n "$opt_container" -- $opt_command
fi

echo "Done."
