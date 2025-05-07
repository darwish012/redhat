#!/bin/bash

# Set variables
DATE=$(date +%d-%m-%Y)
DEST_DIR=~/ingestion/data
URL="https://raw.githubusercontent.com/Badr-AL101/rh2-project-csvs/main/$DATE.csv"
CSV_FILE="$DEST_DIR/$DATE.csv"
COMPRESSED_FILE="$CSV_FILE.gz"

# Create directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Check if mount exists
if ! mountpoint -q ~/ingestion; then
    echo "Ingestion directory is not mounted!"
    exit 1
fi

# Check disk usage
USAGE=$(df --output=pcent ~/ingestion | tail -1 | tr -dc '0-9')
if [ "$USAGE" -ge 90 ]; then
    echo "Ingestion partition is over 90% full. Cancelling download."
    exit 1
fi

# Download the file using wget
wget -q -O "$CSV_FILE" "$URL"

# Verify download and compress
if [ -f "$CSV_FILE" ]; then
    gzip "$CSV_FILE"
    echo "File downloaded and compressed: $COMPRESSED_FILE"
else
    echo "Download failed. File not found: $CSV_FILE"
    exit 1
fi
