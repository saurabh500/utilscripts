#!/bin/bash

# Script to manage node labels in K3s cluster

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

KUBECTL="k3s kubectl"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "          K3s Node Label Manager"
echo "═══════════════════════════════════════════════════════"
echo ""

# Check if K3s is installed
if ! command -v k3s &> /dev/null; then
    print_warning "K3s is not installed on this system"
    exit 1
fi

# Show current nodes
print_info "Current nodes in cluster:"
$KUBECTL get nodes -o wide
echo ""

# Menu
echo "What would you like to do?"
echo "1. Add label to node"
echo "2. Remove label from node"
echo "3. Show node labels"
echo "4. List nodes by label"
echo "5. Exit"
echo ""

read -p "Choose option [1-5]: " OPTION

case $OPTION in
    1)
        # Add label
        read -p "Enter node name: " NODE_NAME
        read -p "Enter label key: " LABEL_KEY
        read -p "Enter label value: " LABEL_VALUE
        
        print_info "Adding label $LABEL_KEY=$LABEL_VALUE to node $NODE_NAME..."
        $KUBECTL label node "$NODE_NAME" "$LABEL_KEY=$LABEL_VALUE" --overwrite
        print_success "Label added successfully"
        
        echo ""
        print_info "Updated node labels:"
        $KUBECTL get node "$NODE_NAME" --show-labels
        ;;
        
    2)
        # Remove label
        read -p "Enter node name: " NODE_NAME
        read -p "Enter label key to remove: " LABEL_KEY
        
        print_info "Removing label $LABEL_KEY from node $NODE_NAME..."
        $KUBECTL label node "$NODE_NAME" "$LABEL_KEY-"
        print_success "Label removed successfully"
        
        echo ""
        print_info "Updated node labels:"
        $KUBECTL get node "$NODE_NAME" --show-labels
        ;;
        
    3)
        # Show labels
        read -p "Enter node name (or 'all' for all nodes): " NODE_NAME
        
        if [ "$NODE_NAME" = "all" ]; then
            $KUBECTL get nodes --show-labels
        else
            $KUBECTL describe node "$NODE_NAME" | grep -A 10 "Labels:"
        fi
        ;;
        
    4)
        # List by label
        read -p "Enter label selector (e.g., purpose=plex): " LABEL_SELECTOR
        
        print_info "Nodes matching label $LABEL_SELECTOR:"
        $KUBECTL get nodes -l "$LABEL_SELECTOR" -o wide
        ;;
        
    5)
        print_info "Exiting..."
        exit 0
        ;;
        
    *)
        print_warning "Invalid option"
        exit 1
        ;;
esac

echo ""
print_success "Operation complete!"
