#!/bin/bash
retval=0

if [ $# -eq 0 ]; then
	containerId=$(docker ps -a --filter label=com.docker.compose.project=itg --filter label=service.type=app --format {{.ID}})
	if [[ -n $containerId ]]; then
		while read res ;
		do
			IFS=',' read -ra strarr <<< "$res"
			if [[ ${strarr[1]} != "running" ]]; then
				printf '%-30s %s\n' "${strarr[0]}" "${strarr[1]}"
				retval=1
			else
				printf '%-30s %s\n' "${strarr[0]}" "${strarr[2]}" 
				if [[ ${strarr[2]} != "healthy" ]]; then
					retval=1
				fi
			fi
		done < <(docker inspect --format {{.Name}},{{.State.Status}},{{.State.Health.Status}} $containerId)
	fi
else
	for component in "$@"
	do
		containerId=$(docker ps -a --filter label=com.docker.compose.project=itg --filter label=service.type=app --filter label=service.description=$component --format {{.ID}})
		if [[ -n $containerId ]]; then
			while read res ;
			do
				IFS=',' read -ra strarr <<< "$res"
				if [[ ${strarr[1]} != "running" ]]; then
					printf '%-30s %s\n' "${strarr[0]}" "${strarr[1]}"
					retval=1
				else
					printf '%-30s %s\n' "${strarr[0]}" "${strarr[2]}" 
					if [[ ${strarr[2]} != "healthy" ]]; then
						retval=1
					fi
				fi
			done < <(docker inspect --format {{.Name}},{{.State.Status}},{{.State.Health.Status}} $containerId)
		fi 
	done
fi

exit $retval