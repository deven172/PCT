#!/usr/bin/env bash
set -euo pipefail

usage="Usage: $(basename "$0") [-f folder] [-d db1,db2] [-c] [-y]"

command -v docker >/dev/null || { echo "Error: 'docker' command not found" >&2; exit 1; }
command -v curl >/dev/null || { echo "Error: 'curl' command not found" >&2; exit 1; }

for f in app.env db.env stacks/sqlserver-compose.yml; do
    [[ -f $f ]] || { echo "Error: required file '$f' not found" >&2; exit 1; }
done

share="\\\\itgauto1.eng.wallstreetsystems.com\\dbbackup"
mntPoint="/mnt/dbbackup"

# Parse input parameters
usage="$(basename "$0") [-f] [-d] [-c] [-y] [-h]

where:
    -f  Source folder to fetch db-backup from share \\$share (default: default)
    -d  comma-separated list of databases to be restored (default: all)
        Supported databases are - hub, camunda, itgapi, mds, scheduler, ebics, banking, banking_ks, cds, dnc_adapter, dnc, scs, its
    -c  Use option to fetch copy of db-backup from source path
    -y  Continue restore without yes/no prompt
    -h  Help text"

while getopts :hycf:d: flag
do
    case "${flag}" in
        f) folder=${OPTARG};;
        d) dblist=${OPTARG};;
        c) fetchbackup=Y;;
        y) skipRestorePrompt=Y;;
        h) echo -e "\n$usage"
           exit 0;;
        ?) echo -e "\n$usage"
           exit 1;;
    esac
done

shift $((OPTIND-1))
[[ $# -eq 0 ]] || { echo "$usage" >&2; exit 1; }

check_source_folder() {
    echo -e "Checking source folder path.. "
    if [ ! -e "$1" ]; then
        echo "Path not found - $2"
        exit 1
    else
        echo "Path Ok."
    fi
}

validate_db_back_up_files() {
    IFS=','
    echo -e "\nChecking database back up files.. "
    for db in $1;  do
        echo "$3\\$db.bak"

        if [ "$db" != 'hub' ] && [ "$db" != 'camunda' ] && [ "$db" != 'itgapi' ] && [ "$db" != 'mds' ] && [ "$db" != 'scheduler' ] \
        && [ "$db" != 'ebics' ] && [ "$db" != 'banking' ] && [ "$db" != 'banking_ks' ] && [ "$db" != 'cds' ] && [ "$db" != 'dnc_adapter' ] \
        && [ "$db" != 'dnc' ] && [ "$db" != 'scs' ] && [ "$db" != 'its' ]
        then
            echo "Invalid database name - $db. Please choose from allowed list of values."
            exit 1
        fi
        if [ ! -e "$2/$db.bak" ]; then
            echo "Back up file not found - $3\\$db.bak"
            exit 1
        else
        echo "Back up file Ok."
        fi
    done
    unset IFS
}

# Interactive shell for default case with no parameters
HORIZONTALLINE="============================================================"
echo -e "$HORIZONTALLINE"
echo "                     RESTORE DATABASES"
echo -e "$HORIZONTALLINE"

# Input source folder
if [ $# -eq 0 ]
then
 echo -en "\n1. Enter source folder to fetch db-backup from share path \\$share [default: default] : \n"
 read -r folder
fi

if [ -z "$folder" ] ; then
    folder="default"
fi

# Input fetch option
if [ $# -eq 0 ]
then
    echo -en "2. Do you want to fetch copy of db-back from the source path [Y/N] [default: N] ? : \n"
    read -r fetchbackup
fi

if [ -z "$fetchbackup" ]; then
    fetchbackup=N
else
   if [ "$fetchbackup" != 'Y' ] && [ "$fetchbackup" != 'y' ] && [ "$fetchbackup" != 'n' ] && [ "$fetchbackup" != 'N' ]
    then
        echo "Invalid input.";
        exit 1
    fi
fi

# Input list of db-names
if [ $# -eq 0 ]
then
 echo -en "3. Enter comma-separated list of databases to be restored [default: all]. To restore specific database(s), choose from - hub, camunda, itgapi, mds, scheduler, ebics, banking, banking_ks, cds, dnc_adapter, dnc, scs, its : \n"
 read -r dblist
 echo -e "\n$HORIZONTALLINE"
fi

if [ -z "$dblist" ] || [ "$dblist" == 'all' ]
then
    dblist="hub,camunda,itgapi,mds,scheduler,ebics,banking,banking_ks,cds,dnc_adapter,dnc,scs,its"
fi

echo -e "\nValidating arguments..\n"
check_source_folder "$mntPoint/$folder" "$share\\$folder"
validate_db_back_up_files "$dblist" "$mntPoint/$folder" "$share\\$folder"

# Restore prompt
echo -e "Validaton done !!"
echo -e "\n$HORIZONTALLINE\n"
echo -e "Will start restore process with below options...\n"
echo -e "Source folder to fetch db-backups from share path    : \\$share\\$folder";
echo -e "Databases to be restored                             : $dblist";
echo -e "Fetch copy of the backup-up files                    : $fetchbackup";

if [ -z "$skipRestorePrompt" ] || [ "$skipRestorePrompt" != 'Y' ]
then
    printf '\nDo you wish to start restore [Y/N] [default: Y] ? :'
    read -r restoreConfirm
    else 
    restoreConfirm='Y'
fi

if [ -z "$restoreConfirm" ]; then
    restoreConfirm='Y'
fi

if [[ "$restoreConfirm" != "${restoreConfirm#[Yy]}" ]]
then
    if [ "$fetchbackup" != "${fetchbackup#[Yy]}" ]
    then
        echo -e "\nStarting to fetch db backup.. "
        backupFolderPath="$(realpath "$(dirname "$0")")/sqlserverbackup"
        IFS=','
        for db in $dblist;  do
            echo -e "\nCopying \\$share\\$folder\\$db.bak to $backupFolderPath/$db.bak.."
            if ! curl --fail-with-body -o "$backupFolderPath/$db.bak" FILE://"$mntPoint/$folder/$db.bak"; then
                echo "Error: failed to fetch backup for $db" >&2
                exit 1
            fi
            echo "$db.bak copied!!"
        done
        unset IFS
    fi

    echo -e "\nStopping all components.. "
    docker compose --env-file=app.env --project-directory stacks/ down

    echo -e "\nRestoring databases from backup.. "
    sed -i "s/^SQLSERVER_RESTORE_DBNAMES=.*/SQLSERVER_RESTORE_DBNAMES=$dblist/" db.env
    if ! docker compose -v --env-file=db.env --profile local --profile restore -f stacks/sqlserver-compose.yml up -d --force-recreate; then
        echo "Error: docker compose restore failed" >&2
        exit 1
    fi
    if ! docker wait sqlserver.dbrestore >/dev/null; then
        echo "Error: sqlserver.dbrestore container failed" >&2
        exit 1
    fi
fi
