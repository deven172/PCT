#!/bin/bash

if [ -z "$1" ]
	then
	echo "-------------------------------------------------"
	echo "               Apply Scenario                    "
	echo "-------------------------------------------------"
	echo "please provide path to scenario file as parameter"
	exit 1
fi

services=""

while IFS= read -r line || [ -n "$line" ]; do
	services="${services}${services:+,}$line"
done < "$1"

echo "applying scenario $1 with enabled services $services"
groovy helper/enable_disable_service.groovy -d stacks -m apply -s $services