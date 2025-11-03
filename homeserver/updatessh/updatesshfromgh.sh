#!/bin/bash

# --- Configuration ---
GITHUB_USERNAME="saurabh500"  # <-- change this
SSH_DIR="$HOME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"
TEMP_KEYS="/tmp/github_keys_$$"

# --- Create .ssh directory if it doesn't exist ---
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# --- Download public keys from GitHub ---
echo "📥 Downloading SSH keys from GitHub user '${GITHUB_USERNAME}'..."
if ! curl -fsSL "https://github.com/${GITHUB_USERNAME}.keys" > "$TEMP_KEYS"; then
    echo "❌ Failed to download keys from GitHub"
    rm -f "$TEMP_KEYS"
    exit 1
fi

# --- Check if we got any keys ---
if [ ! -s "$TEMP_KEYS" ]; then
    echo "⚠️  No keys found for GitHub user '${GITHUB_USERNAME}'"
    rm -f "$TEMP_KEYS"
    exit 1
fi

# --- Merge with existing keys (if any) ---
if [ -f "$AUTHORIZED_KEYS" ]; then
    echo "🔄 Merging with existing authorized_keys..."
    # Create backup
    cp "$AUTHORIZED_KEYS" "${AUTHORIZED_KEYS}.backup.$(date +%Y%m%d_%H%M%S)"
    # Combine existing and new keys, remove duplicates, and filter out empty lines
    cat "$AUTHORIZED_KEYS" "$TEMP_KEYS" | sort -u | grep -v '^$' > "${AUTHORIZED_KEYS}.tmp"
    mv "${AUTHORIZED_KEYS}.tmp" "$AUTHORIZED_KEYS"
else
    echo "📝 Creating new authorized_keys file..."
    mv "$TEMP_KEYS" "$AUTHORIZED_KEYS"
fi

# --- Clean up temp file ---
rm -f "$TEMP_KEYS"

# --- Secure the authorized_keys file ---
chmod 600 "$AUTHORIZED_KEYS"

# --- Done ---
echo "✅ SSH authorized_keys updated from GitHub user '${GITHUB_USERNAME}'."
echo "   Existing keys have been preserved and merged with GitHub keys."
