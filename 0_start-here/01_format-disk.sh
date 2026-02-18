#!/bin/bash

# 01_format-disk.sh
# Purpose: Interactive disk partitioning and formatting (UEFI/XFS)

set -euo pipefail

# -----------------------------
# 0. Dependency Check
# -----------------------------
REQUIRED_CMDS=(sgdisk wipefs mkfs.fat mkfs.xfs partprobe lsblk findmnt udevadm)

for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: Required command '$cmd' not found."
        exit 1
    fi
done

# -----------------------------
# 1. UEFI Check
# -----------------------------
if [ ! -d "/sys/firmware/efi" ]; then
    echo "Error: System is not booted in UEFI mode. This script requires UEFI."
    exit 1
fi

# -----------------------------
# 2. Show Available Disks
# -----------------------------
echo "Available disks in the system:"
lsblk -d -n -o NAME,SIZE,MODEL | grep -v "loop"
echo ""

# -----------------------------
# 3. Get Drive Name
# -----------------------------
read -rp "Enter the drive name (e.g., nvme0n1 or sda): " DISK_NAME
DRIVE="/dev/$DISK_NAME"

if [ ! -b "$DRIVE" ]; then
    echo "Error: Device $DRIVE not found."
    exit 1
fi

# -----------------------------
# 4. Detect Mounted Partitions
# -----------------------------
if lsblk -n -o MOUNTPOINT "$DRIVE" | grep -q "/"; then
    echo "Error: One or more partitions on $DRIVE are currently mounted."
    echo "Unmount them before proceeding."
    exit 1
fi

# -----------------------------
# 5. Detect Current Root Disk
# -----------------------------
ROOT_DEVICE=$(findmnt -n -o SOURCE /)
ROOT_DISK=$(lsblk -no PKNAME "$ROOT_DEVICE" 2>/dev/null || true)

if [ -n "${ROOT_DISK:-}" ] && [ "/dev/$ROOT_DISK" = "$DRIVE" ]; then
    echo "--------------------------------------------------------"
    echo "CRITICAL WARNING:"
    echo "You are attempting to wipe the disk containing the current root filesystem."
    echo "Root device: $ROOT_DEVICE"
    echo "Root disk: /dev/$ROOT_DISK"
    echo "--------------------------------------------------------"
    read -rp "Type 'yes' to continue: " ROOT_CONFIRM
    if [ "$ROOT_CONFIRM" != "yes" ]; then
        echo "Operation aborted."
        exit 1
    fi
fi

# -----------------------------
# 6. Final Confirmation
# -----------------------------
echo "--------------------------------------------------------"
echo "DANGER: Everything on $DRIVE will be DELETED"
echo "Current partition layout:"
lsblk "$DRIVE"
echo "--------------------------------------------------------"

read -rp "Type 'yes' to continue: " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Operation aborted."
    exit 1
fi

echo "Starting in 3 seconds..."
sleep 3

# -----------------------------
# 7. Full Wipe
# -----------------------------
echo "Wiping signatures and partition table..."
sgdisk --zap-all "$DRIVE"
wipefs -a "$DRIVE"

# -----------------------------
# 8. Create GPT Partition Scheme
# -----------------------------
echo "Creating partitions..."
sgdisk --clear \
       --new=1:0:+550MiB --typecode=1:ef00 --change-name=1:EFI \
       --new=2:0:0       --typecode=2:8300 --change-name=2:SYSTEM \
       "$DRIVE"

partprobe "$DRIVE"
udevadm settle
sleep 1

# -----------------------------
# 9. Format Partitions
# -----------------------------
echo "Formatting partitions..."

mkfs.fat -F32 -n EFI /dev/disk/by-partlabel/EFI
mkfs.xfs -f -L SYSTEM /dev/disk/by-partlabel/SYSTEM

# -----------------------------
# 10. Mount for Installation
# -----------------------------
echo "Mounting to /mnt..."
mount LABEL=SYSTEM /mnt
mkdir -p /mnt/boot
mount LABEL=EFI /mnt/boot

echo "--------------------------------------------------------"
echo "Done! Drive $DRIVE is ready and mounted at /mnt."
lsblk "$DRIVE"
