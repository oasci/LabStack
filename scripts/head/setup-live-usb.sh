#!/usr/bin/env bash
set -euo pipefail

# COLORS & LOG FUNCTIONS 
GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; RESET="\e[0m"
log()   { echo -e "${GREEN}[+]${RESET} $1"; }
warn()  { echo -e "${YELLOW}[!]${RESET} $1"; }
error() { echo -e "${RED}[-]${RESET} $1"; exit 1; }

log "Live USB creator utility"

# ENSURE ROOT & ENABLE TAB COMPLETION
(( EUID == 0 )) || error "Run as root: sudo $0"
if [[ $- == *i* ]]; then
  bind 'TAB:complete'
fi

# DISPLAY BLOCKS
# GLOBAL ASSOCIATIVE ARRAY to store device mappings (index -> device path)
declare -A DEVICES_MAP
# Array to hold raw lsblk output lines, used to avoid subshell issues with DEVICES_MAP
DEVICES_INFO=()

# FUNCTION TO LIST AVAILABLE BLOCK DEVICES WITH INDEXES
list_devices() {
    log "Finding devices"
    printf "%3s %-8s %-6s %-12s %-8s %-7s %-10s %s\n" "Idx" "Name" "Size" "Model" "Vendor" "Type" "Mountpoint" "RO"
    printf "%3s %-8s %-6s %-12s %-8s %-7s %-10s %s\n" "---" "--------" "------" "------------" "--------" "-------" "----------" "--"

    local i=1 # Start index from 1

    # Populate DEVICES_INFO with lines from lsblk directly into the parent shell.
    # We exclude common non-physical/ephemeral device types by their major device numbers.
    # -d lists devices only (not partitions).
    # -n suppresses headers.
    mapfile -t DEVICES_INFO < <(lsblk -o NAME,SIZE,MODEL,VENDOR,TRAN,TYPE,MOUNTPOINT,RO -d -n -e 7,11,9,2,259,1)

    # Iterate over the captured lines to print and store mappings
    for line in "${DEVICES_INFO[@]}"; do
        # Use 'read' with a 'here string' to parse each line
        read -r name size model vendor tran type mountpoint ro <<< "$line"

        # Remove '/dev/' prefix if present, though lsblk -o NAME usually gives just sda, sdb etc.
        local clean_name=$(echo "$name" | sed 's|^/dev/||')
        local full_path="/dev/$clean_name"

        # Store the mapping: index -> full device path
        DEVICES_MAP[$i]="$full_path"

        # Print the indexed device information in a formatted way
        printf "%3d %-8s %-6s %-12s %-8s %-7s %-10s %s\n" \
            "$i" "$clean_name" "$size" "$model" "$vendor" "$type" "$mountpoint" "$ro"
        ((i++))
    done
    echo "" # Add a newline for better readability
    echo "Enter 0 to quit."
    echo ""
}

list_devices


# PROMPT FOR INPUTS
SELECTED_INDEX=""

while true; do
    read -p "Select USB device by Idx (e.g., 1): " SELECTED_INDEX
    # Check if input is a number
    if [[ "$SELECTED_INDEX" =~ ^[0-9]+$ ]]; then
        if (( SELECTED_INDEX == 0 )); then
            error "Aborted."
            exit 0 # Exit if user chooses to quit
        elif [[ -n "${DEVICES_MAP[$SELECTED_INDEX]}" ]]; then
            # If a valid index is provided, retrieve the full device path
            DEV="${DEVICES_MAP[$SELECTED_INDEX]}"
            break # Valid selection, exit the loop
        else
            warn "Invalid index. Please enter a number from the list or 0 to quit."
        fi
    else
        warn "Invalid input. Please enter a number."
    fi
done

# Double-check if the selected device exists, though it should if selected from the list
[[ -b "$DEV" ]] || error "Selected block device '$DEV' not found unexpectedly."
USB_PART="${DEV}1"

read -e -p "Path to ISO: " ISO_PATH
[[ -f "$ISO_PATH" ]] || error "ISO not found at '$ISO_PATH'"

read -e -p "Optional path to autoinstall YAML (press Enter to skip): " YAML_PATH
if [[ -n "$YAML_PATH" && ! -f "$YAML_PATH" ]]; then
    error "YAML not found at '$YAML_PATH'"
fi

cat <<EOF

You are about to:

- Wipe & reformat   ➜ $DEV
- Copy ISO          ➜ $ISO_PATH
- Copy autoinstall  ➜ ${YAML_PATH:-Skipped}

EOF

read -p "Proceed? (yes/[no]) " CONFIRM
[[ "$CONFIRM" == "yes" ]] || { log "Aborted."; exit 0; }

# PREP: UNMOUNT
log "Unmounting partitions on $DEV if mounted..."
for p in $(lsblk -lnpo NAME,MOUNTPOINT "${DEV}"* | awk '$2!=""{print $1}'); do
  warn "  umount $p"
  umount "$p" || warn "Could not unmount $p, continuing"
done

# PARTITION & FORMAT
log "Creating single FAT32 partition on $DEV..."
parted --script "$DEV" \
  mklabel msdos \
  mkpart primary fat32 1MiB 100% \
  set 1 boot on

log "Formatting ${USB_PART} as FAT32..."
mkfs.vfat -F32 "$USB_PART"  > /dev/null 2>&1

# MOUNTS
MNT_ISO=$(mktemp -d)
MNT_USB=$(mktemp -d)

log "Mounting ISO -> $MNT_ISO"
mount -o loop "$ISO_PATH" "$MNT_ISO"  > /dev/null 2>&1

log "Mounting USB -> $MNT_USB"
mount      "$USB_PART" "$MNT_USB"

# COPY FILES
log "Copying ISO contents to USB..."

set +e
cp -aT "${MNT_ISO}/." "${MNT_USB}/" > /dev/null 2>&1
CP_STATUS=$?
set -e

if [[ -n "$YAML_PATH" ]]; then
    log "Adding autoinstall.yaml to USB root..."
    cp "$YAML_PATH" "${MNT_USB}/autoinstall.yaml"
else
    log "Skipping autoinstall.yaml copy."
fi

# CLEANUP
log "Syncing and unmounting USB..."
sync "$MNT_USB"
umount "$MNT_USB"

# Force unmount ISO, as it's read-only and doesn't require flushing
log "Unmounting ISO..."
umount -f "$MNT_ISO"

log "Cleaning up mounts..."
rmdir "$MNT_ISO" "$MNT_USB"

log "USB is ready!"
