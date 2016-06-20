#!/bin/bash

# This script maintains a local incremental backup covering two days. 
# It is intended to run once per day.  
# It is customized to back up OpenStack compute nodes based on the recommendations at:
# http://docs.openstack.org/openstack-ops/content/backup_and_recovery.html
#
# Separate scripts also exist for:
#     - backing up the OpenStack controller
#     - backing up a general server or VM  (requires some configuration)
#     - syncing the backups to a remote location which stores incremental backups

TODAY="$(date -I)"
YESTERDAY="$(date -d '1 day ago' -I)"
LOGDATE="+%Y %b %d %H:%M"

RSYNC_ARGS="-a"
USAGE="Usage Text Here.\n"
VERBOSE=0

#Default # of days to keep
KEEP_DAYS=7

#This functions as a toggle to adjust backup deletion
FAIL_CTR=0

function log {
   if [ "$1" == "-f" ]; then
       printf "%s: %s\n" "$(date "$LOGDATE")" "$2"
   elif [ "$1" == "-e" ]; then
       printf "%s: ERROR: %s\n" "$(date "$LOGDATE")" "$2" >&2
   else
       [ $VERBOSE -ne 0 ] && printf "%s: DEBUG: %s\n" "$(date "$LOGDATE")" "$1"
   fi
}


# -k = number of days to keep
# -v = verbose mode
# -h = help
# -d = backup directory

while getopts ":d:k:vh" opt; do
  case $opt in
    d) if [ -d "$OPTARG" ]; then
           BKP_HOME=$OPTARG
       else
           log -e "directory $OPTARG does not exist."
           exit 1
       fi
       ;;
    k) is_int_regex="^[0-9]+$"
       if [[ $OPTARG =~ $is_int_regex ]]; then
           KEEP_DAYS=$OPTARG
       else
           log -e "invalid number of days to keep: $OPTARG" 
           printf "$USAGE"
           exit 1
       fi
       ;; 
    v) RSYNC_ARGS="${RSYNC_ARGS}v"
       VERBOSE=1
       log "Verbose mode enabled."
       ;;
    h)
       printf "$USAGE"
       exit 0
       ;;
    \?)
       log -e "$0: Invalid option: -$OPTARG"
       printf "$USAGE"
       exit 1
       ;;
    :)
       log -e "$0: Option -$OPTARG requires an argument."
       printf "$USAGE"
       exit 1
       ;;
  esac
done

#Fail if backup directory not defined
if [ -z $BKP_HOME ]; then
    echo "Error: backup directory not defined." >&2
    printf "$USAGE"
    exit 1
fi

#Fail on bogus arguments, otherwise user may assume
# the script is backing something up when it is not. 
#if [[ "$OPTIND" < "$(($#+1))" ]]; then
#        printf "%s: Invalid argument: %s\n" "$0" "${!OPTIND}"
#        printf "$USAGE"
#        exit 1
#fi
log -f "Starting backup of $(hostname -s)"
log "Backup home directory set to: $BKP_HOME."
log "Keeping $KEEP_DAYS days worth of backups."

BKP_DIR="${BKP_HOME}/${TODAY}"
PREV_BKP="${BKP_HOME}/${YESTERDAY}"

log "Backing up to $BKP_DIR"

mkdir -p "${BKP_DIR}/var/lib/"
mkdir -p "${BKP_DIR}/etc/"

#do /var/lib/nova outside the loop so you can exclude /var/lib/nova/instances
rsync $RSYNC_ARGS --delete --link-dest="${PREV_BKP}/var/lib/nova" --exclude="instances/" "/var/lib/nova/" "${BKP_DIR}/var/lib/nova" 
if [[ $? -ne 0 ]]; then
    FAIL_CTR+=1
    log -e "backup of /var/lib/nova failed."
fi


# List of all directories recommended by the OpenStack docs
# Note that not all these directories actually exist in our cluster (this is caught later inside the loop)
DirsToBackup=(  "/etc/nova" \
		"/etc/keystone" \
		"/etc/cinder" \
		"/etc/glance" \
		"/etc/swift" \
		"/var/lib/cinder" \
		"/var/lib/keystone" \
		"/var/lib/glance" )

#Loop through the directories
for thisDir in "${DirsToBackup[@]}"
do
    log "starting backup of $thisDir."
    if [[ -d "$thisDir" ]]; then
	  rsync $RSYNC_ARGS --delete --link-dest="${PREV_BKP}${thisDir}" "${thisDir%/}/" "${BKP_DIR}${thisDir}" 
          if [ $? -ne 0 ]; then
              let FAIL_CTR+=1
              log -e "backup of $thisDir failed." 
          fi
    else
         log "Directory $thisDir does not exist. Skipping."
    fi
done

# Generate a small logfile to help identify this backup
# in case something gets screwed up when we sync to the remote host
printf "Backup of %s created %s.\n" "$(hostname -s)" "$(date "$LOGDATE")" > "${BKP_DIR}/backup.info"

# If today's rsync had errors, keep an extra old backup
if [[ "$FAIL_CTR" -ne "0" ]]; then
    let KEEP_DAYS+=1
    log "Rsync reported $FAIL_CTR failure(s).  Increasing days kept to $KEEP_DAYS."
fi

DELETE_DATE="$(date -d ${KEEP_DAYS}' days ago' -I)"

log "Deleting backups from on or before $DELETE_DATE."

# Delete DELETE_DAY backup and anything older
for checkFile in "$BKP_HOME"/*
do
    fileName=$(basename $checkFile)
    if [[ -d $checkFile ]] && ( [[ "$fileName" < "$DELETE_DATE" ]] || [[ "$fileName" == "$DELETE_DATE" ]] ); then
        log -f "deleting backup: $checkFile"
        rm -r $checkFile
    fi  
done

#Uncomment the redirection if you want to get an email alert every day from every node
log -f "Backup of $(hostname -s) complete." >&2

