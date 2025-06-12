#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $(basename "$0")" >&2
    exit 1
}

[[ $# -eq 0 ]] || usage

command -v docker >/dev/null || {
    echo "Error: 'docker' command not found" >&2
    exit 1
}

for f in db.env stacks/sqlserver-compose.yml; do
    [[ -f $f ]] || { echo "Error: required file '$f' not found" >&2; exit 1; }
done

echo "Starting sql server and creating database tables"
if ! docker compose --env-file=db.env --profile local --profile init -f stacks/sqlserver-compose.yml up -d --force-recreate; then
    echo "Error: docker compose failed" >&2
    exit 1
fi

if ! docker wait sqlserver.configurator >/dev/null; then
    echo "Error: sqlserver.configurator container failed" >&2
    exit 1
fi

