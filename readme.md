### Description

Script for make backup of all running virtual machines and containers on Proxmox using pvesh console tool.

The script will find all running vm's in the cluster and make a backup one by one.

Also it writes results to syslog

### Requirements

Perl with the following modules:

- Json
- Sys::Syslog
- File::Basename

### Installation

Clone repo, create `pve-backup.conf` form example (pve-backup.conf.example), run by cron on any node of the proxmox cluster.

Also, look for some usefull staff in contrib folder.
