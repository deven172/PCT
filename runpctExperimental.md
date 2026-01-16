# runpctExperimental.sh

This script drives the PCT flow for a given `<usecase>-adk` Docker image. It orchestrates database provisioning, service startup, optional static data loading and execution of the ADK test suite. The script can run fully interactively or accept command line flags to automate the flow.

## Usage

```bash
./runpctExperimental.sh [OPTIONS]
```

### Options

- `-u, --usecase <name>` – name of the use case (required)
- `-v, --adk-version <tag>` – Docker image tag to use (default: `latest`)
- `-y, --yes` – automatically answer *yes* to all prompts
- `-l, --log-level <level>` – either `info` (default) or `verbose`
- `--db-provision <mode>` – `initialize|i`, `dump|d` or `existing|e`
- `--skip-dbUpdate` – skip the database update step entirely
- `-h, --help` – show the built‑in help

## Workflow

The script performs a sequence of numbered steps. Each step is executed only if the user confirms the prompt (or `--yes` is supplied).

1. **Schema setup** – initialise a new database, restore from backup or use an existing schema. This step invokes `database_init.sh` or `database_restore.sh` as needed.
2. **Run DB Update** – starts SQL Server and applies liquibase updates defined in the scenario file (lines ending with `-db-update`). This step can be skipped with `--skip-dbUpdate`.
3. **Start services** – starts the Docker compose services listed in the scenario file excluding the `-db-update` entries.
4. **Pull Docker image** – pulls the `<usecase>-adk` image from the registry. If `--adk-version` was provided it is pulled automatically, otherwise the version is requested interactively.
5. **Prepare configuration** – clones or updates the `<usecase>-adk` Git repository and copies the configuration files, secret keys, static data and `dockerrun.sh` into a local `pctrun<usecase>` directory.
6. **Create static data** – optionally pulls the `init_staticdata.sh` script from the data‑loader repository and executes it inside the `staticdata` directory.
7. **Run dockerrun.sh** – executes the ADK tests via the `dockerrun.sh` script in the prepared configuration directory.
8. **Cleanup static data** – optionally deletes the static data again using the data‑loader script.

The scenario file must be located at `scenarios/<usecase>.scenario.txt`. It lists the compose stacks used for the chosen use case. Lines ending with `-db-update` are treated as database update containers in step 2 and all other lines are used for starting services in step 3.

`runpctExperimental.sh` logs each action and hides command output unless `--log-level verbose` is used.

## Example

Running the trustpair use case with all prompts enabled:

```bash
./runpctExperimental.sh --usecase trustpair
```

To run non‑interactively with a specific image tag:

```bash
./runpctExperimental.sh -y -u trustpair -v 1.2.3 --db-provision initialize
```

