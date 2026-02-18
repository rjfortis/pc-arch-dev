#!/bin/bash
set -euo pipefail

# GIT & SSH SETUP
echo "Git & SSH setup"
echo "----------------------------------------"

# User input
read -rp "Enter your full name for Git: " GIT_NAME
read -rp "Enter your email for Git & SSH: " GIT_EMAIL

# Git configuration
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch main

echo ""
echo "Git configured:"
git config --global --list | grep -E 'user.name|user.email|init.defaultBranch'
echo ""

# Ensure .ssh directory exists
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

KEY_PATH="$HOME/.ssh/id_ed25519"

# Ask before generating SSH key
if [ -f "$KEY_PATH" ]; then
    echo "SSH key already exists at $KEY_PATH"
else
    read -rp "Generate a new SSH key (ed25519, no passphrase)? [y/N]: " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$KEY_PATH" -N ""
    else
        echo "Skipping SSH key generation."
    fi
fi

# Start ssh-agent if not running
if ! pgrep -u "$USER" ssh-agent >/dev/null; then
    eval "$(ssh-agent -s)"
fi

# Add key to the agent
if [ -f "$KEY_PATH" ]; then
    ssh-add "$KEY_PATH"
fi

# Output public key and copy to clipboard
if [ -f "$KEY_PATH.pub" ]; then
    PUBLIC_KEY=$(cat "$KEY_PATH.pub")
    echo ""
    echo "----------------------------------------"
    echo "Your SSH public key:"
    echo ""
    echo "$PUBLIC_KEY"
    echo ""
    echo "Add it here:"
    echo "  https://github.com/settings/keys"
    echo "  https://gitlab.com/-/profile/keys"
    echo "----------------------------------------"
fi
