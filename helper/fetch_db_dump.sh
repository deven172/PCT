# if [ $# -eq 0 ]
#   then
#       echo "Please supply the environment name from which databses need to be restored. Options: dev, test, perf."
#       exit 1
# fi
# env="$1"
# if [ "$env" == "perf" ]
#  	then
# 		shareName="itgsqlperf"
# 	else
# 		shareName="itgsql1"
# fi

#backupFolderPath="sqlserverbackup/$env"
#mkdir -p "$backupFolderPath"

env="dev"
shareName="itgsql1"
backupFolderPath="$(realpath $(dirname $0))/../sqlserverbackup"

echo "Copying dump files to $backupFolderPath"

cp --verbose -f /mnt/"$shareName"/itg"$env"_banking/FULL/*.bak "$backupFolderPath"/banking.bak
echo "banking.bak copied!!"

cp --verbose -f /mnt/"$shareName"/itg"$env"_banking_ks/FULL/*.bak "$backupFolderPath"/banking_ks.bak
echo "banking_ks.bak copied!!"

cp --verbose -f /mnt/"$shareName"/itg"$env"ce/FULL/*.bak "$backupFolderPath"/camunda.bak
echo "camunda.bak copied!!"

cp --verbose -f /mnt/"$shareName"/itg"$env"cds/FULL/*.bak "$backupFolderPath"/cds.bak
echo "cds.bak copied!!"

cp --verbose -f /mnt/"$shareName"/itg"$env"dnc/FULL/*.bak "$backupFolderPath"/dnc.bak
echo "dnc.bak copied!!"

cp --verbose -f /mnt/"$shareName"/itg"$env"dncadapter/FULL/*.bak "$backupFolderPath"/dnc_adapter.bak
echo "dnc_adapter.bak copied!!"

cp --verbose -f /mnt/"$shareName"/itg"$env"ebics/FULL/*.bak "$backupFolderPath"/ebics.bak
echo "ebics.bak copied!!"

cp --verbose -f /mnt/"$shareName"/itg"$env"ebicsui/FULL/*.bak "$backupFolderPath"/its.bak
echo "its.bak copied!!"

cp --verbose -f /mnt/"$shareName"/itg"$env"hub/FULL/*.bak "$backupFolderPath"/hub.bak
echo "hub.bak copied!!"

cp --verbose -f /mnt/"$shareName"/itg"$env"api/FULL/*.bak "$backupFolderPath"/itgapi.bak
echo "itgapi.bak copied!!"

cp --verbose -f /mnt/"$shareName"/itg"$env"mds/FULL/*.bak "$backupFolderPath"/mds.bak
echo "mds.bak copied!!"

cp --verbose -f /mnt/"$shareName"/itg"$env"hub_scheduler/FULL/*.bak "$backupFolderPath"/scheduler.bak
echo "scheduler.bak copied!!"

cp --verbose -f /mnt/"$shareName"/itg"$env"scs/FULL/*.bak "$backupFolderPath"/scs.bak
echo "scs.bak copied!!"

cp --verbose -f /mnt/"$shareName"/itg"$env"scsadapter/FULL/*.bak "$backupFolderPath"/scs_adapter.bak
echo "scs_adapter.bak copied!!"

echo "Copy of backup file is complete!!"