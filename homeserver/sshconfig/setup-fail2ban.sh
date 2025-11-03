#!/bin/bash

# Fail2ban Setup Script for SSH Protection
# Protects against brute force attacks

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root or with sudo${NC}"
   exit 1
fi

echo -e "${BLUE}=== Fail2ban Setup for SSH Protection ===${NC}\n"

# Check if fail2ban is installed
if ! command -v fail2ban-client &> /dev/null; then
    echo -e "${YELLOW}Fail2ban not found. Installing...${NC}"
    
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y fail2ban
    elif command -v yum &> /dev/null; then
        yum install -y fail2ban
    elif command -v dnf &> /dev/null; then
        dnf install -y fail2ban
    else
        echo -e "${RED}Cannot detect package manager. Please install fail2ban manually.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Fail2ban installed${NC}\n"
else
    echo -e "${GREEN}✓ Fail2ban already installed${NC}\n"
fi

# Create jail.local configuration
echo -e "${YELLOW}Configuring fail2ban for SSH...${NC}"

cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
# Ban hosts for 1 hour (3600 seconds)
bantime = 3600

# A host is banned if it has generated "maxretry" during the last "findtime"
findtime = 600

# Number of failures before a host get banned
maxretry = 5

# Destination email for ban notifications (optional)
# destemail = your-email@example.com
# sendername = Fail2Ban
# mta = sendmail

# Action to take (ban and optionally send email)
action = %(action_)s
# For email notifications, use: %(action_mwl)s

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
# For CentOS/RHEL/Fedora, use:
# logpath = /var/log/secure
maxretry = 3
bantime = 3600
findtime = 600

EOF

# Test fail2ban configuration
echo -e "\n${YELLOW}Testing fail2ban configuration...${NC}"
if fail2ban-client -t 2>&1; then
    echo -e "${GREEN}✓ Configuration test passed${NC}\n"
else
    echo -e "${RED}✗ Configuration test failed!${NC}"
    exit 1
fi

# Enable and start fail2ban
echo -e "${YELLOW}Starting fail2ban service...${NC}"
systemctl enable fail2ban
systemctl restart fail2ban

echo -e "${GREEN}✓ Fail2ban service started${NC}\n"

# Show status
echo -e "${GREEN}=== Fail2ban Setup Complete ===${NC}\n"

echo -e "${BLUE}Current Status:${NC}"
fail2ban-client status sshd

echo -e "\n${YELLOW}Useful Commands:${NC}"
echo -e "  Check status:          ${BLUE}sudo fail2ban-client status sshd${NC}"
echo -e "  Unban an IP:          ${BLUE}sudo fail2ban-client set sshd unbanip IP_ADDRESS${NC}"
echo -e "  View banned IPs:      ${BLUE}sudo fail2ban-client get sshd banip${NC}"
echo -e "  Check logs:           ${BLUE}sudo tail -f /var/log/fail2ban.log${NC}\n"

echo -e "${GREEN}SSH is now protected against brute force attacks!${NC}\n"
