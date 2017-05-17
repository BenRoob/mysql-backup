#
# DB vars
#
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=me
DB_USER=root
DB_PASSWORD=admin

DB_PARAMS="--host=${DB_HOST} --port=${DB_PORT} -u${DB_USER} -p${DB_PASSWORD}"
DUMP_FILE_STRUCTURE=${NOW}_dump_structure.sql
DUMP_FILE_FUNCTIONS=${NOW}_dump_functions.sql


# tables to export
INCLUDE_DATA_TABLES=(
table_name_1
table_name_2
)


# eclude tables from data dump
EXCLUDE_DATA_TABLES=(
BerichtServiceRequest
AktionServiceRequest
ErrorLog
DebugLog
ImageData
ImageThumbnail
)
