# Compose Files Overview

This document describes the Docker Compose stacks and helper scripts found in this repository. Use these tools to create and manage local instances of the ITG services.

## Compose stacks

All compose files reside in the `stacks/` directory. Each YAML file groups one or more services.

- `adminui-compose.yml` – Admin UI containers
- `beat-compose.yml` – Filebeat, Metricbeat and Logstash
- `camunda-compose.yml` – Camunda engine, worker, app and deploy servers
- `dnc-compose.yml` and `scs-compose.yml` – Message transformation and sanctions screening services
- `ebicsui-compose.yml` – EBICS UI containers
- `hub-compose.yml` – Hub, MQ and Scheduler
- `keycloak-compose.yml` – Keycloak identity provider
- `mock-compose.yml` – Mock services
- `spot-compose.yml` – Spot services
- `sqlserver-compose.yml` – Local SQL Server instance

For database maintenance there are matching stacks prefixed with `db-update-` (for example `db-update-hub-compose.yml`). These stacks contain liquibase update containers for their respective services.

## Environment files

Running `./config_generate.sh` creates the files `app.env` and `db.env` in the repository root. They hold the environment variables used by Docker Compose. The script relies on `itg.properties`, `version.yml` and `environment.yml` to generate the necessary settings using the helper Groovy scripts in `helper/`.

## Database scripts

Several helper scripts operate on the local SQL Server instance:

- `database_init.sh` – start SQL Server and create the required schemas
- `database_restore.sh` – restore databases from backup files
- `database_update.sh <stack>` – run liquibase updates using the `db-update-*` stacks

## Managing services

The following shell scripts orchestrate the compose stacks:

- `service_start.sh <stack ...>` – start one or more stacks
- `service_stop.sh <stack ...>` – stop running stacks
- `service_enable_disable.sh enable|disable <service list>` – toggle individual services defined in the compose files
- `service_scenario_apply.sh <scenario file>` – apply a scenario listing services to run

Example scenarios can be found in `trustpair.scenario.txt` and `trustpairdbupdate.scenario.txt`.

## Typical workflow

1. Generate configuration and environment files with `./config_generate.sh`.
2. Start the required stacks, e.g. `./service_start.sh hub keycloak`.
3. When finished, stop them using `./service_stop.sh hub keycloak`.
4. Use the database scripts when initialising or updating the schemas.

