#!/usr/bin/env bash

set -euo pipefail

# --------------------------------------------------------
# Prevent running as root
# --------------------------------------------------------
if [ "$EUID" -eq 0 ]; then
    echo "Error: Do not run this script as root."
    exit 1
fi

# --------------------------------------------------------
# Resolve repository path
# --------------------------------------------------------
REPO_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=== Linking Dotfiles from: $REPO_PATH ==="

# --------------------------------------------------------
# Generic Link Function
# --------------------------------------------------------
link_file() {
    local relative_src="$1"
    local relative_dest="$2"

    local src="$REPO_PATH/$relative_src"
    local dest="$HOME/$relative_dest"

    if [ ! -e "$src" ]; then
        echo "Warning: Source not found → $relative_src"
        return
    fi

    mkdir -p "$(dirname "$dest")"

    # If already correct symlink
    if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
        echo "Already linked: $relative_dest"
        return
    fi

    # If real file exists → backup
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        mv "$dest" "$dest.bak"
        echo "Backed up existing file: $relative_dest → $relative_dest.bak"
    fi

    ln -sf "$src" "$dest"
    echo "Linked: $relative_dest"
}

# --------------------------------------------------------
# Link Files
# --------------------------------------------------------

# Shell
link_file "config/bashrc" ".bashrc"

# xinit
link_file "config/xinitrc" ".xinitrc"

# Window Manager & Status
link_file "config/i3/config" ".config/i3/config"
link_file "config/i3status/config" ".config/i3status/config"

# Terminal & Apps
link_file "config/alacritty/alacritty.toml" ".config/alacritty/alacritty.toml"
link_file "config/zed/settings.json" ".config/zed/settings.json"

echo "=== Done! All configs are now managed via symlinks ==="
