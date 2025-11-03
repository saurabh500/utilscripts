#!/bin/bash

# Installation script for updatesshfromgh.sh cron job
# This script adds a cron job to automatically update SSH authorized_keys from GitHub

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/updatesshfromgh.sh"
LOG_FILE="$HOME/update-ssh-keys.log"
CRON_SCHEDULE="*/10 * * * *"  # Every 10 minutes

# --- Check if script exists ---
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "❌ Error: updatesshfromgh.sh not found at $SCRIPT_PATH"
    exit 1
fi

# --- Make script executable ---
echo "🔧 Making updatesshfromgh.sh executable..."
chmod +x "$SCRIPT_PATH"

# --- Check if cron job already exists ---
CRON_COMMAND="$SCRIPT_PATH >> $LOG_FILE 2>&1"
if crontab -l 2>/dev/null | grep -F "$SCRIPT_PATH" > /dev/null; then
    echo "⚠️  Cron job for updatesshfromgh.sh already exists!"
    echo ""
    echo "Current cron entry:"
    crontab -l | grep -F "$SCRIPT_PATH"
    echo ""
    read -p "Do you want to remove and reinstall it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Installation cancelled."
        exit 0
    fi
    # Remove existing entry
    crontab -l | grep -v -F "$SCRIPT_PATH" | crontab -
    echo "🗑️  Removed existing cron job."
fi

# --- Add cron job ---
echo "➕ Adding cron job to update SSH keys every 10 minutes..."
(crontab -l 2>/dev/null; echo "$CRON_SCHEDULE $CRON_COMMAND") | crontab -

# --- Verify installation ---
echo ""
echo "✅ Installation complete!"
echo ""
echo "Cron job details:"
echo "  Schedule: Every 10 minutes"
echo "  Script:   $SCRIPT_PATH"
echo "  Log file: $LOG_FILE"
echo ""
echo "Current crontab entry:"
crontab -l | grep -F "$SCRIPT_PATH"
echo ""
echo "💡 Tips:"
echo "  - View logs: tail -f $LOG_FILE"
echo "  - Edit crontab: crontab -e"
echo "  - List crontab: crontab -l"
echo "  - Remove this job: crontab -l | grep -v updatesshfromgh.sh | crontab -"
echo ""
echo "🧪 To test the script manually, run:"
echo "  $SCRIPT_PATH"
