#!/bin/bash

# SSH Security Configuration Installer
# This script installs conditional SSH authentication based on source IP

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root or with sudo${NC}"
   exit 1
fi

echo -e "${BLUE}=== SSH Security Configuration Installer ===${NC}\n"

# Detect SSH config location
if [ -f "/etc/ssh/sshd_config" ]; then
    SSHD_CONFIG="/etc/ssh/sshd_config"
else
    echo -e "${RED}Error: Cannot find sshd_config${NC}"
    exit 1
fi

# Backup existing configuration
BACKUP_FILE="${SSHD_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
echo -e "${YELLOW}Creating backup...${NC}"
cp "$SSHD_CONFIG" "$BACKUP_FILE"
echo -e "${GREEN}✓ Backup created: $BACKUP_FILE${NC}\n"

# Detect LAN subnet
echo -e "${BLUE}Detecting network configuration...${NC}"
LAN_IP=$(hostname -I | awk '{print $1}')
echo -e "Your current IP: ${GREEN}$LAN_IP${NC}"

# Common subnet patterns
if [[ $LAN_IP =~ ^192\.168\.([0-9]+)\. ]]; then
    SUGGESTED_SUBNET="192.168.${BASH_REMATCH[1]}.0/24"
elif [[ $LAN_IP =~ ^10\.([0-9]+)\.([0-9]+)\. ]]; then
    SUGGESTED_SUBNET="10.${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.0/24"
elif [[ $LAN_IP =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]]; then
    SUGGESTED_SUBNET="172.${BASH_REMATCH[1]}.0.0/16"
else
    SUGGESTED_SUBNET=""
fi

echo -e "Suggested LAN subnet: ${GREEN}$SUGGESTED_SUBNET${NC}\n"

# Ask user for confirmation or custom subnet
read -p "Enter your LAN subnet (or press Enter to use $SUGGESTED_SUBNET): " USER_SUBNET
LAN_SUBNET=${USER_SUBNET:-$SUGGESTED_SUBNET}

if [ -z "$LAN_SUBNET" ]; then
    echo -e "${RED}Error: No subnet provided${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Configuration:${NC}"
echo -e "  LAN Subnet: ${GREEN}$LAN_SUBNET${NC}"
echo -e "  Password auth: ${GREEN}Allowed from LAN${NC}"
echo -e "  Key-based auth: ${GREEN}Required from external${NC}\n"

read -p "Proceed with installation? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo -e "${RED}Installation cancelled${NC}"
    exit 0
fi

# Create new configuration
echo -e "\n${YELLOW}Installing SSH configuration...${NC}"

cat > "$SSHD_CONFIG" << EOF
# SSH Server Configuration
# Enhanced security: Password auth for LAN, Key-based only for external
# Generated on $(date)

Port 22
Protocol 2

# Logging
SyslogFacility AUTH
LogLevel VERBOSE

# Authentication
LoginGraceTime 2m
PermitRootLogin no
StrictModes yes
MaxAuthTries 3
MaxSessions 10

# Public key authentication
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys2

# Default: Disable password authentication
PasswordAuthentication no
PermitEmptyPasswords no

# Challenge-response authentication
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no

# Other authentication methods
HostbasedAuthentication no
IgnoreRhosts yes

# Security features
PermitUserEnvironment no
Compression delayed
UsePAM yes
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*

# Subsystem
Subsystem sftp /usr/lib/openssh/sftp-server

# ============================================================
# CONDITIONAL AUTHENTICATION BASED ON SOURCE IP
# ============================================================

# LAN connections - Allow password authentication
Match Address $LAN_SUBNET
    PasswordAuthentication yes

# Localhost - Allow password authentication
Match Address 127.0.0.1,::1
    PasswordAuthentication yes

# External connections - Key-based only
Match Address *,!$LAN_SUBNET,!127.0.0.1,!::1
    PasswordAuthentication no
    PubkeyAuthentication yes

# Reset to defaults
Match all

EOF

# Test configuration
echo -e "\n${YELLOW}Testing SSH configuration...${NC}"
if sshd -t -f "$SSHD_CONFIG" 2>&1; then
    echo -e "${GREEN}✓ Configuration test passed${NC}\n"
else
    echo -e "${RED}✗ Configuration test failed!${NC}"
    echo -e "${YELLOW}Restoring backup...${NC}"
    cp "$BACKUP_FILE" "$SSHD_CONFIG"
    echo -e "${RED}Installation failed. Previous configuration restored.${NC}"
    exit 1
fi

# Restart SSH service
echo -e "${YELLOW}Restarting SSH service...${NC}"
if systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null || service ssh restart 2>/dev/null; then
    echo -e "${GREEN}✓ SSH service restarted successfully${NC}\n"
else
    echo -e "${RED}Warning: Could not restart SSH service automatically${NC}"
    echo -e "${YELLOW}Please restart SSH manually:${NC}"
    echo -e "  systemctl restart sshd"
    echo -e "  or: service ssh restart\n"
fi

# Summary
echo -e "${GREEN}=== Installation Complete ===${NC}\n"
echo -e "${BLUE}Configuration Summary:${NC}"
echo -e "  • Password auth enabled for: ${GREEN}$LAN_SUBNET${NC}"
echo -e "  • Key-based auth required for: ${GREEN}External connections${NC}"
echo -e "  • Backup saved to: ${YELLOW}$BACKUP_FILE${NC}\n"

echo -e "${YELLOW}Important:${NC}"
echo -e "  1. Test SSH access from LAN before logging out"
echo -e "  2. Ensure you have SSH keys set up for external access"
echo -e "  3. Check logs: ${BLUE}tail -f /var/log/auth.log${NC}\n"

echo -e "${YELLOW}To rollback:${NC}"
echo -e "  sudo cp $BACKUP_FILE $SSHD_CONFIG"
echo -e "  sudo systemctl restart sshd\n"
