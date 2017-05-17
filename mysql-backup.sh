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
    #echo "do_backup arg1=$1"
    #exit
    DATE=$1
    if [ -z $DATE  ] 
    then
        echo "ERROR: date must not be empty"
        exit
    fi

    create_backup_folders $DATE
    backup_table_structure
    backup_functions
    backup_table_data 
}


##
# read command from options
##
COMMAND=0
case $1 in
    "dump")
        #echo "Command: dump"
        COMMAND=1
        ;;
    "restore")
        #echo "Command: restore"
        COMMAND=2
        ;;
    *)
        echo "invalid command specified {dump|restore}!."
        exit 1
        ;;
esac


##
# other options
##
OPTION_A=0
shift
while getopts ":a:" OPTION; do
    case $OPTION in
        a)
            echo "-a was triggered, parameter: $OPTARG" >&2
            OPTION_A=$OPTARG
            ;;
        \?)
            echo "Invalid  option: -$OPTARG" >&2
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            ;;
    esac
done


##
# start database command
##
case $COMMAND in
    1)
        echo "dumping database ${DB_NAME}..."
        do_backup $NOW
        ;;
    2)
        echo "restore databse ${DB_NAME}..."
        ;;
esac

exit
