#!/bin/sh
set -e # Exit immediately if a command exits with a non-zero status.

# Construct the repository path from environment variables passed by docker-compose
REPO="sftp:${SFTP_USER}@${SFTP_HOST}:${SFTP_PATH}"

# 1. Run the backup
# -----------------
echo "--- Starting backup for ${BACKUP_SOURCE} ---"
restic backup /source --verbose -r "${REPO}"
echo "--- Backup complete ---"

# 2. Clean up old snapshots according to the policy
# --------------------------------------------------
echo "--- Pruning old snapshots --- 
(Policy: keep last 7 daily, 4 weekly, 6 monthly)"
restic forget \
    --prune \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 6 \
    -r "${REPO}"

echo "--- Backup and prune process finished successfully ---"
