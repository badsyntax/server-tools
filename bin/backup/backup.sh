#/usr/bin/env bash

# NOTE: this script should be run by cron as root user

backupdir="/backup/lxc"
s3bucket="bucket-name"
zfspool="lxc"
ftpuser="username"
ismounted=$(df -h | grep "$ftpuser")

# Ensure FTP backup directory is mounted
if [ -z "$ismounted" ]; then
        echo "Attempting to mount FTP backup directory"
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
	/root/bin/backup/zfs.sh "$backupdir" "$zfspool" "$container"
	if [ $? -ne 0 ]; then
		echo "ZFS backup failed for container $container"
		exit $?
	fi
done

# Backup the containers to S3
echo "Backing up $backupdir to s3..."
/root/bin/backup/s3.sh "$backupdir" "$s3bucket"
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
