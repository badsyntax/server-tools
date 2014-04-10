# RESCUE

Hetzner provides a pretty handy rescue system which allows you to re-install your operating system, as well as partition your disk and setup RAID.

For our setup, we have 2 x 2TB disks. We want to use 128GB in RAID-1 for the host operation system and leave the reset unparitioned (for now).

The only changes we made to the installimage config was to change the root (/) size to 128GB and change the hostname. After saving the install image config, the rescue system will partition the disk, setup RAID-1 and install the operating system.
