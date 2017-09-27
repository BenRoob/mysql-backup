#!/bin/bash
# TODO docs, info...

NOW=$(date +'%Y-%m-%d')

#
# includes
#
source ./config.sh


##
# backup folders
##
function create_backup_dirs() {
    # create folder 
    BACKUP_DIR="$BACKUP_DIRECTORY/$1"
    if [ ! -d $BACKUP_DIR ]; 
    then
	    echo "create backup dir: ${BACKUP_DIR}"
	    mkdir -p $BACKUP_DIR
    fi

    BACKUP_DIR_DATA="${BACKUP_DIR}/data"
    if [ ! -d $BACKUP_DIR_DATA ];
    then
		echo "create backup data dir: ${BACKUP_DIR_DATA}"
		mkdir -p $BACKUP_DIR_DATA
	fi
}

##
# dump structure of database
##
function backup_table_structure() {
    echo "dump structure only"
    
    DATE=$1
    if [ -z $DATE  ] 
    then
        echo "ERROR: date must not be empty"
        exit
    fi   
    mysqldump $DB_PARAMS --no-data --skip-triggers --ignore-table=$DB_NAME.ViewImageSize $DB_NAME > $BACKUP_DIR/${DATE}$DUMP_FILE_STRUCTURE
}

##
# dump tables
##
function backup_table_data() {
    # echo all tables in a list as file (temporary)
    echo "show tables in ${DB_NAME}" | mysql ${DB_PARAMS} ${DB_NAME} > tmp_tables.sql
    #cat tmp_tables.sql

    while IFS= read -r TABLE; 
    do
	    #[[ $EXCLUDE_DATA_TABLES =~ (^|[[:space:]])"$TABLE"($|[[:space:]]) ]] && echo 'yes' || echo 'no'
	    if grep -Fxq "$TABLE" $EXCLUDE_DUMP_TABLES
	    then
		    #... found
		    echo "${TABLE} ... ignored"
	    else
		    # ... not found
		    echo "${TABLE} ... dump data..."
		    mysqldump $DB_PARAMS $DB_NAME $TABLE --ignore-table=$DB_NAME.ViewImageSize --no-create-info > $BACKUP_DIR_DATA/$TABLE.sql
	    fi
    done < tmp_tables.sql

    # delete tmp file
    rm -r tmp_tables.sql
}


##
# export only triggers, procedures etc.
##
function backup_functions() {
    echo "dump triggers, procedures etc..."
    DATE=$1
    if [ -z $DATE  ] 
    then
        echo "ERROR: date must not be empty"
        exit
    fi
    mysqldump $DB_PARAMS --routines --no-create-info --no-data --no-create-db --skip-opt --ignore-table=$DB_NAME.ViewImageSize $DB_NAME > $BACKUP_DIR/${DATE}${DUMP_FILE_FUNCTIONS}
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

    create_backup_dirs $DATE
    backup_table_structure $DATE
    backup_functions $DATE
    backup_table_data
}


function check_backup_dirs() {
    # directory exists?
    BACKUP_DIR="$BACKUP_DIRECTORY/$1/"
    if [ ! -d $BACKUP_DIR ];
    then
        echo "Error: backup directory does not exist: ${BACKUP_FOLDER}"
        exit
    fi

    # data directory exists?
    BACKUP_DIR_DATA="${BACKUP_DIR}data/"
    if [ ! -d $BACKUP_DIR_DATA ];
    then
        echo "Error: backup data directory does not exist: ${BACKUP_FOLDER_DATA}"
        exit
    fi
}


function create_database() {

    echo "Creating database $DB_NAME:"
    RESULT=`mysql $DB_PARAMS --skip-column-names -e "SHOW DATABASES LIKE '${DB_NAME}'"`
    if [ "$RESULT" == "$DB_NAME" ]; then
        echo "Database already exists..."
    else
        echo "Database does not exist - create $DB_NAME ..."
        mysql $DB_PARAMS -e 'CREATE DATABASE IF NOT EXISTS `${DB_NAME}` CHARACTER SET utf8 COLLATE utf8_general_ci'
    fi
}

##
# import table structure file to DB schema
##
function import_table_structure() {
	echo "import_table_structure $DATE"
	# check date
    DATE=$1 
    if [ -z $DATE ]
    then
        echo "Error: option date must not by empty!"
        exit
    fi
   
   
    IMPORT_STRUCTURE_FILE=$BACKUP_DIRECTORY$DATE/${DATE}${DUMP_FILE_STRUCTURE}
    if [ ! -f $IMPORT_STRUCTURE_FILE ];
    then
        echo "${IMPORT_STRUCTURE_FILE} not found in backup directory!"
        exit
    fi


    read -r -p "Are you sure to override the structure for config: ${DB_PARAMS}? [y/N] " RESPONSE
    case "$RESPONSE" in
         [yY][eE][sS]|[yY]) 
            echo "import... structure"
            mysql $DB_PARAMS $DB_NAME < $IMPORT_STRUCTURE_FILE
            echo "finish import structure"
           ;;
        *)
            echo "import_table_structure exit..."
            exit;
            ;;
    esac
}


function confirm_import_table_data() {

    read -r -p "Are you sure to override the data for config: ${DB_PARAMS}? [y/N] " RESPONSE
    case "$RESPONSE" in
         [yY][eE][sS]|[yY]) 
            true
           ;;
        *)
            false
            ;;
    esac
}


function import_table_data() {
    DATE=$1
    echo "import_table_structure $DATE"
    if [ -z $DATE ]
    then
        echo "Error: option date must not by empty!"
        exit
    fi

    BACKUP_DATA_DIR=${BACKUP_DIRECTORY}${DATE}/data/
    if [ ! -d $BACKUP_DATA_DIR ];
    then
        echo "${BACKUP_DATA_DIR} must exist!"
        exit
    fi


    for TABLE_DATA_FILE in `ls $BACKUP_DATA_DIR`;
    do
        echo $TABLE_DATA_FILE
        # extract table name 
        FILENAME=$(basename "$TABLE_DATA_FILE")
        #EXTENSION="${FILENAME##*.}"
        TABLE_NAME="${FILENAME%.*}"

		## check is not neccessary, due to not exporting table data if data is exluded while dump process
        if grep -Fxq "$TABLE_NAME" $EXCLUDE_DUMP_TABLES
        then
            echo "import ignored for table data file: ${FILENAME}"
        else
            echo "import table data for: ${TABLE_NAME}";
            mysql $DB_PARAMS $DB_NAME < "$BACKUP_DATA_DIR/$TABLE_DATA_FILE"
        fi
    done
}


function do_restore() {
    DATE=$1
    echo "do_restore $DATE"
    if [ -z $DATE ]
    then
        echo "Error: option date must not by empty!"
        exit
    fi

    # check if restore folder exists
    check_backup_dirs $DATE
    create_database
    import_table_structure $DATE
    confirm_import_table_data && import_table_data $DATE
    # TODO restore functions
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
OPTION_DATE=$NOW
shift
while getopts ":t:" OPTION; do
    case $OPTION in
        t)
            echo "-t was triggered, parameter: $OPTARG" >&2
            OPTION_DATE=$OPTARG
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
        do_restore $OPTION_DATE
        ;;
esac

exit
