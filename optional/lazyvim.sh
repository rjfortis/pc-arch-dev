#!/usr/bin/env bash

set -euo pipefail

# --------------------------------------------------------
# Verify Neovim is installed
# --------------------------------------------------------
if ! command -v nvim >/dev/null 2>&1; then
  echo "Error: Neovim is not installed."
  echo "Install it first with: sudo pacman -S neovim"
  exit 1
fi

# Backup existing config if it exists
if [ -d ~/.config/nvim ]; then
  mv ~/.config/nvim ~/.config/nvim.bak
fi

# Clone the starter
git clone https://github.com/LazyVim/starter ~/.config/nvim

# Wait for git clone to finish properly
sleep 3

# Remove git history from the starter
rm -rf ~/.config/nvim/.git

# Ensure config directory exists
mkdir -p ~/.config/nvim/lua/config

# Configure Clipboard (OSC 52) in options.lua
OPTIONS_FILE="$HOME/.config/nvim/lua/config/options.lua"

cat <<'EOF' >>"$OPTIONS_FILE"
-- Clipboard configuration for SSH (OSC 52)
vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
  },
}
EOF

# Custom Keymaps
KEYMAPS_FILE="$HOME/.config/nvim/lua/config/keymaps.lua"

cat <<'EOF' >>"$KEYMAPS_FILE"

-- Custom buffer navigation
vim.keymap.set("n", "<S-Right>", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-Left>", ":bprevious<CR>", { desc = "Previous buffer" })
EOF

echo "LazyVim installed successfully."
