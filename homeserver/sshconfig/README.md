# SSH Security Configuration - Conditional Authentication

This configuration enhances SSH security by:
- **Allowing password authentication** for connections from LAN (local subnet)
- **Requiring key-based authentication** for connections from outside the LAN

## Prerequisites

- SSH server installed (OpenSSH)
- Root/sudo access to modify SSH configuration
- Knowledge of your LAN subnet (e.g., 192.168.1.0/24, 10.0.0.0/8)

## Installation

1. **Backup your current SSH configuration:**
   ```bash
   sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)
   ```

2. **Determine your LAN subnet:**
   ```bash
   ip addr show | grep "inet "
   # Or
   hostname -I
   ```

3. **Edit the configuration files:**
   - Update `sshd_config.template` with your LAN subnet
   - Apply the configuration (see below)

4. **Test the configuration before applying:**
   ```bash
   sudo sshd -t -f /etc/ssh/sshd_config
   ```

5. **Apply the configuration:**
   ```bash
   sudo cp sshd_config.template /etc/ssh/sshd_config
   sudo systemctl restart sshd
   # Or for older systems:
   # sudo service ssh restart
   ```

## Configuration Details

The configuration uses SSH's `Match` directive to apply different authentication rules based on the source IP address:

- **Match Address [LAN_SUBNET]**: Allows password authentication
- **Match Address [EXTERNAL]**: Enforces key-based authentication only

## Security Recommendations

1. **Use strong passwords** for LAN access
2. **Set up fail2ban** to prevent brute force attacks
3. **Regularly audit SSH access logs** (`/var/log/auth.log`)
4. **Consider using 2FA** even for LAN access
5. **Keep SSH updated** to the latest version

## Testing

### From LAN:
```bash
# Should allow password authentication
ssh user@your-server-ip
```

### From External Network:
```bash
# Should require SSH key
ssh -i ~/.ssh/id_rsa user@your-server-ip
```

## Troubleshooting

### Check SSH service status:
```bash
sudo systemctl status sshd
```

### View SSH logs:
```bash
sudo tail -f /var/log/auth.log
# Or on some systems:
sudo journalctl -u sshd -f
```

### Test configuration syntax:
```bash
sudo sshd -t
```

### Verbose SSH connection for debugging:
```bash
ssh -vvv user@host
```

## Common LAN Subnets

- `192.168.0.0/24` - Common home network (192.168.0.1-254)
- `192.168.1.0/24` - Common home network (192.168.1.1-254)
- `10.0.0.0/8` - Large private network
- `172.16.0.0/12` - Medium private network

## Rollback

If something goes wrong:
```bash
sudo cp /etc/ssh/sshd_config.backup.[DATE] /etc/ssh/sshd_config
sudo systemctl restart sshd
```

## Additional Security Layers

Consider implementing these additional security measures:

1. **Port Knocking**: Hide SSH port until a sequence is sent
2. **VPN**: Require VPN connection for external access
3. **Firewall Rules**: Use iptables/ufw to restrict SSH access
4. **SSH Bastion/Jump Host**: Central access point for external connections

## Files in This Directory

- `sshd_config.template` - Main SSH configuration template
- `install.sh` - Automated installation script
- `setup-fail2ban.sh` - Optional fail2ban setup for brute force protection
- `test-ssh-config.sh` - Testing script to validate configuration
- `README.md` - This file
