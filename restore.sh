#!/bin/bash

set -e

if [[ "$#" -ne 1 ]]; then
  echo "Usage: $0 backup_filename.tar.gz"
  exit 1
fi

BACKUP_FILE_NAME=$1
POSTGRES_CONTAINER_NAME="data-db-1"
S3_BUCKET="911archive-wikijs-backups"

(
  cd /mnt/data
  docker-compose stop wikijs
  docker-compose stop db
)

aws s3 cp s3://$S3_BUCKET/$BACKUP_FILE_NAME /mnt/data/backups/$BACKUP_FILE_NAME
tar xzf /mnt/data/backups/$BACKUP_FILE_NAME -C /mnt/data/wikijs

(
  cd /mnt/data
  docker-compose start db
)

DB_BACKUP_FILE_NAME="/mnt/data/wikijs/db_backup.sql"
cat $DB_BACKUP_FILE_NAME | docker exec -i $POSTGRES_CONTAINER_NAME psql -U wikijs -d postgres
systemctl restart wikijs
