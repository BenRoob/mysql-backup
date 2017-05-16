#!/bin/bash

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
# TODO swap to a function (create_backup_folders) >> $1 = $NOW
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
# TODO swap to function mysql_dump_structure
echo "Start MySQL-Backup"
echo "dump structure only - disabled !!!"
#mysqldump $DB_PARAMS --no-data --skip-triggers --ignore-table=$DB_NAME.ViewImageSize $DB_NAME > $BACKUP_FOLDER/$DUMP_FILE_STRUCTURE


##
# start data export
# TODO swap to function mysql_dump_data
##
echo "show tables in ${DB_NAME}" | mysql ${DB_PARAMS} ${DB_NAME} > tmp_tables.sql
#cat tmp_tables.sql

while IFS= read -r TABLE; 
do
	#[[ $EXCLUDE_DATA_TABLES =~ (^|[[:space:]])"$TABLE"($|[[:space:]]) ]] && echo 'yes' || echo 'no'
	if grep -Fxq "$TABLE" exclude-tables
	then
		#... found
		echo "${TABLE} ... ignored"
	else
		# ... not found
		echo "${TABLE} ... dump data..."
		#mysqldump $DB_PARAMS $DB_NAME $TABLE --no-create-info > $BACKUP_FOLDER_DATA$TABLE.sql
	fi
done < tmp_tables.sql

# delete tmp file
rm -r tmp_tables.sql

#
# export only triggers, procedures etc.
# TODO swap to function mysql_dump_functions
#echo "dump functions etc..."
#mysqldump $DB_PARAMS --routines --no-create-info --no-data --no-create-db --skip-opt $dbName > $BACKUP_FOLDER$DUMP_FILE_FUNCTIONS

