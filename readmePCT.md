# PCT Experimental Runner

`runpctExperimental.sh` is an all-in-one script that orchestrates the "PCT" testing workflow for a chosen use case. It automates database preparation, service start-up, optional ADK configuration, test execution, and clean-up.

> **Note**: The script performs a number of checks and can install missing tools (Java, unzip, jq, Groovy). It also generates an SSH key if none is available.

## Quick start

```bash
# Make the script executable
chmod +x runpctExperimental.sh

# Run with the default settings
./runpctExperimental.sh -u trustpair -s --db-provision initialize
```

The command above executes the PCT flow for the `trustpair` use case, starts the required services and initializes the schema.

## Options

| Option | Description |
|--------|-------------|
| `-u, --usecase <value>` | Name of the use case. Using `custom` skips Docker image pull and data creation. |
| `-v, --adk-version <value>` | Docker image tag for the use case ADK (default: `latest`). |
| `-y, --yes` | Automatically accept prompts. |
| `-l, --log-level <info\|verbose>` | Control verbosity (default: `info`). |
| `--db-provision <initialize\|dump\|existing>` | How to set up the database. |
| `--dbUpdate` | Runs database update (step 1). |
| `--env-setup` | Fetches ShiftLeft files and prepares configuration. |
| `-t, --tenant-sync` | Trigger tenant sync via the Hub Admin API. |
| `-s, --start-services` | Start services listed in the scenario file. |
| `-r, --run-tests` | Run ADK tests using `dockerrun.sh`. |
| `-d, --create-staticdata` | Create static data using the data loader. |
| `-configureadk` | Prepare configuration for ADK tests. |
| `-c, --cleanup <all\|containers\|dbconfigs\|staticdata>` | Clean up containers, images or static data. |
| `-h, --help` | Show help and exit. |

## Workflow overview

Below diagram summarises the major steps executed by `runpctExperimental.sh`:

```mermaid
flowchart TD
    A[Start] --> B{Pre-flight checks}\n(install tools)
    B --> C[Optional env setup]
    C --> D[Step 0: Schema setup]
    D --> E[Step 1: DB update]
    E --> F[Step 2: Start services]
    F --> G[Optional tenant sync]
    G --> H[Step 3: Pull Docker image]
    H --> I[Step 4: Prepare config]
    I --> J[Step 5: Static data init]
    J --> K[Step 6: Run tests]
    K --> L[Step 7/8: Cleanup]
    L --> M[Complete]
```

Steps are only executed if the corresponding flags are provided. For example, the test phase runs only when `-r` is set.

## Scenario files

Scenario files live in the `scenarios/` directory (e.g. `trustpair.scenario.txt`). They list services or DB update actions to apply. The script filters lines ending in `-db-update` for the database update stage and the rest for service startup.

## Logs

All output is written to `pctlogs/pct_<usecase>_<timestamp>.log`. Review this log if something fails. Use `--log-level verbose` for detailed output.

## Example run

```bash
./runpctExperimental.sh \
  --usecase trustpair \
  --adk-version 1.2.3 \
  --db-provision initialize \
  --start-services \
  --run-tests \
  --cleanup all
```

This runs the entire flow with clean-up at the end.

