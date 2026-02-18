#!/usr/bin/env bash
set -euo pipefail

echo "Installing and configuring Nix on Arch Linux..."

# 1. Install Nix via pacman
if ! pacman -Qi nix &>/dev/null; then
  sudo pacman -S --noconfirm nix
else
  echo "Nix is already installed."
fi

# 2. Ensure nix-users group exists and add current user
sudo groupadd -f nix-users
sudo gpasswd -a "$USER" nix-users

# 3. Enable and start the Nix daemon (multi-user mode)
sudo systemctl enable --now nix-daemon

# 4. Enable experimental features (nix-command, flakes)
NIX_CONF_DIR="$HOME/.config/nix"
NIX_CONF_FILE="$NIX_CONF_DIR/nix.conf"

mkdir -p "$NIX_CONF_DIR"

if ! grep -q "experimental-features" "$NIX_CONF_FILE" 2>/dev/null; then
  echo "experimental-features = nix-command flakes" >>"$NIX_CONF_FILE"
fi

# User Nixpkgs config (for allowUnfree)
NIXPKGS_CONFIG_DIR="$HOME/.config/nixpkgs"
NIXPKGS_CONFIG_FILE="$NIXPKGS_CONFIG_DIR/config.nix"

# Configure allowUnfree
mkdir -p "$NIXPKGS_CONFIG_DIR"
cat <<EOF >"$NIXPKGS_CONFIG_FILE"
{
  allowUnfree = true;
}
EOF

# Ensure Nix environment is loaded in bash
#NIX_PROFILE_LINE='[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ] && . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'

#if ! grep -qF "$NIX_PROFILE_LINE" "$HOME/.bashrc"; then
#  echo "$NIX_PROFILE_LINE" >>"$HOME/.bashrc"
#fi

# Apply changes to the current session
export NIX_REMOTE=daemon
#if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
#  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
#fi

echo ""
echo "Nix installation completed successfully."
echo "IMPORTANT: Restart your terminal or run 'source ~/.bashrc' to start using Nix."
