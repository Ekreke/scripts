#!/bin/bash

# Database configuration
DB_HOST=""
DB_PORT=""
DB_USER="root"
DB_PASSWORD=""
BASE_BACKUP_DIR=""

# List of schemas to backup
SCHEMA_NAMES=(

)

# Iterate through each database for backup
for DB_NAME in "${SCHEMA_NAMES[@]}"; do
    # Generate backup directory based on database name
    BACKUP_DIR="$BASE_BACKUP_DIR/$DB_NAME"
    
    # Ensure backup directory exists
    mkdir -p "$BACKUP_DIR"
    
    # Get current timestamp as backup file prefix
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    
    # Create complete backup file path
    BACKUP_FILE="$BACKUP_DIR/$DB_NAME-$TIMESTAMP.sql.gz"
    
    echo "Starting backup of database: $DB_NAME to directory: $BACKUP_DIR"
    
    # Use mysqldump command to backup database
    mysqldump --set-gtid-purged=OFF -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASSWORD "$DB_NAME" | gzip > "$BACKUP_FILE"
    
    # Check if backup was successful
    if [ $? -eq 0 ]; then
        echo "Database $DB_NAME backup successful, file location: $BACKUP_FILE"
    else
        echo "Database $DB_NAME backup failed"
    fi
done

# Cleanup logic: iterate through all database directories and remove files older than 15 days
for DB_NAME in "${SCHEMA_NAMES[@]}"; do
    BACKUP_DIR="$BASE_BACKUP_DIR/$DB_NAME"
    find "$BACKUP_DIR" -type f -name "*.sql.gz" -mtime +15 -exec rm {} \;
done