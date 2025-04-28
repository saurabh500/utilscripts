#!/bin/bash

# --- Configuration ---
GITHUB_USERNAME="saurabh500"  # <-- change this
SSH_DIR="$HOME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

# --- Create .ssh directory if it doesn't exist ---
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# --- Download public keys from GitHub ---
curl -fsSL "https://github.com/${GITHUB_USERNAME}.keys" > "$AUTHORIZED_KEYS"

# --- Secure the authorized_keys file ---
chmod 600 "$AUTHORIZED_KEYS"

# --- Done ---
echo "✅ SSH authorized_keys updated from GitHub user '${GITHUB_USERNAME}'."
