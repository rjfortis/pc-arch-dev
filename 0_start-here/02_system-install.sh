#!/bin/bash

set -euo pipefail

# -----------------------------
# 00. Dependency Check
# -----------------------------
REQUIRED_CMDS=(pacstrap genfstab arch-chroot bootctl mkinitcpio blkid ping awk)

for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: Required command '$cmd' not found."
        exit 1
    fi
done

# -----------------------------
# 01. Verify Internet Connectivity
# -----------------------------
echo "Checking internet connectivity..."
if ! ping -c 1 -W 2 archlinux.org >/dev/null 2>&1; then
    echo "Error: No internet connection detected. pacstrap requires network access."
    exit 1
fi

# -----------------------------
# 02. CPU Vendor Detection (Improved)
# -----------------------------
CPU_VENDOR=$(awk -F: '/vendor_id/ {print $2; exit}' /proc/cpuinfo | xargs 2>/dev/null || true)

if [[ "$CPU_VENDOR" == "GenuineIntel" ]]; then
    UCODE_PACKAGE="intel-ucode"
elif [[ "$CPU_VENDOR" == "AuthenticAMD" ]]; then
    UCODE_PACKAGE="amd-ucode"
else
    echo "Warning: Unknown CPU vendor '$CPU_VENDOR'. Skipping microcode."
    UCODE_PACKAGE=""
fi

# -----------------------------
# 03. Gather User Info
# -----------------------------
read -rp "Enter hostname: " MY_HOSTNAME
read -rp "Enter username: " MY_USER
read -s -p "Enter password for both root and $MY_USER: " MY_PASSWORD
echo ""

# -----------------------------
# 04. Base Installation (Package Array)
# -----------------------------
PACKAGES=(
    base
    linux
    linux-firmware
    nano
    sudo
    git
    gh
    openssh
    networkmanager
    xfsprogs
)

[[ -n "$UCODE_PACKAGE" ]] && PACKAGES+=("$UCODE_PACKAGE")

echo "Installing base system packages..."
pacstrap -K /mnt "${PACKAGES[@]}"

# -----------------------------
# 05. Generate fstab
# -----------------------------
echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# -----------------------------
# 06. Chroot Configuration
# -----------------------------
echo "Entering Chroot for system configuration..."

arch-chroot /mnt <<EOF

set -euo pipefail

# -----------------------------
# Localization (Avoid duplication)
# -----------------------------
ln -sf /usr/share/zoneinfo/America/El_Salvador /etc/localtime
hwclock --systohc

# Uncomment if commented
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen

# Append only if missing
if ! grep -q "^en_US.UTF-8 UTF-8" /etc/locale.gen; then
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
fi

locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# -----------------------------
# Network configuration
# -----------------------------
echo "$MY_HOSTNAME" > /etc/hostname

cat <<EOT > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $MY_HOSTNAME.localdomain   $MY_HOSTNAME
EOT

# -----------------------------
# Users and Permissions
# -----------------------------
echo "root:$MY_PASSWORD" | chpasswd
useradd -m -G wheel "$MY_USER"
echo "$MY_USER:$MY_PASSWORD" | chpasswd

sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# -----------------------------
# Enable services
# -----------------------------
systemctl enable sshd
systemctl enable NetworkManager
systemctl enable systemd-timesyncd

# -----------------------------
# Bootloader Setup (systemd-boot)
# -----------------------------
bootctl install

cat <<EOT > /boot/loader/loader.conf
default arch.conf
timeout 5
editor no
console-mode auto
EOT

# -----------------------------
# Resolve ROOT UUID Safely
# -----------------------------
ROOT_UUID=\$(blkid -s UUID -o value -L SYSTEM || true)

if [ -z "\$ROOT_UUID" ]; then
    echo "Error: Could not find partition labeled SYSTEM."
    exit 1
fi

cat <<EOT > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
$( [[ -n "$UCODE_PACKAGE" ]] && echo "initrd  /$UCODE_PACKAGE.img" )
initrd  /initramfs-linux.img
options root=UUID=\$ROOT_UUID rw audit=0 acpi_backlight=vendor splash quiet
EOT

# -----------------------------
# Regenerate Initramfs
# -----------------------------
cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.orig

sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block filesystems fsck)/' /etc/mkinitcpio.conf

mkinitcpio -P

EOF

# -----------------------------
# 07. Final Message & Shutdown
# -----------------------------
echo "--------------------------------------------------------"
echo "INSTALLATION FINISHED SUCCESSFULLY!"
echo "Please REMOVE the USB installation media NOW."
echo "--------------------------------------------------------"

echo "Unmounting partitions..."
umount -R /mnt

echo "Shutting down in 5 seconds..."
sleep 5
poweroff
