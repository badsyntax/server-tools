# BACKUP

This backup script will create archived zfs snapshots of all lxc containers, and save them to a mounted FTP drive and Amazon S3.

### Prep:

1. Copy your keys to the FTP server, [follow these instructions](http://wiki.hetzner.de/index.php/Backup/en#FTP.2FSFTP.2FSCP).
2. Install s3cmd: `sudo apt-get install s3cmd -y`
2. Configure s3cmd: `s3cmd --configure`
3. Create a backup config file in your `$HOME` location (see below)
3. Update the `$HOME` var at the top of the `backup.sh` script file

#### Example config file:

Location: `/root/.backupcfg`

```bash
backupdir="/backup/lxc"
s3bucket="bucket-name"
zfspool="lxc"
ftpuser="uxxxxx"
```

### Backup overview:

This is the process the backup script follows:

1. Mount the FTP backup drive.
1. Get a list of containers using `lxc-ls`.
2. Create a "tagged" zfs snapshot for every container. The tag will be the date in "Y-m-d" format.
3. Send the snapshot to the backup drive as an archived file (eg: ubuntu-lamp@2014-04-10.gz)
4. Destroy the snapshot.
5. Sync the entire backup directory to amazon s3, removing deleted files.
6. Remove container archives older than 7 days from the FTP backup drive.
7. Unmount the FTP backup drive.

### Setup

You must run the `backup.sh` in the root contrab. 

Edit your crontab like so:

```bash
sudo crontab -e
```

**NOTE:** You have to specify the PATH in your crontab!

Example crontab:

```bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=your@email.com
@daily /usr/bin/time /root/bin/backup.sh
```

## Snippets

Backup and restore:

```bash
# Take backup
zfs snapshot lxc/sascha@0.1
zfs send lxc/sascha@0.1 | gzip > sascha@0.1.gz
zfs destroy lxc/sascha@0.1
# Now back a change to the sascha container
chroot /lxc/sascha/rootfs
touch /root/old
exit
# Extract and restore backup
gunzip sascha@0.1.gz
zfs receive lxc/sascha < sascha@0.1 -F
zfs destroy lxc/sascha@0.1
```
