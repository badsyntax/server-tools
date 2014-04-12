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

	if [ -z "$backupdir" ] || [ -z "$s3bucket" ] || [ -z "$zfspool" ] || [ -z "$ftpuser" ]; then
		echo "Invalid config!"
		exit 1
	fi
}

# Sync local files with s3
function backup_s3 {
	echo -n "Backing up $backupdir to s3..."
	s3cmd sync --delete-removed "$backupdir" "s3://$s3bucket/"
	if [ $? -ne 0 ]; then
		echo "s3cmd sync failed!"
		exit 1
	fi
	echo "done."
}

# Create an archived zfs snapshot of a lxc container
function backup_zfs {

	local container="$1"
	local timestamp=$(date "+%Y-%m-%d")
	local snapshot="$zfspool/$container@$timestamp"
	local backupfile="$backupdir/$container@$timestamp.gz"

	echo -n "Creating zfs snapshot: $snapshot..."
	zfs snapshot "$snapshot"
	if [ $? -ne 0 ]; then
		echo "Unable to create snapshot!"
		exit 1
	fi
	echo "done."

	if [ -e "$backupfile" ]; then
		echo "Backup file already exists: $backupfile"
	else
		echo -n "Creating data backup at location: $backupfile..."
		zfs send "$snapshot" | gzip > "$backupfile"
		if [ $? -ne 0 ]; then
			echo "Unable to create data backup!"
			exit 1
		fi
		echo "done."
	fi

	echo -n "Destroying snapshot: $snapshot..."
	zfs destroy "$snapshot"
	if [ $? -ne 0 ]; then
		echo "Unable to destroy snapshot!"
		exit 1
	fi
	echo "done."
}

# Remove backups older than 7 days
function clean_backups {
	echo -n "Cleaning up old backups at $backupdir..."
	find "$backupdir" -mtime +7 -exec rm -f {} \;
	echo "done."
}

# Umount the backup drive
function unmount_backup_drive {
	echo -n "Unmounting FTP backup drive..."
	umount "$backupdir"
	echo "done."
}

# Backup all containers by taking zfs snapshots
function backup_containers {
	echo "Backing up ZFS container snapshots at $backupdir to FTP drive..."
	for container in $(lxc-ls)
	do
		backup_zfs "$container"
		if [ $? -ne 0 ]; then
			echo "ZFS backup failed for container $container"
			exit 1
		fi
	done
}

# Mount the FTP backup drive
function mount_backup_drive {
	local ismounted=$(df -h | grep "$ftpuser")
	if [ -z "$ismounted" ]; then
		echo -n "Attempting to mount FTP backup directory..."
		sshfs -o idmap=user "$ftpuser@$ftpuser.your-backup.de:lxc/" "$backupdir"
		if [ $? -ne 0 ]; then
			echo "FTP backup directory mount failed!"
			exit 1
		fi
		echo "done."
	fi
}

function show_backup_size {
	size=$(du -h "$backupdir")
	echo "Total backup size: $size"
}

function main {
	local timestamp=$(date)
	local user=$(whoami)
	echo "Creating backup for $timestamp on $HOSTNAME."
	echo -e "Running backup script as $user.\n"
	load_config
	mount_backup_drive
	backup_containers
	show_backup_size
	backup_s3
	clean_backups
	unmount_backup_drive
	echo -e "\nAll tasks completed successfully!\n"
}
main
