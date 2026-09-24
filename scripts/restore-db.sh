#!/usr/bin/env bash
################################
# Developer: Liad Binyamin
# Purpose: Restore the Outline Postgres database from the latest backup
# Version: 0.0.2
# Date: 24.9.26
set -o errexit
set -o pipefail
set -o nounset
################################


SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_DIR/backups"
ENV_FILE="$PROJECT_DIR/.env"

# Read BACKUP_ENCRYPTION_KEY from the .env file - and also checks that it exists and is not empty
load_encryption_key() {
  if [ ! -f "$ENV_FILE" ]; then
        echo "Environment file not found: $ENV_FILE"
        exit 1
  fi

  source "$ENV_FILE"

  if [ -z "$BACKUP_ENCRYPTION_KEY" ]; then
    echo "BACKUP_ENCRYPTION_KEY is missing or empty in $ENV_FILE"
    exit 1
  fi

  export BACKUP_ENCRYPTION_KEY 
}

# Find the newest backup file, exit if none found
find_latest_backup() {
  if ! ls "$BACKUP_DIR"/*.enc > /dev/null 2>&1; then
    echo "No backups found in $BACKUP_DIR"
    exit 1
  fi
  LATEST_BACKUP=$(ls -1t "$BACKUP_DIR"/*.enc | head -n 1)
  echo "Latest backup: $LATEST_BACKUP"
}

# Stop Outline so nothing writes to the database during the restore
stop_outline() {
  docker compose stop outline
}

# Delete the current database and create a new empty one
recreate_database() {
  docker compose exec -T postgres sh -c 'dropdb -U "$POSTGRES_USER" --if-exists "$POSTGRES_DB"'
  docker compose exec -T postgres sh -c 'createdb -U "$POSTGRES_USER" "$POSTGRES_DB"'
}

# Decrypt, decompress, and load the backup into the database
restore_backup() {
  openssl enc -d -aes-256-cbc -pbkdf2 -pass env:BACKUP_ENCRYPTION_KEY -in "$LATEST_BACKUP" \
    | gunzip \
    | docker compose exec -T postgres sh -c 'psql -q -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"'
  echo "Database restored from: $LATEST_BACKUP"
}

# Start Outline again
start_outline() {
  docker compose start outline
}

main() {
  load_encryption_key
  find_latest_backup
  cd "$PROJECT_DIR" # to run docker compose commands from the project root
  stop_outline
  recreate_database
  restore_backup
  start_outline
  echo "Done! Outline is running with the restored database."
}

main