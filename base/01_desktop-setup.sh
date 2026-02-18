#!/bin/bash

# 01_desktop-setup.sh
# Purpose: Graphics, Window Manager, Audio, Bluetooth, and User Tools

# 1. Update Mirrors and System
echo "Updating mirrors and system..."
sudo pacman -S --needed --noconfirm reflector
sudo reflector --country 'United States' --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
sudo pacman -Syu --noconfirm

# 2. Driver Detection (CPU & GPU)
echo "Installing hardware drivers..."
if grep -q "Intel" /proc/cpuinfo; then
    sudo pacman -S --needed --noconfirm mesa vulkan-intel intel-media-driver
elif grep -q "AMD" /proc/cpuinfo; then
    sudo pacman -S --needed --noconfirm xf86-video-amdgpu mesa mesa-utils vulkan-radeon vulkan-icd-loader libva-mesa-driver
fi

# 3. Audio Stack (Pipewire - Modern & Essential)
echo "Installing Audio stack (Pipewire)..."
sudo pacman -S --needed --noconfirm \
    pipewire pipewire-audio pipewire-pulse pipewire-alsa pipewire-jack \
    pavucontrol pasystray

# 4. Bluetooth Setup
echo "Installing Bluetooth stack..."
sudo pacman -S --needed --noconfirm bluez bluez-utils blueman
sudo systemctl enable bluetooth

# 5. Network Applet & Power Management
echo "Installing Network and Power applets..."
sudo pacman -S --needed --noconfirm nm-applet upower

# 6. Laptop Specifics
if [ -d "/sys/class/power_supply/BAT0" ]; then
    echo "Laptop detected. Installing power and touchpad tools..."
    sudo pacman -S --needed --noconfirm brightnessctl acpi cpupower xf86-input-libinput
fi

# 7. Essential Tools & Development
echo "Installing essential and development tools..."
sudo pacman -S --needed --noconfirm \
    base-devel git curl wget github-cli rsync zip unzip xdg-utils xdg-user-dirs \
    xclip dbus htop ca-certificates openssl usbutils dmidecode pciutils \
    direnv ripgrep helix jq tmux zellij

# 8. Xorg and i3 Window Manager
echo "Installing Xorg and i3..."
sudo pacman -S --needed --noconfirm \
    xorg-server xorg-xinit xorg-xsetroot \
    i3 i3lock xss-lock picom feh \
    alacritty rofi pcmanfm dunst libnotify flameshot redshift lxqt-policykit

# 9. Fonts
echo "Installing fonts..."
sudo pacman -S --needed --noconfirm \
    ttf-liberation ttf-dejavu ttf-jetbrains-mono ttf-jetbrains-mono-nerd \
    ttf-font-awesome

# 10. Setup XDG Directories
xdg-user-dirs-update

# 11. Install Paru (AUR Helper)
echo "Installing Paru (AUR Helper)..."
if ! command -v paru &> /dev/null; then
    mkdir -p ~/temp
    git clone https://aur.archlinux.org/paru-bin.git ~/temp/paru-bin
    cd ~/temp/paru-bin && makepkg -si --noconfirm
    cd ~
    rm -rf ~/temp
fi

echo "--------------------------------------------------------"
echo "SETUP COMPLETE!"
echo "System ready for i3. Don't forget to 'exec i3' in ~/.xinitrc"
