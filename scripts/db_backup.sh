#!/bin/bash

BACKUP_DIR="/var/backups/db"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BACKUP_FILE="${BACKUP_DIR}/db_backup_${TIMESTAMP}.sql.gz"

mkdir -p "$BACKUP_DIR"

echo "starting db backup"

if docker exec test-db pg_dump -U devops -d devopsdb | gzip > "$BACKUP_FILE"; then
	echo "backup successful: $BACKUP_FILE"
else
	echo "error: database backup failed."
	rm -f "$BACKUP_FILE"
	exit 1
fi
