#server-tools

A repo to store my bash scripts and documentation for Hetzner server management. 

*This repo is not intended as a guide for others to use, but feel free to have a look around. Unless otherwise stated, all code is Public Domain.*

## Server specs

* Intel ® Core™ i7-4770 Quadcore Haswell incl. Hyper-Threading Technology
* RAM: 32 GB DDR3 RAM
* Hard Drive2 x 2 TB SATA 6 Gb/s 7200 rpm HDD
* Backup space: 100 GB

## Goal

128Gb in RAID-1 for host OS (Ubuntu 12.04). LXC with ZFS backend (mirrored pool) for everything else. Container snapshot backups to external FTP server and Amazon S3. Easy snapshot restore.

## Process

Let's begin!

1. rescue - Install a fresh OS host on a 125GB parition in RAID-1
2. zfs-lxc-setup - Install zfs and lxc
3. securing-host-os - Secure the host operating system
3. container-management - Create some containers
4. securing-containers - Secure the containers
5. monitoring - Setup monitoring of the host and containers
6. backup - Backup your containers to a mounted FTP drive and amazon s3
7. restore - Restore your archived containers
8. migrate - Migrate your data from another server into your containers
