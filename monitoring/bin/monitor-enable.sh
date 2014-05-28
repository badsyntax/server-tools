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

# Check if we haven't already enabled monitoring
for enabled_container in $enabled_containers; do
	if [ "$enabled_container" = "$opt_container" ]; then
		if [ $found -eq 1 ]; then
			echo "Monitoring for this container has already been enabled."
			exit 1
		fi
	fi
done

# Install the nrpe package
package="nagios-nrpe-server"
lxc-run-command.sh -n "$opt_container" -c "apt-get install $package"
if [ $? -ne 0 ]; then
	echo "Unable to install package $package in container $opt_container"
	exit 1
fi

# Update nagios nrpe config
nrpe_local_path="/var/lib/lxc/$opt_container/rootfs/etc/nagios/nrpe_local.cfg"
bridge_ip="10.0.3.1"
if [[ ! -f "$nrpe_local_path" ]]; then
	echo "Error: File not found: $nrpe_local_path"
	exit 1
fi

echo "Updating nagios nrpe config..."

cat <<EOF > "$nrpe_local_path"
######################################
# Do any local nrpe configuration here
######################################

allowed_hosts=127.0.0.1,$bridge_ip
dont_blame_nrpe=1

command[check_users]=/usr/lib/nagios/plugins/check_users -w 5 -c 10
command[check_load]=/usr/lib/nagios/plugins/check_load -w 15,10,5 -c 30,25,20
command[check_rootfs_disk]=/usr/lib/nagios/plugins/check_disk -w 20 -c 10 /
command[check_zombie_procs]=/usr/lib/nagios/plugins/check_procs -w 5 -c 10 -s Z
command[check_total_procs]=/usr/lib/nagios/plugins/check_procs -w 150 -c 200
command[check_swap]=/usr/lib/nagios/plugins/check_swap -w 20 -c 10
command[check_apt]=/usr/lib/nagios/plugins/check_apt
command[check_smtp]=/usr/lib/nagios/plugins/check_smtp -H localhost
command[check_http]=/usr/lib/nagios/plugins/check_http -H localhost
command[check_http_domain]=/usr/lib/nagios/plugins/check_http -H \$ARG1\$ -u /
EOF

# Reload the nrpe server
lxc-run-command.sh -n "$opt_container" -c "service nagios-nrpe-server restart"

echo "Adding port forward rule to iptables..."
container_ip=$(lxc-info -n "$opt_container" -i | sed 's/IP:\s*//')
iptables -t nat -A PREROUTING -p tcp -d "$serverip" -j DNAT --dport "$opt_port" --to-destination "$container_ip":5666
iptables-save > /etc/iptables.conf

echo "Nagios remote daemon for container $opt_container with ip $container_ip listening on port $opt_port on host with ip $serverip..."
echo "Updating config..."

# Re-generate the .prox-monitor config
_enabled_containers=""
for enabled_container in $enabled_containers; do
	 _enabled_containers=" $_enabled_containers$enabled_container"
done
_enabled_containers=" $_enabled_containers$opt_container"
_enabled_containers=$(echo "$_enabled_containers" | sed 's/^ *//g')
_enabled_containers="enabled_containers=\"$_enabled_containers\""
echo "$_enabled_containers" > "$monitor_configfile"

echo "Done."
