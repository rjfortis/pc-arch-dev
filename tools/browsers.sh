#!/usr/bin/env bash

set -euo pipefail

echo "=== Installing Browsers ==="

PACKAGES=(
    chromium
    firefox
)

sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

echo "=== Browsers installation complete ==="
