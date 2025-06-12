#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
echo "--------------------------------------------------------------------"
echo "                           Start Compose                            "
echo "--------------------------------------------------------------------"
echo "Please provide stack name(s) to start (space-separated) as parameter"
exit 1
fi

command -v docker >/dev/null || {
echo "Error: 'docker' command not found" >&2
exit 1
}

command -v groovy >/dev/null || {
echo "Error: 'groovy' command not found" >&2
exit 1
}

[[ -f app.env ]] || { echo "Error: required file 'app.env' not found" >&2; exit 1; }

composeFiles=()
for component in "$@"
do
	if [ "$component" == 'dnc' ] || [ "$component" == 'scs' ]
	then
		dbName=$component

		if [[ "$component" == "dnc" ]]
			then
				groovy helper/generate_dnc_env_settings_file.groovy -p itg.properties -c "msg-transformation" -e environment.yml -o dnc-saas/env-msg-transformation -h sqlserver -d "$dbName" -l true
			else
				groovy helper/generate_dnc_env_settings_file.groovy -p itg.properties -c "scs-screening" -e environment.yml -o dnc-saas/env-scs-screening -h sqlserver -d "$dbName" -l true
				groovy helper/generate_dnc_env_settings_file.groovy -p itg.properties -c "scs-exceptions" -e environment.yml -o dnc-saas/env-scs-exceptions -h sqlserver -d "$dbName" -l true
		fi

		docker compose --env-file=app.env -f stacks/"$component"-base-compose.yml pull

		if [[ "$component" == "dnc" ]]
			then
				groovy helper/buildDncImage.groovy -c "msg-transformation" -v version.yml -o dnc-saas
			else
				groovy helper/buildDncImage.groovy -c "scs-screening" -v version.yml -o dnc-saas
				groovy helper/buildDncImage.groovy -c "scs-exceptions" -v version.yml -o dnc-saas
		fi
	fi

       if [[ ! -f "stacks/$component-compose.yml" ]]; then
               echo "Error: stacks/$component-compose.yml not found" >&2
               exit 1
       fi
       composeFiles+=("-f" "stacks/$component-compose.yml")
        if [ -e "stacks/$component-compose-disable.yml" ]
        then
               composeFiles+=("-f" "stacks/$component-compose-disable.yml")
        fi
	
done

if ! docker compose --env-file=app.env --profile local "${composeFiles[@]}" up -d --wait; then
    echo "Error: docker compose failed" >&2
    exit 1
fi

# Optional step to import dev cert to dnc-adapter, scs-adapter spot
for component in "$@"
do
	if [[ "$component" == "spot" ]]; then
		./setup_dev_certs.sh
	fi
done
