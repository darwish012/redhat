#!/bin/bash

LV_PATH="/dev/vg_name/lv_ingestion"  # Replace with your actual LV path
MOUNT_DIR=~/ingestion

# Ensure the logical volume and mount point exist
if [ ! -e "$LV_PATH" ]; then
    echo "ERROR: Logical volume $LV_PATH does not exist."
    exit 1
fi

if [ ! -d "$MOUNT_DIR" ]; then
    echo "ERROR: Mount directory $MOUNT_DIR does not exist."
    exit 1
fi

# Ensure it's mounted
if ! mountpoint -q "$MOUNT_DIR"; then
    echo "ERROR: $MOUNT_DIR is not a mount point."
    exit 1
fi

# Get usage %
USAGE=$(df --output=pcent "$MOUNT_DIR" | tail -1 | tr -dc '0-9')

if [ "$USAGE" -ge 90 ]; then
    echo "Usage is $USAGE%. Attempting to extend LV..."

    # Get current size in GB
    CURRENT_SIZE=$(lvs --noheadings --units g -o LV_SIZE "$LV_PATH" | tr -dc '0-9.')

    if [ -z "$CURRENT_SIZE" ]; then
        echo "ERROR: Failed to get current LV size."
        exit 1
    fi

    # Calculate 10% of current size
    EXTEND_BY=$(echo "$CURRENT_SIZE * 0.1" | bc)

    # Check if there is space in the VG
    VG_NAME=$(lvs --noheadings -o VG_NAME "$LV_PATH" | tr -d ' ')
    FREE_SPACE=$(vgs --noheadings --units g -o VG_FREE "$VG_NAME" | tr -dc '0-9.')

    if (( $(echo "$EXTEND_BY > $FREE_SPACE" | bc -l) )); then
        echo "ERROR: Not enough free space in the volume group to extend."
        exit 1
    fi

    # Extend and grow the filesystem
    echo "Extending by ${EXTEND_BY}G..."
    lvextend -L +"${EXTEND_BY}G" "$LV_PATH" && xfs_growfs "$MOUNT_DIR"

    if [ $? -eq 0 ]; then
        echo "Extension successful."
    else
        echo "ERROR: Failed to extend the logical volume or grow the filesystem."
        exit 1
    fi
else
    echo "Usage is $USAGE%. No extension needed."
fi
