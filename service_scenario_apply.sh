#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "-------------------------------------------------"
    echo "               Apply Scenario                    "
    echo "-------------------------------------------------"
    echo "please provide path to scenario file as parameter"
    exit 1
fi

scenario_file="$1"

if [[ ! -f $scenario_file ]]; then
    echo "Error: scenario file '$scenario_file' not found" >&2
    exit 1
fi

if [[ ! -s $scenario_file ]]; then
    echo "Error: scenario file '$scenario_file' is empty" >&2
    exit 1
fi

[[ -f helper/enable_disable_service.groovy ]] || {
    echo "Error: helper/enable_disable_service.groovy not found" >&2
    exit 1
}

command -v groovy >/dev/null || {
    echo "Error: 'groovy' command not found" >&2
    exit 1
}

services=""
while IFS= read -r line || [[ -n $line ]]; do
    services="${services}${services:+,}$line"
done < "$scenario_file"

echo "applying scenario $scenario_file with enabled services $services"
groovy helper/enable_disable_service.groovy -d stacks -m apply -s "$services"

