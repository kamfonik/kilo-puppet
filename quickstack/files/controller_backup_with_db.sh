#!/bin/bash

# This script maintains a local full backup. It is intended to run once per day.  
# It is customized to back up OpenStack controller nodes based on the recommendations at:
# http://docs.openstack.org/openstack-ops/content/backup_and_recovery.html
#
# Separate scripts also exist for:
#     - backing up the OpenStack compute nodes
#     - backing up a general server or VM  (requires some configuration)
#     - syncing the backups to a remote location which stores incremental backups
#
# To maintain security, you must pass this script the database user and password from the cronjob that runs it.
#
# USAGE:
#	./controller_backup.sh -u <username> -p <password> [-d database1]
#
# The optional argument -d may be specified more than once.
# If no databases are specified, --all-databases is invoked.
#

USAGE="USAGE: $0 -u <username> -p <password> [-d \"database1\"]\n\tOptional argument -d may be passed more than once.\n\tIf no databases are specified, --all-databases is invoked.\n"
DB_LIST=""

while getopts ":u:p:d:h" opt; do
  case $opt in
    u)
      DB_USR=$OPTARG
      ;;
    p)
      DB_PWD=$OPTARG
      ;;
    d)
      DB_LIST="${DB_LIST}${OPTARG} "
      ;;
    h)
      printf "$USAGE"
      exit 0
      ;;
    \?)
      printf "%s: Invalid option: -%s\n" "$0" "$OPTARG" >&2
      printf "$USAGE"
      exit 1
      ;;
    :)
      printf "%s: Option -%s requires an argument." "$0" "$OPTARG" >&2
      printf "$USAGE"
      exit 1
      ;;
  esac
done

#Fail on bogus arguments, otherwise user may assume
# the script is backing something up when it is not. 
if [[ "$OPTIND" < "$(($#+1))" ]]; then
        printf "%s: Invalid argument: %s\n" "$0" "${!OPTIND}"
        printf "$USAGE"
        exit 1
fi

BKP_HOME="/backups"
TIMESTAMP="$(date -I)"
YESTERDAY="$(date -d '1 day ago' -I)"
DELETE_DATE="$(date -d '2 days ago' -I)"

BKP_DIR="${BKP_HOME}/${TIMESTAMP}"
PREV_BKP="${BKP_HOME}/${YESTERDAY}"
DELETE_BKP="${BKP_HOME}/${DELETE_DATE}"

# mysqldump fails unless this already exists...
mkdir -p "${BKP_DIR}"

# Dump the MySQL database(s) 
if [[ -z "$DB_LIST" ]]; then
    DB_LIST= "--all-databases"
fi

DB_BKP="${BKP_DIR}/mysql-$(hostname -s).sql"
/usr/bin/mysqldump -u $DB_USR  -p$DB_PWD $DB_LIST > $DB_BKP

# Loop through the directories we need
DirsToBackup=(  "/etc/nova" \
		"/etc/keystone" \
		"/etc/cinder" \
		"/etc/glance" \
		"/var/lib/nova" \
                "/var/lib/glance" \
		"/var/log/keystone" \
		"/var/log/cinder" \
		"/var/log/glance" )


for thisDir in "${DirsToBackup[@]}"
do
    mkdir -p "${BKP_DIR}${thisDir}" 
    rsync -av --delete --link-dest="${PREV_BKP}${thisDir}" "${thisDir%/}/" "${BKP_DIR}${thisDir}" $DRY
done

# Generate a small logfile to help identify this backup
# in case something gets screwed up when we sync to the remote host
printf "Backup of %s created %s.\n" "$(hostname -s)" "$(date '+%Y %b %d %H:%M')" > "${BKP_DIR}/backup.info"

# Delete the oldest backup
echo "removing ${DELETE_BKP}"
rm -rf "${DELETE_BKP}"

echo "Done!"
