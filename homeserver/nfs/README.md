# NFS Share Setup

This directory contains a script to easily set up NFS sharing between two Linux hosts.

## Overview

The `setup-nfs-share.sh` script automates the entire process of:
1. **Configuring the remote host as an NFS server** - installs packages, exports a directory
2. **Configuring the local host as an NFS client** - installs packages, mounts the remote share
3. **Making it persistent** - optionally adds the mount to `/etc/fstab`

## Requirements

- **SSH access** to the remote host with sudo privileges
- **Ubuntu/Debian** based systems (uses `apt-get`)
- Both hosts should be on the same network or have proper firewall rules

## Usage

```bash
./setup-nfs-share.sh
```

The script will interactively prompt you for:
- Remote host (IP or hostname)
- SSH user and port
- Remote directory to share
- Local mount point
- NFS options (with sensible defaults)

## Example Session

```
Enter remote host (IP or hostname): 192.168.1.100
Enter SSH user for remote host [default: saurabh]: 
Enter SSH port for remote host [default: 22]: 
Enter remote directory to share (on 192.168.1.100): /data/shared
Enter local mount point [default: /mnt/nfs_share]: /mnt/remote_data
```

## What It Does

### On the Remote Host (NFS Server):
1. Installs `nfs-kernel-server`
2. Creates the shared directory if it doesn't exist
3. Adds the export to `/etc/exports`
4. Exports the share and restarts the NFS server

### On the Local Host (NFS Client):
1. Installs `nfs-common`
2. Creates the local mount point
3. Mounts the remote NFS share
4. Optionally adds to `/etc/fstab` for automatic mounting on boot

## NFS Options

### Default Export Options (Server):
- `rw` - Read/write access
- `sync` - Synchronous writes
- `no_subtree_check` - Improved reliability

### Default Mount Options (Client):
- `rw` - Read/write access
- `hard` - Hard mount (retry on failure)
- `intr` - Allow interruption of NFS calls

## Firewall Requirements

Ensure the following ports are open on the NFS server:
- **TCP/UDP 111** - RPC portmapper
- **TCP/UDP 2049** - NFS service

### Opening Ports (if using UFW):
```bash
sudo ufw allow from <client-ip> to any port 111
sudo ufw allow from <client-ip> to any port 2049
```

## Useful Commands

### Check NFS Mount
```bash
df -h /mnt/nfs_share
mount | grep nfs
```

### View Server Exports
```bash
showmount -e <server-ip>
```

### Unmount
```bash
sudo umount /mnt/nfs_share
```

### Remount (if in fstab)
```bash
sudo mount /mnt/nfs_share
```

## Troubleshooting

### Mount fails with "Connection refused"
- Check if NFS server is running: `systemctl status nfs-kernel-server`
- Verify firewall settings on server
- Ensure client IP is in the exports file

### Permission denied errors
- Check directory permissions on server
- Verify export options allow your client IP
- Check if root_squash is causing issues

### Stale file handle errors
- Unmount and remount the share
- Restart NFS server: `sudo systemctl restart nfs-kernel-server`

## Removing an NFS Share

### On Client:
```bash
sudo umount /mnt/nfs_share
sudo sed -i '\|<server>:<path>|d' /etc/fstab
```

### On Server:
```bash
sudo sed -i '\|<export-path>|d' /etc/exports
sudo exportfs -ra
```

## Security Considerations

- NFS v3 (default) doesn't encrypt data - use within trusted networks
- Consider using NFS v4 with Kerberos for authentication
- Limit exports to specific IPs or networks
- Use `root_squash` to prevent root access from clients (enabled by default)

## Advanced Usage

### Custom Export Options

For read-only access:
```
Export options: ro,sync,no_subtree_check
```

For better performance (async writes):
```
Export options: rw,async,no_subtree_check
```

For specific subnet:
```
# Edit /etc/exports manually
/path/to/share  192.168.1.0/24(rw,sync,no_subtree_check)
```

## Files Modified

### On Server:
- `/etc/exports` - NFS export configuration
- Installed packages: `nfs-kernel-server`

### On Client:
- `/etc/fstab` - (optional) for persistent mounts
- Installed packages: `nfs-common`
