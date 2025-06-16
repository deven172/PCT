#!/usr/bin/env bash
set -uo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/helper/common.sh"
trap 'log_warn "command failed: $BASH_COMMAND"' ERR

log_info "Starting sql server and creating database tables"
run_cmd "Start sqlserver init" docker compose --env-file=db.env --profile local --profile init -f stacks/sqlserver-compose.yml up -d --force-recreate
run_cmd "Wait for configurator" docker wait sqlserver.configurator
