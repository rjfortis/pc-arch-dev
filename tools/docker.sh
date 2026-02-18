#!/bin/bash
set -euo pipefail

# 1. Install Docker
sudo pacman -S --needed --noconfirm docker docker-compose docker-buildx

# 2. Enable Docker service
sudo systemctl enable --now docker.service

# 3. Create docker group and add current user
sudo groupadd -f docker
sudo usermod -aG docker "$USER"

# 4. Verification
echo "--------------------------------------------------"
docker --version
echo "Installation complete."
echo "IMPORTANT: Log out and log back in to apply group changes."
echo "Or run: newgrp docker"
echo "--------------------------------------------------"
