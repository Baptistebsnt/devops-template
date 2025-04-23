#!/bin/bash

# Exit on error
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Function to print status messages
print_status() {
    echo -e "${GREEN}[*] $1${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}[!] $1${NC}"
}

# Default values
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DB_HOST=${DB_HOST:-"localhost"}
DB_PORT=${DB_PORT:-"5432"}
DB_NAME=${DB_NAME:-"app_db"}
DB_USER=${DB_USER:-"postgres"}

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Function to create backup
create_backup() {
    local backup_file="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql"
    
    print_status "Creating backup of $DB_NAME..."
    if pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -F c -b -v -f "$backup_file" "$DB_NAME"; then
        print_status "Backup created successfully: $backup_file"
    else
        print_error "Backup failed"
        exit 1
    fi
}

# Function to restore from backup
restore_backup() {
    local backup_file=$1
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    print_status "Restoring from backup: $backup_file..."
    if pg_restore -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v "$backup_file"; then
        print_status "Restore completed successfully"
    else
        print_error "Restore failed"
        exit 1
    fi
}

# Function to list available backups
list_backups() {
    print_status "Available backups:"
    ls -lh "$BACKUP_DIR"/*.sql 2>/dev/null || print_error "No backups found"
}

# Function to verify backup
verify_backup() {
    local backup_file=$1
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    print_status "Verifying backup: $backup_file..."
    if pg_restore -l "$backup_file" > /dev/null; then
        print_status "Backup verification successful"
    else
        print_error "Backup verification failed"
        exit 1
    fi
}

# Main script
case "$1" in
    "backup")
        create_backup
        ;;
    "restore")
        if [ -z "$2" ]; then
            print_error "Please specify backup file to restore"
            exit 1
        fi
        restore_backup "$2"
        ;;
    "list")
        list_backups
        ;;
    "verify")
        if [ -z "$2" ]; then
            print_error "Please specify backup file to verify"
            exit 1
        fi
        verify_backup "$2"
        ;;
    *)
        echo "Usage: $0 {backup|restore <file>|list|verify <file>}"
        exit 1
        ;;
esac 