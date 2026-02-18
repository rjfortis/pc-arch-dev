#!/bin/bash
set -euo pipefail

echo "Installing Tailscale..."

# Install Tailscale
sudo pacman -S --needed --noconfirm tailscale

# Enable and start service
sudo systemctl enable --now tailscaled.service

echo "----------------------------------------"
echo "Tailscale installed and running"
echo "Next step: authenticate with: "
echo "sudo tailscale up"
echo "----------------------------------------"
