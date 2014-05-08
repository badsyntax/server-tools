#!/usr/bin/env bash
#backup.sh, by Richard Willis <willis.rh@gmail.com>

### ADJUST VALUE BELOW ###
# Location of config files
export HOME=/root
### LEAVE THE REST UNTOUCHED ###

function load_config {

	local configfile="$HOME/.backupcfg"

	if [ ! -e "$configfile" ]; then
		echo "Error: backup config file does not exist at location: $configfile"
		exit 1
	fi

	source "$configfile"

	if [ -z "$ftpbackupdir" ] || [ -z "$localbackupdir" ] || [ -z "$s3bucket" ] || [ -z "$zfspool" ] || [ -z "$ftpuser" ]; then
		echo "Invalid config!"
		exit 1
	fi
}

# Sync local files with s3
function backup_s3 {
	# if it's Sunday
	local today=`date +%w`
	if [ $today = 0 ]; then
		echo -n "Backing up $localbackupdir to s3..."
		s3cmd sync --delete-removed "$localbackupdir" "s3://$s3bucket/"
		if [ $? -ne 0 ]; then
			echo "s3cmd sync failed!"
			exit 1
		fi
		echo -e "done.\n"
	fi
}

# Remove backups older than 7 days
function clean_backups {

	echo -n "Cleaning up old backups at $ftpbackupdir. Removing files older than 2 days..."
	find "$ftpbackupdir" -mtime +2 -exec rm -f {} \;
	echo "done."
	
	echo -n "Cleaning up old backups at $localbackupdir. Removing files older than 7 days..."
	find "$localbackupdir" -mtime +7 -exec rm -f {} \;
	echo "done."
}

# Umount the backup drive
function unmount_backup_drive {
	echo -n "Unmounting FTP backup drive..."
	umount "$ftpbackupdir"
	echo -e "done.\n"
}

# Create an archived zfs snapshot of a lxc container
function backup_zfs {

	local container="$1"
	local timestamp=$(date "+%Y-%m-%d")
	local snapshot="$zfspool/$container@$timestamp"
	local localbackupfile="$localbackupdir/lxc/$container@$timestamp.gz"
	local ftpbackupfile="$ftpbackupdir/lxc/$container@$timestamp.gz"

	echo -n "Creating zfs snapshot: $snapshot..."
	zfs snapshot "$snapshot"
	if [ $? -ne 0 ]; then
		echo "Unable to create snapshot!"
		exit 1
	fi
	echo "done."

	if [ -e "$localbackupfile" ]; then
		echo "Backup file already exists: $localbackupfile"
	else
		echo -n "Creating data backup at location: $localbackupfile..."
		zfs send "$snapshot" | gzip > "$localbackupfile"
		if [ $? -ne 0 ]; then
			echo "Unable to create data backup!"
			exit 1
		fi
		echo "done."
	fi

	echo -n "Copying $localbackupfile to $ftpbackupfile..."
	if [ -e "$ftpbackupfile" ]; then
		echo -n "already exists, skipping..."
	else
		cp "$localbackupfile" "$ftpbackupfile"
	fi
	echo "done."

	echo -n "Destroying snapshot: $snapshot..."
	zfs destroy "$snapshot"
	if [ $? -ne 0 ]; then
		echo "Unable to destroy snapshot!"
		exit 1
	fi
	echo -e "done.\n"
}


function backup_containers {

	echo -e "Backing up ZFS container snapshots to FTP drive mounted at $ftpbackupdir and local dir at $localbackupdir...\n"
	for container in $(lxc-ls)
	do
		backup_zfs "$container"
		if [ $? -ne 0 ]; then
			echo "ZFS backup failed for container $container"
			exit 1
		fi
	done
}

# Backup rootfs stuff
function backup_host {
	
	echo "Backing up host files to $ftpbackupdir..."
	tar -zcf "$ftpbackupdir"/etc/nginx.tar.gz /etc/nginx
	tar -zcf "$ftpbackupdir"/root.tar.gz /root
	echo "Done"
	
	echo "Backing up host files to $localbackupdir..."
	tar -zcf "$localbackupdir"/etc/nginx.tar.gz /etc/nginx
	tar -zcf "$localbackupdir"/root.tar.gz /root
	echo "Done"
}

# Mount the FTP backup drive
function mount_backup_drive {
	local ismounted=$(df -h | grep "$ftpuser")
	if [ -z "$ismounted" ]; then
		echo -n "Attempting to mount FTP backup directory..."
		sshfs -o idmap=user "$ftpuser@$ftpuser.your-backup.de:lxc/" "$ftpbackupdir"
		if [ $? -ne 0 ]; then
			echo "FTP backup directory mount failed!"
			exit 1
		fi
		echo -e "done.\n"
	fi
}

function show_backup_size {
	local ftpsize=$(du -sh "$ftpbackupdir")
	local localsize=$(du -sh "$localbackupdir")
	echo -e "\nTotal FTP backup size: $ftpsize"
	echo -e "Total local backup size: $localsize\n"
}

function show_tree {
	tree "$ftpbackupdir"
	tree "$localbackupdir"
}

function main {
	local timestamp=$(date)
	local user=$(whoami)
	echo "Creating backup for $timestamp on $HOSTNAME."
	echo -e "Running backup script as $user.\n"
	load_config
	mount_backup_drive
	clean_backups
	backup_containers
	backup_host
	show_backup_size
	backup_s3
	show_tree
	unmount_backup_drive
	echo -e "\nAll tasks completed successfully!\n"
}
main
