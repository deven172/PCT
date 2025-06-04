# PCT Repository

This repository contains a single shell script, `runpctExperimental.sh`, used to orchestrate running a PCT ("Platform Configuration Test" or similar) flow for a given use case. The script automates database preparation, service startup, Docker image management, configuration provisioning, and optional static data setup before running tests via `dockerrun.sh`.

## Repository Contents

- `runpctExperimental.sh` – Bash script that drives the PCT workflow.
- `README.md` – This documentation file.

## Prerequisites

The script expects the following tools to be installed and available in your `PATH`:

- Bash (script uses `bash` features and should run on Unix-like systems)
- Docker
- Git
- `jq` (only needed when initializing static data)

It also assumes several helper scripts exist in the same directory:

- `database_init.sh` and `database_restore.sh` – for schema initialization or restoration.
- `service_start.sh` and `service_scenario_apply.sh` – for starting services and applying scenarios.
- A scenario description file named `<usecase>.scenario.txt` located in a `scenarios/` directory describing service steps and DB update steps.

These helper files are **not** provided in this repository, so they must be obtained separately for the script to work.

## Usage

```bash
./runpctExperimental.sh --usecase <usecase> [options]
```

### Common options

- `-v`, `--adk-version <tag>` – Docker image tag for the `<usecase>-adk` image (default: `latest`).
- `-y`, `--yes` – Automatically answer "yes" to all prompts.
- `-l`, `--log-level <info|verbose>` – Set log verbosity (default: `info`).
- `--db-provision <initialize|dump|existing>` – Control schema setup without prompting.
- `--skip-dbUpdate` – Skip the DB update step entirely.

Run `./runpctExperimental.sh --help` to see the full list of options.

### Example

```bash
./runpctExperimental.sh --usecase trustpair --adk-version 2.3.0
```

The script will interactively perform the following steps:

1. **Schema setup** – initialize or restore the database schema.
2. **DB update** – apply update scripts if not skipped.
3. **Service enablement** – start the services defined in `scenarios/<usecase>.scenario.txt`.
4. **Docker image retrieval** – pull the appropriate `<usecase>-adk` Docker image.
5. **Configuration preparation** – clone `<usecase>-adk` from the configured repository, copy configuration files, and create a working directory (`pctrun<usecase>`).
6. **Static data initialization** – (optional) download the data loader and run `init_staticdata.sh` to seed test data.
7. **Run tests** – execute `dockerrun.sh` in the prepared directory.
8. **Cleanup static data** – (optional) delete the static data using the data loader.

Each step requires user confirmation unless `--yes` is supplied or an overriding option (such as `--db-provision`) is provided.

## Configuration Files and Directories

- **Repository base** – The script clones `<usecase>-adk` from a repository base defined in `REPO_BASE` (currently set to `git@graugitlab01.reval.com:hawaii`). Adjust this variable if using a different host.
- **Working directory** – Files are copied to `pctrun<usecase>` under the script directory. This contains configuration files, test data, and the downloaded `dockerrun.sh` script.
- **Static data** – When step 5 is selected, the data loader (`init_staticdata.sh`) is obtained from `itg-data-loader.git` and executed in `pctrun<usecase>/staticdata`.

## Notes

- The script uses `set -euo pipefail` for strict error handling.
- Commands are executed quietly unless `--log-level verbose` is chosen.
- On errors during the data loader or `dockerrun.sh`, the script prints a warning and continues.

This repository only includes the main driver script. Refer to your organisation's documentation for the helper scripts and scenario files required to run the full PCT workflow.
