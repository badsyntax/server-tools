#/usr/bin/env bash

command="$@"

echo -e "Containers:\n"

for container in $(lxc-ls)
do
	if [ "$container" != "ubuntu-base" ] && [ "$container" != "ubuntu-lamp" ]; then
		echo "$container"
	fi
done
echo -e "All\n"

echo -n "Enter container to run command in: "
read container

if [ "$container" = "All" ]; then
	echo "Running command '$command' in *all* containers..."	
	for container in $(lxc-ls)
	do
		if [ "$container" != "ubuntu-base" ] && [ "$container" != "ubuntu-lamp" ]; then
			echo "Running command '$command' in '$container'..."
			lxc-attach -n "$container" -- $command	
		fi
	done
else
	echo "Running command '$command' in '$container'..."
	lxc-attach -n "$container" -- $command
fi

echo "done!"
