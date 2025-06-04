#!/bin/bash
set -f

if [ $# -eq 0 ]
  then
	groovy helper/enable_disable_service.groovy -d stacks -m show
	exit 0
fi


if [[ -z "$1" || -z "$2" ]]  
then
	echo "-------------------------------------------------------"
	echo "               Enable / Disable Services               "
	echo "-------------------------------------------------------"
	echo "Please provide"
	echo " - enable/disable as first parameter"
	echo " - comma separated list of services as second parameter"
	exit 1
fi

groovy helper/enable_disable_service.groovy -d stacks -m $1 -s $2