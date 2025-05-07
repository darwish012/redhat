#!/bin/bash

LV_PATH="/dev/vg_name/lv_ingestion"   # Replace with your actual LV path
MOUNT_DIR=~/ingestion

# Check usage
USAGE=$(df --output=pcent "$MOUNT_DIR" | tail -1 | tr -dc '0-9')

if [ "$USAGE" -ge 90 ]; then
    echo "Usage is $USAGE%. Attempting to extend LV..."

    # Extend by 10% of current size
    CURRENT_SIZE=$(lvs --noheadings --units G -o LV_SIZE "$LV_PATH" | tr -dc '0-9.')
    EXTEND_BY=$(echo "$CURRENT_SIZE * 0.1" | bc)
    lvextend -L +"${EXTEND_BY}G" "$LV_PATH"

    # Resize filesystem
    xfs_growfs "$MOUNT_DIR"
fi
