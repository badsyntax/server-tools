#server-tools

A repo to store my bash scripts and documentation for Hetzner server management. 

*This repo is not intended as a guide for others to use, but feel free to have a look around. All code is MIT licensed.*

### Goal

Here's what we'll do: 128Gb in RAID-1 for host OS. LXC with ZFS backend (mirrored pool) for everything else. Container snapshot backups to external FTP server and Amazon S3.

### Process

Let's begin!

1. rescue - Install a fresh OS host on a 125GB parition in RAID-1
2. zfs-lxc-setup - Install zfs and lxc
3. container-management - Create some containers
4. backup - Backup your containers to a mounted FTP drive and amazon s3
