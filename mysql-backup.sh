#!/bin/bash

#
# vars
#
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=me
DB_USER=root
DB_PASSWORD=admin

NOW=$(date +'%Y-%m-%d')

#
# includes
#
source ./mysql-backup.conf


DB_PARAMS="--host=${DB_HOST} --port=${DB_PORT} -u${DB_USER} -p${DB_PASSWORD}"
DUMP_FILE_STRUCTURE=${NOW}_dump_structure.sql
DUMP_FILE_FUNCTIONS=${NOW}_dump_functions.sql

#echo $DB_PARAMS
#exit 1

# create folder if not exist
BACKUP_FOLDER="./dumps/${NOW}/"
if [ ! -d $BACKUP_FOLDER ]; 
then
	echo "create backup folder: ${BACKUP_FOLDER}"
	mkdir -p $BACKUP_FOLDER
fi

BACKUP_FOLDER_DATA="${BACKUP_FOLDER}/data/"
if [ ! -d $BACKUP_FOLDER_DATA ];
then
	echo "create backup data folder: ${BACKUP_FOLDER_DATA}"
	mkdir -p $BACKUP_FOLDER_DATA
fi


#
# start dump commands
#
echo "Start MySQL-Backup"
echo "dump structure only"
mysqldump $DB_PARAMS --no-data --skip-triggers $DB_NAME > $BACKUP_FOLDER/$DUMP_FILE_STRUCTURE



echo "dump data for tables in included"
for TABLE in ${INCLUDE_DATA_TABLES[@]}
do :
	echo "dump data from: ${TABLE}"
	mysqldump $DB_PARAMS $DB_NAME $TABLE --no-create-info > $BACKUP_FOLDER_DATA$TABLE.sql
done


# export only triggers, procedures etc.
echo "dump functions etc..."
mysqldump $DB_PARAMS --routines --no-create-info --no-data --no-create-db --skip-opt $dbName > $BACKUP_FOLDER$DUMP_FILE_FUNCTIONS

