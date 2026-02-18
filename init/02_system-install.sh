#!/bin/bash

# 01. Detection of CPU Microcode
if grep -q "Intel" /proc/cpuinfo; then
    CPU_ARCH="intel"
elif grep -q "AMD" /proc/cpuinfo; then
    CPU_ARCH="amd"
else
    echo "Unknown CPU architecture. Skipping ucode."
fi

# 02. Gather User Info
read -p "Enter hostname: " MY_HOSTNAME
read -p "Enter username: " MY_USER
read -s -p "Enter password for both root and $MY_USER: " MY_PASSWORD
echo ""

# 03. Base Installation (pacstrap)
# CORRECCIÓN: networkmanager en minúsculas y añadimos xfsprogs
echo "Installing base system packages..."
pacstrap -K /mnt base linux linux-firmware $CPU_ARCH-ucode \
    nano sudo git gh openssh networkmanager xfsprogs

# 04. Generate fstab
echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# 05. Chroot Configuration
echo "Entering Chroot for system configuration..."
arch-chroot /mnt <<EOF
# Localization
ln -sf /usr/share/zoneinfo/America/El_Salvador /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Network configuration
echo "$MY_HOSTNAME" > /etc/hostname
cat <<EOT > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $MY_HOSTNAME.localdomain   $MY_HOSTNAME
EOT

# Users and Permissions
echo "root:$MY_PASSWORD" | chpasswd
useradd -m -G wheel "$MY_USER"
echo "$MY_USER:$MY_PASSWORD" | chpasswd
# Enable sudo for wheel group
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Enable services
systemctl enable sshd
systemctl enable NetworkManager
systemctl enable systemd-timesyncd

# 06. Bootloader Setup (systemd-boot)
bootctl install

# Configure loader.conf
cat <<EOT > /boot/loader/loader.conf
default arch.conf
timeout 5
editor no
console-mode auto
EOT

# Get UUID of the ROOT partition (SYSTEM)
ROOT_UUID=\$(blkid -s UUID -o value -L SYSTEM)

# Configure arch.conf (Entry)
cat <<EOT > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /$CPU_ARCH-ucode.img
initrd  /initramfs-linux.img
options root=UUID=\$ROOT_UUID rw audit=0 acpi_backlight=vendor splash quiet
EOT

# 07. Regenerate Initramfs
cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.orig
# Hook layout estándar
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -p linux

EOF

# 08. Final Message, Clean up and Power Off
echo "--------------------------------------------------------"
echo "INSTALLATION FINISHED SUCCESSFULLY!"
echo "Please REMOVE the USB installation media NOW."
echo "--------------------------------------------------------"
echo "Unmounting partitions..."
umount -R /mnt

echo "Shutting down in 5 seconds..."
sleep 5
poweroff
