#!/usr/bin/env bash
################################
# Developer: Liad Binyamin
# Purpose: Backup and encrypt the Outline Postgres database
# Version: 0.0.4
# Date: 24.9.26
set -o errexit
set -o pipefail
set -o nounset
################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_DIR/backups"
ENV_FILE="$PROJECT_DIR/.env"
KEEP=10

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

# Dump the database, compress it, and encrypt it
create_backup() {
  BACKUP_FILE="$BACKUP_DIR/outline-$(date +%Y-%m-%d_%H-%M).sql.gz.enc"

  # Write to a .tmp file first, so a failed backup never looks like a real one
  docker compose exec -T postgres sh -c 'pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB"' \
    | gzip \
    | openssl enc -aes-256-cbc -pbkdf2 -pass env:BACKUP_ENCRYPTION_KEY -out "$BACKUP_FILE.tmp"

  mv "$BACKUP_FILE.tmp" "$BACKUP_FILE"
  echo "$(date): Backup created: $BACKUP_FILE"
}

# Keep the 10 most recent backups, delete the rest
delete_old_backups() {
    count=0

    for file in $(ls -1t "$BACKUP_DIR"/*.enc 2>/dev/null); do
        count=$((count + 1))

        if (( count > KEEP )); then
            rm "$file"
        fi
    done
}

main() {
  load_encryption_key
  cd "$PROJECT_DIR" 
  create_backup
  delete_old_backups
}

main