On the backup server, we need to mount our main server via sshfs.

First ensure you are root:

```
sudo -s
```

Install sshfs:


```
apt-get update
apt-get install sshfs
```

Create the directory where we'll mount the server:

```
mkdir /mnt/your_server
```

Example mount:

```
sshfs root@server.tld:/backup/local /mnt/your_server
```
