#!/bin/bash
if [ $# -eq 0 ]
  then
	echo "-------------------------------------------------------------------"
	echo "                           Stop Compose                            "
	echo "-------------------------------------------------------------------"
	echo "Please provide stack name(s) to stop (space-separated) as parameter" 
	exit 1
fi

composeFiles=""
for component in "$@"
do
	composeFiles+=" -f stacks/$component-compose.yml"
done

docker compose --env-file=app.env $composeFiles down