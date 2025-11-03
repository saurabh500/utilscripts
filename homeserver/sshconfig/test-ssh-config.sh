#!/bin/bash

# SSH Configuration Testing Script
# Tests the conditional authentication setup

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== SSH Configuration Test ===${NC}\n"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${YELLOW}Note: Running as root. Some tests might not reflect user experience.${NC}\n"
fi

# Test 1: Check SSH service status
echo -e "${YELLOW}[1/5] Checking SSH service status...${NC}"
if systemctl is-active --quiet sshd || systemctl is-active --quiet ssh; then
    echo -e "${GREEN}✓ SSH service is running${NC}\n"
else
    echo -e "${RED}✗ SSH service is not running${NC}"
    echo -e "${YELLOW}Start with: sudo systemctl start sshd${NC}\n"
fi

# Test 2: Validate SSH configuration syntax
echo -e "${YELLOW}[2/5] Validating SSH configuration syntax...${NC}"
if sudo sshd -t 2>&1; then
    echo -e "${GREEN}✓ Configuration syntax is valid${NC}\n"
else
    echo -e "${RED}✗ Configuration has syntax errors${NC}\n"
fi

# Test 3: Check for Match directives
echo -e "${YELLOW}[3/5] Checking for conditional authentication rules...${NC}"
if sudo grep -q "Match Address" /etc/ssh/sshd_config; then
    echo -e "${GREEN}✓ Found Match Address directives${NC}"
    sudo grep "Match Address" /etc/ssh/sshd_config | while read line; do
        echo -e "  ${BLUE}$line${NC}"
    done
    echo ""
else
    echo -e "${RED}✗ No Match Address directives found${NC}"
    echo -e "${YELLOW}The conditional authentication may not be configured${NC}\n"
fi

# Test 4: Check current network configuration
echo -e "${YELLOW}[4/5] Checking network configuration...${NC}"
echo -e "Current IP addresses:"
ip addr show | grep "inet " | grep -v "127.0.0.1" | awk '{print "  " $2}' | while read ip; do
    echo -e "  ${GREEN}$ip${NC}"
done
echo ""

# Test 5: Display effective configuration for different sources
echo -e "${YELLOW}[5/5] Checking authentication settings...${NC}"

# Check default PasswordAuthentication
DEFAULT_PWD=$(sudo grep -E "^PasswordAuthentication" /etc/ssh/sshd_config | head -1 | awk '{print $2}')
echo -e "Default PasswordAuthentication: ${BLUE}${DEFAULT_PWD:-not set}${NC}"

# Check PubkeyAuthentication
PUBKEY=$(sudo grep -E "^PubkeyAuthentication" /etc/ssh/sshd_config | head -1 | awk '{print $2}')
echo -e "PubkeyAuthentication: ${BLUE}${PUBKEY:-not set}${NC}\n"

# Test localhost connection (if available)
echo -e "${YELLOW}Testing localhost SSH connection...${NC}"
echo -e "${BLUE}Attempting to test SSH authentication methods on localhost...${NC}"

# Use ssh with verbose output to check available auth methods
timeout 5 ssh -v -o PreferredAuthentications=password -o PubkeyAuthentication=no \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    localhost echo "test" 2>&1 | grep -i "authentications that can continue" || true

echo ""

# Summary and recommendations
echo -e "${GREEN}=== Test Summary ===${NC}\n"

echo -e "${YELLOW}Configuration Files:${NC}"
echo -e "  Main config: ${BLUE}/etc/ssh/sshd_config${NC}"
echo -e "  Logs: ${BLUE}/var/log/auth.log${NC} or ${BLUE}journalctl -u sshd${NC}\n"

echo -e "${YELLOW}Testing from another machine:${NC}"
echo -e "  From LAN:     ${BLUE}ssh -v username@$(hostname -I | awk '{print $1}')${NC}"
echo -e "  With key:     ${BLUE}ssh -i ~/.ssh/id_rsa username@$(hostname -I | awk '{print $1}')${NC}\n"

echo -e "${YELLOW}View current SSH sessions:${NC}"
echo -e "  ${BLUE}who${NC} or ${BLUE}w${NC}\n"

echo -e "${YELLOW}Monitor SSH authentication attempts:${NC}"
echo -e "  ${BLUE}sudo tail -f /var/log/auth.log | grep sshd${NC}\n"

echo -e "${YELLOW}Check Match rules:${NC}"
echo -e "  ${BLUE}sudo grep -A 2 'Match Address' /etc/ssh/sshd_config${NC}\n"

echo -e "${GREEN}Testing complete!${NC}\n"
