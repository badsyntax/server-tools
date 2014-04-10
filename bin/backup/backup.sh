#/usr/bin/env bash

# NOTE: intended to be run as root

backupdir="/backup/lxc"
s3bucket="your-bucket-name"
zfspool="lxc"

path="${BASH_SOURCE[0]}"
cwd=$(dirname "$path")

# Backup the zfs containers to the FTP drive
echo "Backing up ZFS container snapshots at $backupdir to FTP drive"
for container in $(lxc-ls)
do
	"$cwd"/zfs.sh "$backupdir" "$zfspool" "$container"
	if [ $? -ne 0 ]; then
		echo "ZFS backup failed for container $container"
		exit $?
	fi
done

# Backup the containers to S3
echo "Backing up $backupdir to s3..."
"$cwd"/s3.sh "$backupdir" "$s3bucket"
if [ $? -ne 0 ]; then
        echo "s3 backup failed"
        exit $?
fi

# Removing backups older than 7 days...
echo "Cleaning up old backups at $backupdir..."
find "$backupdir" -mtime +7 -exec rm -f {} \;

echo "Done!"

