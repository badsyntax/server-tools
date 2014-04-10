# BACKUP

This backup script will safe zfs snapshots (that should lxc containers) to a mounted FTP drive, and then
sync with amazon s3.

Prep:

Copy your keys to the FTP server, following these instructions: http://wiki.hetzner.de/index.php/Backup/en#FTP.2FSFTP.2FSCP

Backup overview:

1. Mount the FTP backup drive if it hasn't been mounted.
1. Get a list of containers using `lxc-ls`.
2. Create a "tagged" zfs snapshot for every container. The tag will be the date in "Y-m-d" format.
3. Send the snapshot to the backup drive as an archived file (eg: 

You must run the `backup.sh` in the root contrab. 

Edit your crontab like so:

```bash
sudo crontab -e
```

Example crontab:

```
MAILTO=your@email.com
@daily /root/bin/backup/backup.sh
```

If you want to run the script outside of the crontab, you need to be sudo'd as root:

Like so:

```bash
sudo -s
./backup.sh
```

This will not work: `sudo ./backup.sh`

