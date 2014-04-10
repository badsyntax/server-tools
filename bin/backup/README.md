# BACKUP

You must run the `backup.sh` in the root contrab.

Edit your crontab like so:

```bash
sudo crontab -e
```

Example crontab:

```
MAILTO=willis.rh@gmail.com
@daily /root/bin/backup/backup.sh
```
