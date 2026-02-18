#!/bin/bash

# 01_format-disk.sh
# Purpose: Interactive disk partitioning and formatting (UEFI/XFS)

# 1. Check if system is booted in UEFI mode
if [ ! -d "/sys/firmware/efi" ]; then
    echo "Error: System is not booted in UEFI mode. This script requires UEFI."
    exit 1
fi

# 2. Show available disks to the user
echo "Available disks in the system:"
lsblk -d -n -o NAME,SIZE,MODEL | grep -v "loop"
echo ""

# 3. Get the drive name interactively
read -p "Enter the drive name (e.g., nvme0n1 or sda): " DISK_NAME

# Define the full path
export DRIVE="/dev/$DISK_NAME"

# 4. Validation: Check if the device exists
if [ ! -b "$DRIVE" ]; then
    echo "Error: Device $DRIVE not found."
    exit 1
fi

# 5. Security Confirmation
echo "--------------------------------------------------------"
echo "DANGER: Everything on $DRIVE will be DELETED"
echo "Current partition layout:"
lsblk $DRIVE
echo "--------------------------------------------------------"
read -p "ARE YOU SURE? (type 'yes' to continue): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Operation aborted by user."
    exit 1
fi

echo "Starting in 3 seconds..."
sleep 3

# 6. Full Wipe
echo "Wiping signatures and partition table..."
sgdisk --zap-all $DRIVE
wipefs -a $DRIVE

# 7. Create new GPT partition scheme
# Partition 1: EFI (550MiB) - Type ef00
# Partition 2: System (Remaining space) - Type 8300
echo "Creating partitions..."
sgdisk --clear \
       --new=1:0:+550MiB --typecode=1:ef00 --change-name=1:EFI \
       --new=2:0:0       --typecode=2:8300 --change-name=2:SYSTEM $DRIVE

# Inform the kernel of partition changes
partprobe $DRIVE
sleep 2

# 8. Format the partitions
echo "Formatting partitions..."

# EFI (FAT32)
mkfs.fat -F32 -n EFI /dev/disk/by-partlabel/EFI

# SYSTEM (XFS)
mkfs.xfs -f -L SYSTEM /dev/disk/by-partlabel/SYSTEM

# 9. Mount for installation
echo "Mounting units to /mnt..."
mount LABEL=SYSTEM /mnt
mkdir -p /mnt/boot
mount LABEL=EFI /mnt/boot

echo "--------------------------------------------------------"
echo "Done! Drive $DRIVE is ready and mounted at /mnt."
lsblk $DRIVE
