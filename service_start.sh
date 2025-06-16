#!/usr/bin/env bash
set -uo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/helper/common.sh"
trap 'log_warn "command failed: $BASH_COMMAND"' ERR
if [ $# -eq 0 ]
  then
	echo "--------------------------------------------------------------------"
	echo "                           Start Compose                            "
	echo "--------------------------------------------------------------------"
	echo "Please provide stack name(s) to start (space-separated) as parameter" 
	exit 1
fi

composeFiles=""
for component in "$@"
do
	if [ "$component" == 'dnc' ] || [ "$component" == 'scs' ]
	then
		dbName=$component

		if [[ "$component" == "dnc" ]]
			then
                run_cmd "generate msg-transformation env" \
                  groovy helper/generate_dnc_env_settings_file.groovy -p itg.properties -c "msg-transformation" -e environment.yml -o dnc-saas/env-msg-transformation -h sqlserver -d "$dbName" -l true
			else
                                run_cmd "generate scs env" \
                                  groovy helper/generate_dnc_env_settings_file.groovy -p itg.properties -c "scs-screening" -e environment.yml -o dnc-saas/env-scs-screening -h sqlserver -d "$dbName" -l true
                                run_cmd "generate scs exceptions env" \
                                  groovy helper/generate_dnc_env_settings_file.groovy -p itg.properties -c "scs-exceptions" -e environment.yml -o dnc-saas/env-scs-exceptions -h sqlserver -d "$dbName" -l true
		fi

                run_cmd "docker pull base $component" docker compose --env-file=app.env -f stacks/"$component"-base-compose.yml pull

		if [[ "$component" == "dnc" ]]
			then
                                run_cmd "build dnc msg-transformation" \
                                  groovy helper/buildDncImage.groovy -c "msg-transformation" -v version.yml -o dnc-saas
			else
                                run_cmd "build scs-screening" \
                                  groovy helper/buildDncImage.groovy -c "scs-screening" -v version.yml -o dnc-saas
                                run_cmd "build scs-exceptions" \
                                  groovy helper/buildDncImage.groovy -c "scs-exceptions" -v version.yml -o dnc-saas
		fi
	fi

	composeFiles+=" -f stacks/$component-compose.yml"
	if [ -e "stacks/$component-compose-disable.yml" ]
	then
		composeFiles+=" -f stacks/$component-compose-disable.yml"
	fi
	
done

run_cmd "start compose" docker compose --env-file=app.env --profile local $composeFiles up -d --wait

# Optional step to import dev cert to dnc-adapter, scs-adapter spot
for component in "$@"
do
	if [[ "$component" == "spot" ]]; then
                run_cmd "setup dev certs" ./setup_dev_certs.sh
	fi
done

