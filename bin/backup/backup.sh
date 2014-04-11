#/usr/bin/env bash
# Written by Richard Willis <willis.rh@gmail.com>

# NOTE: this script should be run by cron as root user

### ADJUST VALUE BELOW ############################################

# We read config files (both s3 and this script) from this HOME directory.
export HOME=/root

### LEAVE THE REST UNTOUCHED ######################################

configfile="$HOME/.backupcfg"

if [ ! -e "$configfile" ]; then
	echo "Error: backup config file does not exist at location: $configfile"
	exit 1
fi

source "$configfile"

backupdir="$backup_conf_backupdir"
s3bucket="$backup_conf_s3bucket"
zfspool="$backup_conf_zfspool"
ftpuser="$backup_conf_ftpuser"
ismounted=$(df -h | grep "$ftpuser")

function backup_s3 {
	s3cmd sync --delete-removed "$backupdir" "s3://$s3bucket/"
	if [ $? -ne 0 ]; then
		echo "s3cmd sync failed!"
		exit 1
	fi
}

function backup_zfs {

	local container="$1"
	local timestamp=$(date "+%Y-%m-%d")
	local snapshot="$zfspool/$container@$timestamp"
	local backupfile="$backupdir/$container@$timestamp.gz"

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
}

# Ensure FTP backup directory is mounted
if [ -z "$ismounted" ]; then
        echo "Attempting to mount FTP backup directory..."
        sshfs -o idmap=user "$ftpuser@$ftpuser.your-backup.de:lxc/" "$backupdir"
        if [ $? -ne 0 ]; then
                echo "FTP backup directory mount failed!"
                exit 1
        fi
fi

# Backup the zfs containers to the FTP drive
echo "Backing up ZFS container snapshots at $backupdir to FTP drive"
for container in $(lxc-ls)
do
	backup_zfs "$container"
	if [ $? -ne 0 ]; then
		echo "ZFS backup failed for container $container"
		exit $?
	fi
done

size=$(du -h "$backupdir")
echo "Total backup size: $size"

# Backup the containers to S3
echo "Backing up $backupdir to s3..."
backup_s3 "$backupdir" "$s3bucket"
if [ $? -ne 0 ]; then
        echo "s3 backup failed"
        exit $?
fi

# Remove backups older than 7 days...
echo "Cleaning up old backups at $backupdir..."
find "$backupdir" -mtime +7 -exec rm -f {} \;

# Umount FTP backup drive
echo "Unmounting FTP backup drive..."
umount "$backupdir"

echo "Done!"
