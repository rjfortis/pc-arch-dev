#!/bin/bash

set -euo pipefail

# --------------------------------------------------------
# 00. Prevent Root Execution
# --------------------------------------------------------
if [ "$EUID" -eq 0 ]; then
    echo "Error: Do NOT run this script as root."
    echo "Run it as your regular user with sudo privileges."
    exit 1
fi

log() {
    echo ""
    echo "--------------------------------------------------------"
    echo "[+] $1"
    echo "--------------------------------------------------------"
}

# --------------------------------------------------------
# 01. Update Mirrors and System
# --------------------------------------------------------
log "Updating mirrors and system"

sudo pacman -S --needed --noconfirm reflector
sudo reflector --country 'United States' --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
sudo pacman -Syu --noconfirm

# --------------------------------------------------------
# 02. GPU Detection & Driver Installation
# --------------------------------------------------------
log "Detecting GPU and installing drivers"

GPU_INFO=$(lspci | grep -E "VGA|3D" || true)

if echo "$GPU_INFO" | grep -qi "NVIDIA"; then
    echo "NVIDIA GPU detected"
    sudo pacman -S --needed --noconfirm nvidia nvidia-utils nvidia-settings
elif echo "$GPU_INFO" | grep -qi "AMD"; then
    echo "AMD GPU detected"
    sudo pacman -S --needed --noconfirm \
        xf86-video-amdgpu mesa mesa-utils vulkan-radeon vulkan-icd-loader libva-mesa-driver
elif echo "$GPU_INFO" | grep -qi "Intel"; then
    echo "Intel GPU detected"
    sudo pacman -S --needed --noconfirm mesa vulkan-intel intel-media-driver
else
    echo "No supported GPU detected or running in VM. Skipping GPU drivers."
fi

# --------------------------------------------------------
# 03. Audio Stack (Pipewire)
# --------------------------------------------------------
log "Installing Audio stack (Pipewire)"

sudo pacman -S --needed --noconfirm \
    pipewire pipewire-audio pipewire-pulse pipewire-alsa pipewire-jack \
    pavucontrol pasystray

# --------------------------------------------------------
# 04. Bluetooth Setup
# --------------------------------------------------------
log "Installing Bluetooth stack"

sudo pacman -S --needed --noconfirm bluez bluez-utils blueman
sudo systemctl enable bluetooth

# --------------------------------------------------------
# 05. Network Applet & Power Management
# --------------------------------------------------------
log "Installing network and power applets"

sudo pacman -S --needed --noconfirm network-manager-applet upower

# --------------------------------------------------------
# 06. Laptop Specific Tools
# --------------------------------------------------------
if [ -d "/sys/class/power_supply/BAT0" ]; then
    log "Laptop detected – installing power and touchpad tools"
    sudo pacman -S --needed --noconfirm brightnessctl acpi cpupower xf86-input-libinput
fi

# --------------------------------------------------------
# 07. Essential Tools & Development
# --------------------------------------------------------
log "Installing essential and development tools"

sudo pacman -S --needed --noconfirm \
    base-devel bash-completion git curl wget github-cli rsync zip unzip xdg-utils xdg-user-dirs \
    xclip dbus htop ca-certificates openssl usbutils dmidecode pciutils \
    direnv ripgrep helix jq tmux zellij

# --------------------------------------------------------
# 08. Xorg and i3 Window Manager
# --------------------------------------------------------
log "Installing Xorg and i3 window manager"

sudo pacman -S --needed --noconfirm \
    xorg-server xorg-xinit xorg-xsetroot \
    i3 i3lock xss-lock picom feh \
    alacritty rofi pcmanfm dunst libnotify flameshot redshift lxqt-policykit

# --------------------------------------------------------
# 09. Fonts
# --------------------------------------------------------
log "Installing fonts"

sudo pacman -S --needed --noconfirm \
    ttf-liberation ttf-dejavu ttf-jetbrains-mono ttf-jetbrains-mono-nerd \
    ttf-font-awesome noto-fonts noto-fonts-emoji noto-fonts-cjk

# --------------------------------------------------------
# 10. Setup XDG Directories
# --------------------------------------------------------
log "Configuring XDG user directories"

xdg-user-dirs-update

# --------------------------------------------------------
# 11. Install Paru (AUR Helper)
# --------------------------------------------------------
log "Installing Paru (AUR helper)"

if ! command -v paru >/dev/null 2>&1; then
    mkdir -p ~/temp
    git clone https://aur.archlinux.org/paru-bin.git ~/temp/paru-bin
    cd ~/temp/paru-bin
    makepkg -si --noconfirm
    cd ~
    rm -rf ~/temp
else
    echo "Paru already installed"
fi

echo ""
echo "--------------------------------------------------------"
echo "DESKTOP SETUP COMPLETE!"
echo "--------------------------------------------------------"
