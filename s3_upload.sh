#!/bin/bash

export AWS_ACCESS_KEY_ID="PLEASE_FILL_ME"
export AWS_SECRET_ACCESS_KEY="PLEASE_FILL_ME"
export AWS_MAX_ATTEMPTS=30

# Define log file
LOG_FILE="s3_upload.log"

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Upload to S3 and log the result
aws s3 cp --region us-east-1 "${1}" s3://babcock-av-feeds --cli-read-timeout 120 --cli-connect-timeout 120 >> "$LOG_FILE" 2>&1

if [ $? -eq 0 ]; then
    log "Successfully uploaded ${1}."
    rm "${1}"
    log "Deleted local file ${1} after successful upload."
else
    log "Error: Failed to upload ${1}."
fi
