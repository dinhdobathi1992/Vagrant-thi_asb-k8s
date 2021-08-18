#!/bin/bash
SERVER_NAME=gdrive
REMOTE_NAME=data
cwd=$(pwd)
DATE=`date +%Y-%m-%d`
TIMESTAMP=$(date +%F)
BAK_DIR=/home/vagrant/data-backup/
BACKUP_DIR=${BAK_DIR}/${TIMESTAMP}
POSTGRES_USER="postgresadmin"
BACKUP_USER="vagrant"
POSTGRES_DB=postgresdb
POSTGRES_PASSWORD=admin@123
rclone=/usr/sbin/rclone
POD=$(kubectl get pod -l app=postgres  -o jsonpath="{.items[0].metadata.name}")

# Make sure we're running as the required backup user
if [ "$BACKUP_USER" != "" -a "$(id -un)" != "$BACKUP_USER" ]; then
	echo "This script must be run as $BACKUP_USER. Exiting." 1>&2
	exit 1;
fi;

mkdir -p "$BACKUP_DIR/postgres"

echo "Starting Backup Database";
kubectl exec ${POD} -- bash -c "pg_dump -U ${POSTGRES_USER} ${POSTGRES_DB}" | gzip > ${BACKUP_DIR}/postgres/database-${DATE}.sql.gz
echo "Finished";
echo '';

echo "Finished";
echo '';

echo "Starting compress file";
size1=$(du -sh ${BACKUP_DIR} | awk '{print $1}')
cd ${BAK_DIR}
tar -czf database-${DATE}".tgz" $TIMESTAMP
rm -rf ${BACKUP_DIR}
echo "Finished";
echo '';

echo "Starting Backup Uploading";
$rclone copy ${BAK_DIR}/database-${DATE}.tgz "$SERVER_NAME:$REMOTE_NAME"

$rclone -q delete --min-age 1m "$SERVER_NAME:$REMOTE_NAME" #remove all backups older than 1 week
find ${BAK_DIR} -mindepth 1 -mtime +6 -delete
echo "Finished";
echo '';

duration=$SECONDS
echo "Total $size2, $(($duration/60)) minutes and $(($duration%60)) seconds elapsed."
