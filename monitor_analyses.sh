#!/bin/bash

# This script monitors the disk usage of a specified mount point and automatically
# extends the logical volume and filesystem if the usage exceeds 90%.
# It is designed to work with ext4 filesystems using the `resize2fs` command.

# Define the logical volume path and mount directory
LV_PATH="/dev/vg_data/lv_analyses"  # Replace with your actual analyses LV path
MOUNT_DIR=/root/analyses  # Replace with your actual mount directory

# Check if the logical volume exists
# This ensures that the specified logical volume path is valid
if [ ! -e "$LV_PATH" ]; then
    echo "ERROR: Logical volume $LV_PATH does not exist."
    exit 1
fi

# Check if the mount directory exists
# This ensures that the directory where the volume is mounted exists
if [ ! -d "$MOUNT_DIR" ]; then
    echo "ERROR: Mount directory $MOUNT_DIR does not exist."
    exit 1
fi

# Check if the mount directory is actually mounted
# This ensures that the directory is a valid mount point
if ! mountpoint -q "$MOUNT_DIR"; then
    echo "ERROR: $MOUNT_DIR is not mounted."
    exit 1
fi

# Get the current disk usage percentage of the mount point
# This checks how full the filesystem is
USAGE=$(df --output=pcent "$MOUNT_DIR" | tail -1 | tr -dc '0-9')

# Check if the usage exceeds 90%
# If the usage is too high, attempt to extend the logical volume
if [ "$USAGE" -ge 90 ]; then
    echo "Usage is $USAGE%. Attempting to extend analyses LV..."

    # Get the current size of the logical volume in GB
    # This determines how much space is currently allocated
    CURRENT_SIZE=$(lvs --noheadings --units g -o LV_SIZE "$LV_PATH" | tr -dc '0-9.')

    # Exit if the current size could not be determined
    if [ -z "$CURRENT_SIZE" ]; then
        echo "ERROR: Could not determine current LV size."
        exit 1
    fi

    # Calculate 10% of the current size to determine the extension size
    # This calculates how much additional space to allocate
    EXTEND_BY=$(echo "$CURRENT_SIZE * 0.1" | bc)

    # Get the volume group name and free space available in the volume group
    # This ensures there is enough space to extend the logical volume
    VG_NAME=$(lvs --noheadings -o VG_NAME "$LV_PATH" | tr -d ' ')
    FREE_SPACE=$(vgs --noheadings --units g -o VG_FREE "$VG_NAME" | tr -dc '0-9.')

    # Check if there is enough free space in the volume group to extend
    if (( $(echo "$EXTEND_BY > $FREE_SPACE" | bc -l) )); then
        echo "ERROR: Not enough free space in the VG to extend."
        exit 1
    fi

    # Extend the logical volume and grow the filesystem
    # This increases the size of the logical volume and resizes the filesystem
    echo "Extending $LV_PATH by ${EXTEND_BY}G..."
    lvextend -L +"${EXTEND_BY}G" "$LV_PATH" && resize2fs "$LV_PATH"

    # Check if the extension and resizing were successful
    if [ $? -eq 0 ]; then
        echo "Analyses LV successfully extended."
    else
        echo "ERROR: Extension or filesystem resize failed."
        exit 1
    fi
else
    # If usage is below 90%, no action is needed
    echo "Usage is $USAGE%. No extension needed."
fi
