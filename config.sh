#
# DB vars
#
DB_HOST=localhost
DB_PORT=3306
DB_NAME=me
DB_USER=backup_user
DB_PASSWORD=backup_user
#DB_USER=root
#DB_PASSWORD=admin

DB_PARAMS="--host=${DB_HOST} --port=${DB_PORT} -u${DB_USER} -p${DB_PASSWORD}"

BACKUP_DIRECTORY="./dumps/"
DUMP_FILE_STRUCTURE=_dump_structure.sql
DUMP_FILE_FUNCTIONS=_dump_functions.sql

# eclude tables from data dump
EXCLUDE_DUMP_TABLES="./exclude-tables.cnf"
