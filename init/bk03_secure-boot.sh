#!/bin/bash

# 03_secure-boot.sh
# Purpose: Configure Secure Boot with sbctl (Dual-boot friendly)

# 1. Check if sbctl is installed
if ! command -v sbctl &> /dev/null; then
    echo "Installing sbctl..."
    sudo pacman -S --noconfirm sbctl
fi

# 2. Check Status
echo "Checking Secure Boot status..."
sbctl status

echo "--------------------------------------------------------"
echo "IMPORTANT: Your BIOS must be in 'Setup Mode' (Custom/Audit mode)."
echo "If Setup Mode is 'Disabled', this script will fail."
echo "--------------------------------------------------------"
read -p "Is your BIOS in Setup Mode? (yes/no): " SETUP_CONFIRM

if [ "$SETUP_CONFIRM" != "yes" ]; then
    echo "Please go to BIOS, clear Secure Boot keys, and return."
    exit 1
fi

# 3. Create and Enroll Keys
echo "Creating your custom Secure Boot keys..."
sudo sbctl create-keys

echo "Enrolling keys (including Microsoft keys for Windows Dual Boot)..."
sudo sbctl enroll-keys -m

# 4. Signing Boot Files
echo "Signing kernel and bootloader files..."
# sbctl sign -s automatically tracks these files for future kernel updates
sudo sbctl sign -s /boot/vmlinuz-linux
sudo sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI
sudo sbctl sign -s /boot/EFI/systemd/systemd-bootx64.efi

# 5. Final Verification
echo "--------------------------------------------------------"
echo "Verification:"
sudo sbctl verify
echo "--------------------------------------------------------"
echo "Done! Now go to BIOS and re-enable Secure Boot (User Mode)."
