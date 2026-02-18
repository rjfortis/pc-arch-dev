# Arch i3 Dev Bootstrap

Personal Arch Linux (UEFI) bootstrap focused on:

* i3 window manager
* Development environment
* Reproducible setup
* Modular provisioning

This repository is designed for **clean installs** and personal environment rebuilding.

---

## Enter to the new pc using SSH

```
passwd

ip a

ssh root@<IP>

pacman -Sy git

git clone https://github.com/rjfortis/pc-arch-dev.git
```

---

## ⚠️ WARNING

`01_format-disk.sh` **will erase the selected disk.**

Use only on fresh systems or when you explicitly intend to wipe the drive.

UEFI systems only.

---

# Structure

```
.
├── 0_start-here/
│   ├── 01_format-disk.sh
│   └── 02_system-install.sh
├── config/
├── optional/
├── tools/
├── core.sh
├── tools.sh
├── dotfiles.sh
├── git-ssh.sh
└── README.md
```

---

# Execution Order

Follow this order strictly.

---

## 1️⃣ Disk Formatting (Live ISO)

From Arch ISO:

```bash
cd 0_start-here
bash 01_format-disk.sh
```

This:

* Partitions disk (UEFI)
* Creates filesystems
* Mounts target system

---

## 2️⃣ Base System Installation

Still from ISO:

```bash
bash 02_system-install.sh
```

This:

* Installs base system
* Installs kernel and firmware
* Configures bootloader
* Prepares chroot environment

Reboot after completion.

---

## 3️⃣ Core System Setup

After first boot into installed system:

```bash
bash core.sh
```

This handles:

* Core packages
* Base configuration
* System essentials

---

## 4️⃣ Install Tools

```bash
bash tools.sh
```

Executes all scripts inside:

```
tools/
```

Each tool is modular and isolated.

---

## 5️⃣ Apply Dotfiles

```bash
bash dotfiles.sh
```

Creates symlinks from:

```
config/
```

Into your `$HOME`.

Safe and idempotent.

---

## 6️⃣ Git & SSH Setup

```bash
bash git-ssh.sh
```

Configures:

* SSH keys
* Git identity
* GitHub access

---

# Design Principles

* Modular scripts
* Idempotent behavior where possible
* Fail-fast where critical
* No hidden automation
* Personal reproducibility over generalization

---

# Scope

* Arch Linux
* UEFI systems only
* i3 window manager
* Development-focused workstation
* Personal bootstrap

---

# Philosophy

This repository exists to:

* Rebuild your environment quickly
* Keep setup deterministic
* Avoid manual repetitive configuration
* Maintain full control over every layer
