#!/bin/bash

# K3s Master Node Setup Script
# This script installs K3s on the master node and sets up node labels

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
MASTER_IP=$(hostname -I | awk '{print $1}')
NODE_LABELS="${NODE_LABELS:-}"
NODE_NAME="${NODE_NAME:-$(hostname)}"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "          K3s Master Node Setup"
echo "═══════════════════════════════════════════════════════"
echo ""

print_info "Master IP: $MASTER_IP"
print_info "Node Name: $NODE_NAME"
print_info "Node Labels: ${NODE_LABELS:-none}"
echo ""

read -p "Proceed with K3s master installation? [y/N]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Installation cancelled"
    exit 0
fi

# Check if K3s is already installed
if command -v k3s &> /dev/null; then
    print_warning "K3s is already installed"
    read -p "Reinstall? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Uninstalling existing K3s..."
        /usr/local/bin/k3s-uninstall.sh || true
    else
        print_info "Skipping installation"
        exit 0
    fi
fi

# Install K3s master
print_info "Installing K3s master node..."

curl -sfL https://get.k3s.io | sh -s - server \
    --write-kubeconfig-mode 644 \
    --node-name "$NODE_NAME" \
    ${NODE_LABELS:+--node-label "$NODE_LABELS"}

# Wait for K3s to be ready
print_info "Waiting for K3s to be ready..."
sleep 10

# Check K3s status
if systemctl is-active --quiet k3s; then
    print_success "K3s master is running"
else
    print_error "K3s failed to start"
    systemctl status k3s
    exit 1
fi

# Get node token for workers
print_info "Retrieving node token..."
NODE_TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)

# Setup kubectl alias
if ! grep -q "alias kubectl=" ~/.bashrc; then
    echo "alias kubectl='k3s kubectl'" >> ~/.bashrc
    print_info "Added kubectl alias to ~/.bashrc"
fi

# Create token file for workers
TOKEN_FILE="$(dirname "$0")/k3s-token.txt"
echo "$NODE_TOKEN" > "$TOKEN_FILE"
chmod 600 "$TOKEN_FILE"

# Display cluster info
echo ""
echo "═══════════════════════════════════════════════════════"
print_success "K3s Master Installation Complete!"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Cluster Information:"
echo "  Master IP:    $MASTER_IP"
echo "  Node Name:    $NODE_NAME"
echo "  Token saved:  $TOKEN_FILE"
echo ""
echo "To add worker nodes, use:"
echo "  NODE_NAME=<name> NODE_LABELS=<labels> MASTER_IP=$MASTER_IP ./setup-k3s-worker.sh"
echo ""
echo "Node Token (save this securely):"
echo "$NODE_TOKEN"
echo ""
echo "Useful commands:"
echo "  - View nodes:     k3s kubectl get nodes -o wide"
echo "  - View pods:      k3s kubectl get pods -A"
echo "  - Node details:   k3s kubectl describe node $NODE_NAME"
echo "  - Add labels:     k3s kubectl label node <node-name> key=value"
echo ""

# Apply node labels if provided
if [ -n "$NODE_LABELS" ]; then
    print_info "Applying node labels..."
    sleep 5
    IFS=',' read -ra LABELS <<< "$NODE_LABELS"
    for label in "${LABELS[@]}"; do
        k3s kubectl label node "$NODE_NAME" "$label" --overwrite
        print_success "Applied label: $label"
    done
fi

# Show current nodes
echo "Current cluster nodes:"
k3s kubectl get nodes -o wide

echo ""
print_success "Setup complete! Run 'source ~/.bashrc' to use kubectl alias"
