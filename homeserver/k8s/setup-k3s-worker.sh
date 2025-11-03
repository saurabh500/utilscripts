#!/bin/bash

# K3s Worker Node Setup Script
# This script joins a worker node to an existing K3s cluster

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

# Configuration
MASTER_IP="${MASTER_IP:-}"
NODE_TOKEN="${NODE_TOKEN:-}"
NODE_LABELS="${NODE_LABELS:-}"
NODE_NAME="${NODE_NAME:-$(hostname)}"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "          K3s Worker Node Setup"
echo "═══════════════════════════════════════════════════════"
echo ""

# Prompt for master IP if not provided
if [ -z "$MASTER_IP" ]; then
    read -p "Enter K3s master IP address: " MASTER_IP
fi

# Prompt for node token if not provided
if [ -z "$NODE_TOKEN" ]; then
    read -p "Enter K3s node token: " NODE_TOKEN
fi

# Prompt for node name
read -p "Enter node name [default: $NODE_NAME]: " INPUT_NAME
NODE_NAME="${INPUT_NAME:-$NODE_NAME}"

# Prompt for labels
if [ -z "$NODE_LABELS" ]; then
    echo ""
    echo "Enter node labels (comma-separated, e.g., purpose=plex,type=pi)"
    read -p "Labels: " NODE_LABELS
fi

echo ""
print_info "Configuration:"
print_info "  Master IP: $MASTER_IP"
print_info "  Node Name: $NODE_NAME"
print_info "  Labels: ${NODE_LABELS:-none}"
echo ""

read -p "Proceed with worker node installation? [y/N]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Installation cancelled"
    exit 0
fi

# Check if K3s is already installed
if command -v k3s &> /dev/null; then
    print_warning "K3s is already installed on this node"
    read -p "Reinstall? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Uninstalling existing K3s..."
        /usr/local/bin/k3s-agent-uninstall.sh || /usr/local/bin/k3s-uninstall.sh || true
    else
        print_info "Skipping installation"
        exit 0
    fi
fi

# Test connectivity to master
print_info "Testing connectivity to master..."
if ! ping -c 1 -W 2 "$MASTER_IP" &> /dev/null; then
    print_error "Cannot reach master at $MASTER_IP"
    exit 1
fi
print_success "Master is reachable"

# Install K3s worker
print_info "Installing K3s worker node..."

curl -sfL https://get.k3s.io | K3S_URL="https://$MASTER_IP:6443" \
    K3S_TOKEN="$NODE_TOKEN" \
    sh -s - agent \
    --node-name "$NODE_NAME" \
    ${NODE_LABELS:+--node-label "$NODE_LABELS"}

# Wait for K3s agent to be ready
print_info "Waiting for K3s agent to be ready..."
sleep 10

# Check K3s agent status
if systemctl is-active --quiet k3s-agent; then
    print_success "K3s agent is running"
else
    print_error "K3s agent failed to start"
    systemctl status k3s-agent
    exit 1
fi

echo ""
echo "═══════════════════════════════════════════════════════"
print_success "K3s Worker Node Installation Complete!"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Node Information:"
echo "  Master IP:    $MASTER_IP"
echo "  Node Name:    $NODE_NAME"
echo "  Labels:       ${NODE_LABELS:-none}"
echo ""
echo "Check node status on master:"
echo "  k3s kubectl get nodes"
echo "  k3s kubectl describe node $NODE_NAME"
echo ""

print_info "This worker node has joined the cluster!"
print_info "Run 'k3s kubectl get nodes' on the master to verify"
