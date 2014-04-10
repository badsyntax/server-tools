#/usr/bin/env bash

# NOTE: intended to be run as root

backupdir="$1"
pool="$2"
container="$3"

if [ -z "$backupdir" ] || [ -z "$pool" ] || [ -z "$container" ]; then
        echo "Usage: zfs.sh <backup-directory> <zfs-pool> <lxc-container-name>"
        exit 1
fi

if [ ! -e "$backupdir" ]; then
        echo "Invalid directory, please ensure the directory exists"
        exit 1
fi

timestamp=$(date "+%Y-%m-%d")
snapshot="$pool/$container@$timestamp"
backupfile="$backupdir/$container@$timestamp.gz"

ftpuser="username"
ismounted=$(df -h | grep "$ftpuser")

if [ -z "$ismounted" ]; then
	echo "Attempting to mount FTP backup directory"
	sshfs -o idmap=user "$ftpuser@$ftpuser.your-backup.de:lxc/" "$backupdir"
	if [ $? -ne 0 ]; then
		echo "FTP backup directory mount failed!"
		exit 1
	fi
fi

echo "Creating zfs snapshot: $snapshot..."
zfs snapshot "$snapshot"
if [ $? -ne 0 ]; then
	echo "Unable to create snapshot!"
	exit 1
fi

if [ ! -e "$backupfile" ]; then
	echo "Creating data backup at location: $backupfile..."
	zfs send "$snapshot" | gzip > "$backupfile"
	if [ $? -ne 0 ]; then
		echo "Unable to create data backup!"
		exit 1
	fi
else
	echo "Backup file already exists: $backupfile"
fi

echo "Destroying snapshot: $snapshot..."
zfs destroy "$snapshot"
if [ $? -ne 0 ]; then
	echo "Unable to destroy snapshot!"
	exit 1
fi
