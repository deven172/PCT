#!/bin/bash
retval=0

echo "validating liquibase update"
if [ $# -eq 0 ]; then
	docker inspect $(docker ps -a --filter name=db-update$ --format {{.ID}}) --format {{.Name}},{{.State.ExitCode}} | while read res ;
	do
		IFS=',' read -ra strarr <<< "$res"
		if [[ ${strarr[1]} -ne 0 ]]; then
			echo "${strarr[0]} liquibase update failed!"
			retval=1
		else 
			echo "${strarr[0]} liquibase update ok"
		fi
	done
else
    for container in "$@"
	do
		res=$(docker inspect $container --format='{{.State.ExitCode}}')
		if [[ $res -ne 0 ]]; then
		  echo "$container liquibase update failed!"
		  retval=1
		else
		  echo "$container liquibase update ok"
		fi
	done
fi

exit $retval