#!/bin/bash

# This script monitors the disk usage of a specified mount point and automatically
# extends the logical volume and filesystem if the usage exceeds 90%.
# It is designed to work with ext4 filesystems using the `resize2fs` command.

# Define the logical volume path and mount directory
LV_PATH="/dev/vg_name/lv_ingestion"  # Replace with your actual logical volume path
MOUNT_DIR=~/ingestion  # Replace with your actual mount directory

# Ensure the logical volume exists
if [ ! -e "$LV_PATH" ]; then
    echo "ERROR: Logical volume $LV_PATH does not exist."
    exit 1
fi

# Ensure the mount directory exists
if [ ! -d "$MOUNT_DIR" ]; then
    echo "ERROR: Mount directory $MOUNT_DIR does not exist."
    exit 1
fi

# Ensure the mount directory is actually mounted
if ! mountpoint -q "$MOUNT_DIR"; then
    echo "ERROR: $MOUNT_DIR is not a mount point."
    exit 1
fi

# Get the current disk usage percentage of the mount point
USAGE=$(df --output=pcent "$MOUNT_DIR" | tail -1 | tr -dc '0-9')

# Check if the usage exceeds 90%
if [ "$USAGE" -ge 90 ]; then
    echo "Usage is $USAGE%. Attempting to extend LV..."

    # Get the current size of the logical volume in GB
    CURRENT_SIZE=$(lvs --noheadings --units g -o LV_SIZE "$LV_PATH" | tr -dc '0-9.')

    # Exit if the current size could not be determined
    if [ -z "$CURRENT_SIZE" ]; then
        echo "ERROR: Failed to get current LV size."
        exit 1
    fi

    # Calculate 10% of the current size to determine the extension size
    EXTEND_BY=$(echo "$CURRENT_SIZE * 0.1" | bc)

    # Check if there is enough free space in the volume group to extend
    VG_NAME=$(lvs --noheadings -o VG_NAME "$LV_PATH" | tr -d ' ')
    FREE_SPACE=$(vgs --noheadings --units g -o VG_FREE "$VG_NAME" | tr -dc '0-9.')

    if (( $(echo "$EXTEND_BY > $FREE_SPACE" | bc -l) )); then
        echo "ERROR: Not enough free space in the volume group to extend."
        exit 1
    fi

    # Extend the logical volume and grow the filesystem
    echo "Extending by ${EXTEND_BY}G..."
    lvextend -L +"${EXTEND_BY}G" "$LV_PATH" && resize2fs "$LV_PATH"

    # Check if the extension and resizing were successful
    if [ $? -eq 0 ]; then
        echo "Extension successful."
    else
        echo "ERROR: Failed to extend the logical volume or grow the filesystem."
        exit 1
    fi
else
    # If usage is below 90%, no action is needed
    echo "Usage is $USAGE%. No extension needed."
fi
