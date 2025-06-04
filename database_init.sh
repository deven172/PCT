#!/bin/bash
echo "Starting sql server and creating database tables"
docker compose --env-file=db.env --profile local --profile init -f stacks/sqlserver-compose.yml up -d --force-recreate
docker wait sqlserver.configurator