#!/bin/bash

#
# includes
#
source ./config.sh

#echo $DB_PARAMS
#exit 1
NOW=$(date +'%Y-%m-%d')


##
# backup folders
##
function create_backup_folders() {
    # create folder 
    BACKUP_FOLDER="./dumps/$1/"
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
}

##
# dump structure of database
##
function backup_table_structure() {
    echo "dump structure only"
    mysqldump $DB_PARAMS --no-data --skip-triggers --ignore-table=$DB_NAME.ViewImageSize $DB_NAME > $BACKUP_FOLDER/$DUMP_FILE_STRUCTURE
}

##
# dump tables
##
function backup_table_data() {
    ##
    # start data export
    ##

    # echo all tables in a list as file (temporary)
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
		    mysqldump $DB_PARAMS $DB_NAME $TABLE --no-create-info > $BACKUP_FOLDER_DATA$TABLE.sql
	    fi
    done < tmp_tables.sql

    # delete tmp file
    rm -r tmp_tables.sql
}


##
# export only triggers, procedures etc.
##
function backup_functions() {
    echo "dump functions etc..."
    mysqldump $DB_PARAMS --routines --no-create-info --no-data --no-create-db --skip-opt $dbName > $BACKUP_FOLDER$DUMP_FILE_FUNCTIONS
}

##
#
##
function do_backup() {
    # TODO check date
    echo $1
    DATE=$1
    create_backup_folders $DATE
    backup_table_structure
    backup_functions
    backup_table_data 
}


# TODO check if date is in paramter, default=NOW

do_backup $NOW
exit
