#!/bin/bash
set -e

BACKUP_DIR_PATH="/mnt/data/backups"
DB_BACKUP_FILE_PATH="db_backup.sql"
POSTGRES_CONTAINER_NAME="data-db-1"
S3_BUCKET="911archive-wikijs-backups"
WIKIJS_BACKUP_FILE_PATH="wikijs_backup_$(date +%Y-%m-%d).tar.gz"

(
  cd /mnt/data
  docker-compose stop wikijs
)

docker exec -t $POSTGRES_CONTAINER_NAME pg_dumpall -c -U wikijs > $BACKUP_DIR_PATH/$DB_BACKUP_FILE_PATH
tar czf $BACKUP_DIR_PATH/$WIKIJS_BACKUP_FILE_PATH \
  -C /mnt/data/wikijs/data . \
  -C /mnt/data/wikijs/config . \
  -C $BACKUP_DIR_PATH $DB_BACKUP_FILE_PATH
(
  cd /mnt/data
  docker-compose start wikijs
)

aws s3 cp $BACKUP_DIR_PATH/$WIKIJS_BACKUP_FILE_PATH s3://$S3_BUCKET/
