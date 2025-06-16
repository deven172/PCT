#!/usr/bin/env bash
set -uo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/helper/common.sh"
trap 'log_warn "command failed: $BASH_COMMAND"' ERR

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

log_info "applying scenario $1 with enabled services $services"
run_cmd "apply scenario" groovy helper/enable_disable_service.groovy -d stacks -m apply -s $services


