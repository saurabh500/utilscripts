#!/bin/bash

# NFS Share Setup Script
# This script sets up NFS sharing between two hosts:
# 1. Configures the remote host as NFS server (exports a directory)
# 2. Configures the local host as NFS client (mounts the remote directory)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
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

# --- Collect Information ---
echo ""
echo "═══════════════════════════════════════════════════════"
echo "          NFS Share Setup Script"
echo "═══════════════════════════════════════════════════════"
echo ""

# Remote host information
read -p "Enter remote host (IP or hostname): " REMOTE_HOST
if [ -z "$REMOTE_HOST" ]; then
    print_error "Remote host cannot be empty"
    exit 1
fi

read -p "Enter SSH user for remote host [default: $USER]: " REMOTE_USER
REMOTE_USER=${REMOTE_USER:-$USER}

read -p "Enter SSH port for remote host [default: 22]: " SSH_PORT
SSH_PORT=${SSH_PORT:-22}

# Remote directory to share
read -p "Enter remote directory to share (on $REMOTE_HOST): " REMOTE_DIR
if [ -z "$REMOTE_DIR" ]; then
    print_error "Remote directory cannot be empty"
    exit 1
fi

# Local mount point
read -p "Enter local mount point [default: /mnt/nfs_share]: " LOCAL_MOUNT
LOCAL_MOUNT=${LOCAL_MOUNT:-/mnt/nfs_share}

# NFS options
read -p "Enter NFS export options [default: rw,sync,no_subtree_check]: " NFS_EXPORT_OPTS
NFS_EXPORT_OPTS=${NFS_EXPORT_OPTS:-rw,sync,no_subtree_check}

read -p "Enter NFS mount options [default: rw,hard,intr]: " NFS_MOUNT_OPTS
NFS_MOUNT_OPTS=${NFS_MOUNT_OPTS:-rw,hard,intr}

# Get local IP for NFS exports
print_info "Detecting local IP address..."
LOCAL_IP=$(hostname -I | awk '{print $1}')
print_info "Detected local IP: $LOCAL_IP"
read -p "Is this correct? [Y/n]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    read -p "Enter your local IP address: " LOCAL_IP
fi

# Confirm settings
echo ""
echo "═══════════════════════════════════════════════════════"
echo "Configuration Summary:"
echo "═══════════════════════════════════════════════════════"
echo "Remote NFS Server: $REMOTE_USER@$REMOTE_HOST:$SSH_PORT"
echo "Remote Directory:  $REMOTE_DIR"
echo "Local Mount Point: $LOCAL_MOUNT"
echo "Local Client IP:   $LOCAL_IP"
echo "Export Options:    $NFS_EXPORT_OPTS"
echo "Mount Options:     $NFS_MOUNT_OPTS"
echo "═══════════════════════════════════════════════════════"
echo ""
read -p "Proceed with NFS setup? [y/N]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Setup cancelled by user"
    exit 0
fi

SSH_CMD="ssh -p $SSH_PORT $REMOTE_USER@$REMOTE_HOST"

# --- Step 1: Setup NFS Server on Remote Host ---
echo ""
print_info "Step 1: Configuring NFS server on $REMOTE_HOST..."

# Check if remote host is accessible
if ! $SSH_CMD "echo 'SSH connection successful'" > /dev/null 2>&1; then
    print_error "Cannot connect to $REMOTE_HOST via SSH"
    print_info "Please ensure SSH is configured and you have access to the remote host"
    exit 1
fi

print_success "SSH connection established"

# Install NFS server on remote host
print_info "Installing NFS server packages on remote host..."
$SSH_CMD "sudo apt-get update && sudo apt-get install -y nfs-kernel-server" || {
    print_error "Failed to install NFS server packages"
    exit 1
}

# Create remote directory if it doesn't exist
print_info "Creating remote directory: $REMOTE_DIR"
$SSH_CMD "sudo mkdir -p $REMOTE_DIR && sudo chmod 755 $REMOTE_DIR" || {
    print_error "Failed to create remote directory"
    exit 1
}

# Check if export already exists
print_info "Checking existing NFS exports..."
if $SSH_CMD "grep -q '$REMOTE_DIR' /etc/exports 2>/dev/null"; then
    print_warning "Export for $REMOTE_DIR already exists in /etc/exports"
    read -p "Remove existing export and continue? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        $SSH_CMD "sudo sed -i '\|$REMOTE_DIR|d' /etc/exports"
        print_info "Removed existing export"
    else
        print_error "Cannot proceed with existing export"
        exit 1
    fi
fi

# Add NFS export
print_info "Adding NFS export configuration..."
$SSH_CMD "echo '$REMOTE_DIR    $LOCAL_IP($NFS_EXPORT_OPTS)' | sudo tee -a /etc/exports" || {
    print_error "Failed to add NFS export"
    exit 1
}

# Export the shared directory
print_info "Exporting NFS shares..."
$SSH_CMD "sudo exportfs -ra" || {
    print_error "Failed to export NFS shares"
    exit 1
}

# Restart NFS server
print_info "Restarting NFS server..."
$SSH_CMD "sudo systemctl restart nfs-kernel-server && sudo systemctl enable nfs-kernel-server" || {
    print_error "Failed to restart NFS server"
    exit 1
}

print_success "NFS server configured successfully on $REMOTE_HOST"

# --- Step 2: Setup NFS Client on Local Host ---
echo ""
print_info "Step 2: Configuring NFS client on local host..."

# Install NFS client
print_info "Installing NFS client packages..."
sudo apt-get update && sudo apt-get install -y nfs-common || {
    print_error "Failed to install NFS client packages"
    exit 1
}

# Create local mount point
print_info "Creating local mount point: $LOCAL_MOUNT"
sudo mkdir -p "$LOCAL_MOUNT" || {
    print_error "Failed to create local mount point"
    exit 1
}

# Check if already mounted
if mountpoint -q "$LOCAL_MOUNT" 2>/dev/null; then
    print_warning "$LOCAL_MOUNT is already a mount point"
    read -p "Unmount and continue? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo umount "$LOCAL_MOUNT"
        print_info "Unmounted $LOCAL_MOUNT"
    else
        print_error "Cannot proceed with existing mount"
        exit 1
    fi
fi

# Mount NFS share
print_info "Mounting NFS share from $REMOTE_HOST:$REMOTE_DIR to $LOCAL_MOUNT..."
sudo mount -t nfs -o "$NFS_MOUNT_OPTS" "$REMOTE_HOST:$REMOTE_DIR" "$LOCAL_MOUNT" || {
    print_error "Failed to mount NFS share"
    print_info "You may need to check firewall settings on both hosts"
    print_info "Required ports: TCP/UDP 111, 2049"
    exit 1
}

print_success "NFS share mounted successfully"

# Verify mount
print_info "Verifying mount..."
if mountpoint -q "$LOCAL_MOUNT"; then
    print_success "Mount verified: $LOCAL_MOUNT"
    df -h "$LOCAL_MOUNT"
else
    print_error "Mount verification failed"
    exit 1
fi

# --- Step 3: Add to fstab for persistence ---
echo ""
read -p "Add to /etc/fstab for automatic mounting on boot? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    FSTAB_ENTRY="$REMOTE_HOST:$REMOTE_DIR    $LOCAL_MOUNT    nfs    $NFS_MOUNT_OPTS    0    0"
    
    # Check if entry already exists
    if grep -q "$REMOTE_HOST:$REMOTE_DIR" /etc/fstab 2>/dev/null; then
        print_warning "An entry for this NFS share already exists in /etc/fstab"
        read -p "Replace it? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo sed -i "\|$REMOTE_HOST:$REMOTE_DIR|d" /etc/fstab
        else
            print_info "Skipping fstab update"
        fi
    fi
    
    if ! grep -q "$REMOTE_HOST:$REMOTE_DIR" /etc/fstab 2>/dev/null; then
        # Backup fstab
        sudo cp /etc/fstab /etc/fstab.backup.$(date +%Y%m%d_%H%M%S)
        echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab > /dev/null
        print_success "Added to /etc/fstab"
    fi
fi

# --- Summary ---
echo ""
echo "═══════════════════════════════════════════════════════"
print_success "NFS Share Setup Complete!"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Server: $REMOTE_HOST:$REMOTE_DIR"
echo "Client: $LOCAL_MOUNT"
echo ""
echo "Useful commands:"
echo "  - Check mount: df -h $LOCAL_MOUNT"
echo "  - Unmount:     sudo umount $LOCAL_MOUNT"
echo "  - Remount:     sudo mount $LOCAL_MOUNT"
echo "  - View exports on server: ssh $REMOTE_USER@$REMOTE_HOST 'showmount -e'"
echo "  - View mounts: mount | grep nfs"
echo ""
echo "To remove this NFS share:"
echo "  1. Unmount: sudo umount $LOCAL_MOUNT"
echo "  2. Remove from fstab: sudo sed -i '\\|$REMOTE_HOST:$REMOTE_DIR|d' /etc/fstab"
echo "  3. On server: ssh $REMOTE_USER@$REMOTE_HOST 'sudo sed -i \"\\|$REMOTE_DIR|d\" /etc/exports && sudo exportfs -ra'"
echo "═══════════════════════════════════════════════════════"
