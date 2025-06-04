#!/bin/bash

if [ $# -eq 0 ]
  then
	echo "---------------------------------------------------------------------"
	echo "                           Update Database                           "
	echo "---------------------------------------------------------------------"
	echo "Please provide stack name(s) to update (space-separated) as parameter" 
	exit 1
fi

for component in "$@"
do
	echo "updating database for $@"
	if [ "$component" == 'keycloak' ] 
	then
		echo "Keycloak updates the Db during container startup, no extra update required"
	elif [ "$component" == 'ebicsui' ]
	then
		echo "EbicsUi DB requires smartupdate, please run ebicsui-smartupdate.ps1 in powershell outside of WSL"
	elif [ "$component" == 'dnc' ] || [ "$component" == 'scs' ]
	then		
		dbName="$component"
		component="$component-update"

		groovy helper/generate_dnc_env_settings_file.groovy -p itg.properties -c "$component" -e environment.yml -o dnc-saas/env-"$component" -h sqlserver -d "$dbName" -l true

		if [ "$component" == "dnc-update" ]
			then
				groovy helper/fetch_itg_data_package.groovy -v version.yml -o dnc-saas/itg-data-package.zip -d local
				cd dnc-saas
				unzip -o itg-data-package.zip 
				cd ..
				rm dnc-saas/itg-data-package.zip
		fi

		docker compose --env-file=db.env -f stacks/"$dbName"-base-compose.yml pull "$dbName"-db-update-base
		groovy helper/buildDncImage.groovy -c "$component" -v version.yml -o dnc-saas
		docker compose --env-file=db.env -f stacks/db-update-"$dbName"-compose.yml up -d
		echo "Sleeping for 5 minutes..."
		sleep 300
		docker cp "$component":/autoconfX/latest/solution/environment.tmpl.yml templates/environment.tmpl.yml
		groovy helper/update_dnc_env_file.groovy -p itg.properties -t templates/environment.tmpl.yml -o templates/environment.tmpl.yml
		docker cp templates/environment.tmpl.yml "$component":/autoconfX/latest/solution/environment.tmpl.yml
		docker exec -i --workdir /autoconfX/latest "$component" ./install-solution prepare
		docker exec -i --workdir /autoconfX/latest "$component" ./install-solution --exclude-playbooks initDB
		docker exec -i --workdir /autoconfX/latest "$component" ./data-loader load-all --force
		docker compose --env-file=db.env -f stacks/db-update-"$dbName"-compose.yml down
	else
		composeFiles="-f stacks/db-update-$component-compose.yml"
		if [ -e "stacks/db-update-$component-compose-disable.yml" ]
		then
			composeFiles+=" -f stacks/db-update-$component-compose-disable.yml"
		fi
		
		docker compose --env-file=db.env $composeFiles up --force-recreate
		pushd helper || return
		./db-update-validate.sh
		popd || return
		docker compose --env-file=db.env -f stacks/db-update-"$component"-compose.yml down
	fi
done