#!/usr/bin/env bash
set -euo pipefail

# Determine directory of this script to run relative scripts
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Apply the service scenario
echo "=== Applying service scenario from trustpair.scenario.txt ==="
"${script_dir}/service_scenario_apply.sh" "trustpair.scenario.txt"

# 2. Start the services: spot, mock, hub, sqlserver
echo "=== Starting services: spot, mock, hub, sqlserver ==="
"${script_dir}/service_start.sh" spot mock hub sqlserver

echo "=== All scripts executed successfully ==="
