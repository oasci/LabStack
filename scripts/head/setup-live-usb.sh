#!/usr/bin/env bash
set -euo pipefail

# ─── COLORS & LOG FUNCTIONS ──────────────────────────────────────────────────
GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; RESET="\e[0m"
log()   { echo -e "${GREEN}[+]${RESET} $1"; }
warn()  { echo -e "${YELLOW}[!]${RESET} $1"; }
error() { echo -e "${RED}[-]${RESET} $1"; exit 1; }

# ─── ENSURE ROOT & ENABLE TAB COMPLETION ─────────────────────────────────────
(( EUID == 0 )) || error "Run as root: sudo $0"
bind 'TAB:complete'

# ─── PROMPT FOR INPUTS ────────────────────────────────────────────────────────
read -e -p "Path to Ubuntu ISO: " ISO_PATH
[[ -f "$ISO_PATH" ]] || error "ISO not found at '$ISO_PATH'"

read -e -p "Path to autoinstall YAML: " YAML_PATH
[[ -f "$YAML_PATH" ]] || error "YAML not found at '$YAML_PATH'"

read -e -p "USB device (e.g. /dev/sda): " DEV
[[ -b "$DEV" ]] || error "Block device '$DEV' not found"
USB_PART="${DEV}1"

cat <<EOF

You are about to:

  • Wipe & reformat   ➜ $DEV
  • Copy ISO          ➜ $ISO_PATH
  • Copy autoinstall  ➜ $YAML_PATH

EOF

read -p "Proceed? (yes/[no]) " CONFIRM
[[ "$CONFIRM" == "yes" ]] || { log "Aborted."; exit 0; }

# ─── PREP: UNMOUNT ───────────────────────────────────────────────────────────
log "Unmounting partitions on $DEV if mounted..."
for p in $(lsblk -lnpo NAME,MOUNTPOINT "${DEV}"* | awk '$2!=""{print $1}'); do
  warn "  umount $p"
  umount "$p" || warn "Could not unmount $p, continuing"
done

# ─── PARTITION & FORMAT ──────────────────────────────────────────────────────
log "Creating single FAT32 partition on $DEV..."
parted --script "$DEV" \
  mklabel msdos \
  mkpart primary fat32 1MiB 100% \
  set 1 boot on

log "Formatting ${USB_PART} as FAT32..."
mkfs.vfat -F32 "$USB_PART"

# ─── MOUNTS ───────────────────────────────────────────────────────────────────
MNT_ISO=$(mktemp -d)
MNT_USB=$(mktemp -d)

log "Mounting ISO -> $MNT_ISO"
mount -o loop "$ISO_PATH" "$MNT_ISO"

log "Mounting USB -> $MNT_USB"
mount      "$USB_PART" "$MNT_USB"

# ─── COPY FILES (follow symlinks) ────────────────────────────────────────────
log "Copying ISO contents to USB..."
warn "Symbolic link errors are okay"

set +e
cp -aT "${MNT_ISO}/." "${MNT_USB}/"
CP_STATUS=$?
set -e

log "Adding autoinstall.yaml to USB root..."
cp "$YAML_PATH" "${MNT_USB}/autoinstall.yaml"

# ─── CLEANUP ─────────────────────────────────────────────────────────────────
log "Syncing disks..."
sync "$MNT_USB"

log "Unmounting mounts..."
umount "$MNT_ISO" "$MNT_USB"
rmdir "$MNT_ISO" "$MNT_USB"

log "USB is ready!"
