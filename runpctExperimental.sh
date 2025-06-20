#!/usr/bin/env bash

# Don’t auto‐exit on failures, but still treat unset vars and pipe errors as fatal
set -uo pipefail

PROMPT_ON_ERROR=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --error)
      PROMPT_ON_ERROR=true
      shift
      ;;
    *) break ;;
  esac
done

trap 'error_handler $LINENO $?' ERR

error_handler() {
  local line_no=$1
  local exit_code=$2

  echo
  log_info "⚠️  Warning: command failed at line $line_no (exit code=$exit_code)."

  if [[ "$PROMPT_ON_ERROR" == true ]]; then
    read -rp "Do you want to continue? [y/N]: " choice
    if [[ ! $choice =~ ^[Yy]$ ]]; then
      echo "Aborting."
      exit "$exit_code"
    fi
    echo "Continuing despite the error..."
  fi
}


# === Defaults ===
DRY_RUN=false
PCT_SCRIPT=runPct.sh
ADK_VERSION="latest"                   # Docker image tag for <usecase>-adk
ADK_VERSION_SET=false                  # turned on if user passed -v/--adk-version
USECASE="custom"                             # e.g. "trustpair"
AUTO_YES=false
LOG_LEVEL="info"                       # "info" or "verbose"
DB_PROVISION=""                        # "initialize|i", "dump|d", or "existing|e"
DBUPDATE=false                     # if true, skip Step 1 entirely
CONFIGURE_ADK=false
ENV_SETUP=false                         # if true, run fetchfiles.sh & configgenerate.sh before Step 0
SERVICE_START=false                     # if true start the needed servcies
CLEANUP_PROVISION=""                    # options : all|a(cleanup everything exclude runPct.sh & logs files and folders), containers|c(cleanup all containers & images exclude sqlserver), dbconfigs|d(cleanup sqlserver image and container only), staticdata|s (delete static data)
RUN_TEST=false
CREATE_STATICDATA_DATALOADER=false
REPO_BASE="git@graugitlab01.reval.com:hawaii"
data_loader_repo="git@graugitlab01.reval.com:reval/itg-data-loader.git"
data_loader_path="init_staticdata.sh"
TRIGGER_SYNC=false

HUB_BASE_URL="http://localhost:8282/hub"
HUB_TOKEN_ENDPOINT="/auth/realms/hub-internal/protocol/openid-connect/token"
HUB_SYNC_ENDPOINT="/admin/api/v1/hubadmin/icas/synctenants"

HUB_CLIENT_ID="admin_ui_client"
HUB_CLIENT_SECRET="tH4vqOcWEzXTNDtrFKQRqoAGp3bA08lL"
HUB_GRANT_TYPE="client_credentials"

### Cleanup ###
TARGET_DIRS=("$PWD")  # Directories to clean, current directory
EXCLUDE_FOLDERS=("logs*")
EXCLUDE_PCT_FILES=("runPct.sh" "logs*")
EXCLUDES_DBCONFIGS_FILES=("*.mdf")
IMAGES_TO_KEEP=("mcr.microsoft.com/mssql/server:2022-CU13-ubuntu-20.04")  # Images to preserve
CONTAINERS_TO_KEEP=("sqlserver")  # containers to preserve
EXCLUDES_CONTAINERS=("${CONTAINERS_TO_KEEP[@]/#/!}") # containers to exclude and delete everything
EXCLUDES_IMAGES=("${IMAGES_TO_KEEP[@]/#/!}")  # image to exclude and delete everything


usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Drive the PCT flow for <usecase>-adk, with optional static data init.

Options:
  -u, --usecase VALUE          Name of the usecase (default: "custom", i.e. Skips ADK Docker Image Pull,Static data Creation, Run Test, StaticData CleanUp Steps)
  -v, --adk-version VALUE      ADK Docker image tag (default: "latest")
  -y, --yes                    Automatically accept all prompts
  -l, --log-level VALUE        Log level: 'info' (default) or 'verbose'
  --db-provision VALUE         Database provisioning: initialize|i, dump|d, or existing|e
  --dbUpdate                   Runs dbUpdate other wise skips it
  --env-setup                  Fetches files required for shiftleft setup and configures shiftleft
  -t, --tenant-sync            Trigger tenant sync via Hub Admin API
  -s, --start-services         Start services mentioned in the scenario file
  -r, --run-tests              Run ADK tests
  -d, --create-staticdata      Run dataloader script to create static data
  -configureadk                Configures ADK Tests
  -c, --cleanup VALUE          Run cleanup data with options : all|a(cleanup everything exclude runPct.sh & logs files and folders), containers|c(cleanup all containers & images exclude sqlserver), dbconfigs|d(cleanup only sqlserver image and container), staticdata|s (delete static data)
  -h, --help                   Show this help message and exit
EOF
  exit 0
}

# --- Helpers ---
prompt_step() {
  $AUTO_YES && return 0
  read -rp "$(date '+%Y-%m-%d %H:%M:%S') $1 [y/N]: " c
  [[ $c =~ ^[Yy]$ ]]
}
run_cmd() {
  log_info "$1"
  shift
  if [[ $LOG_LEVEL == "verbose" ]]; then
    "$@"; rc=$?
  else
    "$@" &>/dev/null; rc=$?
  fi
  if (( rc )); then
    log_info "⚠️  Error: '$1' failed with exit code $rc"
  fi
  return $rc
}

run_pushd()  { pushd "$1" &>/dev/null; }
run_popd()   { popd &>/dev/null; }
log_info() {
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}
log_verbose() {
  if [[ "$LOG_LEVEL" == "verbose" ]]; then
    printf '%s [VERBOSE] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
  fi
}

## docker container cleanup function
delete_containers() {
  local ARGS=("$@")
  local INCLUDE_NAMES=()
  local EXCLUDE_NAMES=()

  for arg in "${ARGS[@]}"; do
    if [[ "$arg" == \!* ]]; then
      EXCLUDE_NAMES+=("${arg:1}")  # strip "!" prefix
    else
      INCLUDE_NAMES+=("$arg")
    fi
  done

  log_info "Include filter: ${INCLUDE_NAMES[*]:-"[none]"}"
  log_info "Exclude filter: ${EXCLUDE_NAMES[*]:-"[none]"}"

  # Get all container names
  mapfile -t all_container_names < <(docker ps -a --format '{{.Names}}')

  # Prepare deletion list
  containers_to_delete=()

  for container in "${all_container_names[@]}"; do
    should_delete=true

    # If any excludes match, skip it
    for ex in "${EXCLUDE_NAMES[@]}"; do
      if [[ "$container" == "$ex" ]]; then
        should_delete=false
        break
      fi
    done

    # If include list is non-empty, only include if it matches
    if [ ${#INCLUDE_NAMES[@]} -gt 0 ]; then
      found=false
      for inc in "${INCLUDE_NAMES[@]}"; do
        if [[ "$container" == "$inc" ]]; then
          found=true
          break
        fi
      done
      should_delete=$found
    fi

    $should_delete && containers_to_delete+=("$container")
  done

  if [ ${#containers_to_delete[@]} -eq 0 ]; then
    log_info "No containers to delete (based on filters)."
    return
  fi

  if [[ "$DRY_RUN" == true ]]; then
    log_info "Dry-run: Would delete containers:"
    printf '%s\n' "${containers_to_delete[@]}"
  else
    docker rm -f "${containers_to_delete[@]}"
    log_info "Deleted containers: ${containers_to_delete[*]}"
  fi
}

## docker images cleanup function
delete_images() {
  local ARGS=("$@")
  local INCLUDE_IMAGES=()
  local EXCLUDE_IMAGES=()

  # Split includes and excludes
  for arg in "${ARGS[@]}"; do
    if [[ "$arg" == \!* ]]; then
      EXCLUDE_IMAGES+=("${arg:1}")  # remove the "!" prefix
    else
      INCLUDE_IMAGES+=("$arg")
    fi
  done

  log_info "Include filter: ${INCLUDE_IMAGES[*]:-"[none]"}"
  log_info "Exclude filter: ${EXCLUDE_IMAGES[*]:-"[none]"}"

  # All image IDs
  mapfile -t all_images < <(docker images -q | sort -u)

  # Exclude list -> image IDs
  exclude_ids=()
  if [ ${#EXCLUDE_IMAGES[@]} -gt 0 ]; then
    mapfile -t exclude_ids < <(docker images "${EXCLUDE_IMAGES[@]}" --format '{{.ID}}' 2>/dev/null | sort -u)
  fi

  # Include list -> image IDs
  include_ids=()
  if [ ${#INCLUDE_IMAGES[@]} -gt 0 ]; then
    mapfile -t include_ids < <(docker images "${INCLUDE_IMAGES[@]}" --format '{{.ID}}' 2>/dev/null | sort -u)
  fi

  # Decide what to delete
  images_to_delete=()

  for img in "${all_images[@]}"; do
    # Always skip if in exclude list
    if [[ " ${exclude_ids[*]} " =~ " $img " ]]; then
      continue
    fi

    if [ ${#INCLUDE_IMAGES[@]} -eq 0 ]; then
      # No include list: delete everything (except excluded)
      images_to_delete+=("$img")
    else
      # Include list is provided: delete only matching
      if [[ " ${include_ids[*]} " =~ " $img " ]]; then
        images_to_delete+=("$img")
      fi
    fi
  done

  if [ ${#images_to_delete[@]} -eq 0 ]; then
    log_info "No Docker images to delete (all preserved or none matched)."
    return
  fi

  # Get image names for the selected IDs
  declare -A image_name_by_id
  while IFS= read -r line; do
    img_id=$(awk '{print $1}' <<< "$line")
    img_name=$(awk '{$1=""; print substr($0,2)}' <<< "$line")
    image_name_by_id["$img_id"]="$img_name"
  done < <(docker images --format '{{.ID}} {{.Repository}}:{{.Tag}}')

  # Print & delete
  if [[ "$DRY_RUN" == true ]]; then
    log_info "Dry-run: These images would be deleted:"
    for id in "${images_to_delete[@]}"; do
      echo " - ${image_name_by_id[$id]:-"<unknown>"} ($id)"
    done
  else
    for id in "${images_to_delete[@]}"; do
      echo "Deleting: ${image_name_by_id[$id]:-"<unknown>"} ($id)"
      docker rmi -f "$id"
    done
    log_info "Image deletion completed."
  fi
}

## directory cleanup function which exclude runPct.sh and logs folders
clean_directories() {
  for dir in "$@"; do
    log_info "Cleaning directory: $dir"

    if [ -d "$dir" ]; then
      if $DRY_RUN; then
        log_info "Dry-run: Would delete everything in $dir except:"
        log_info "  - Directories matching: *logs*"
        log_info "  - Files named: runPct.sh"
        find "$dir" -mindepth 1 \
          ! -name "runPct.sh" \
          ! -path "*/logs*" \
          -print
      else
        log_info "Deleting contents of $dir (excluding *logs* folders and runPct.sh files):"
        find "$dir" -mindepth 1 \
          ! -name "runPct.sh" \
          ! -path "*/logs*" \
          -print -exec rm -rf {} +
        log_info "Done cleaning $dir"
      fi
    else
      log_info "Directory does not exist: $dir"
    fi
  done
}

# --- Parse flags ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -u|--usecase)
      USECASE="$2"; shift 2;;
    -v|--adk-version)
      ADK_VERSION="$2"; ADK_VERSION_SET=true; shift 2;;
    -y|--yes)
      AUTO_YES=true; shift;;
    -l|--log-level)
      LOG_LEVEL="$2"; shift 2;;
    --db-provision)
      DB_PROVISION="$2"; shift 2;;
    --dbUpdate)
      DBUPDATE=true; shift;;
    --env-setup)
      ENV_SETUP=true; shift;;
	-t|--tenant-sync)
	TRIGGER_SYNC=true; shift ;;
  -s|--start-services)
	SERVICE_START=true; shift ;;
  -r|--run-tests)
  RUN_TEST=true; shift ;;
  -d|--create-staticdata)
  CREATE_STATICDATA_DATALOADER=true; shift ;;
  -configureadk)
  CONFIGURE_ADK=true; shift ;;
  -c|--cleanup)
	  echo "$2"
	  if [[ -z "$2" || "$2" == -* ]]; then
        echo "Missing value for $1" >&2
        exit 1
      fi
      CLEANUP_PROVISION="$2"
      shift 2
      ;;
    -h|--help)
      usage;;
    *)
      echo "Unknown option: $1" >&2; usage;;
  esac
done

# --- Derived paths & URLs ---
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="${REPO_BASE}/${USECASE}-adk.git"
REPO_DIR="$script_dir/${USECASE}-adk"
SCENARIO_FILE="$script_dir/scenarios/${USECASE}.scenario.txt"
DEST_DIR="$script_dir/pctrun${USECASE}"
STATIC_DIR="$DEST_DIR/staticdata"

logs_dir="$script_dir/pctlogs"
mkdir -p "$logs_dir"
timestamp="$(date '+%Y%m%d_%H%M%S')"
logfile="$logs_dir/pct_${USECASE}_${timestamp}.log"
# redirect all stdout/stderr into the logfile (and still echo to console)
exec > >(tee -a "$logfile") 2>&1

log_info "=== PCT Driver starting (usecase=$USECASE, adk-version=$ADK_VERSION${ADK_VERSION_SET:+ (set)}, log-level=$LOG_LEVEL) ==="

# --- Pre-flight setup ---
log_info "--- Running pre-flight checks ---"

# 1) Install Java if missing
if ! command -v java &>/dev/null; then
  log_info "Java not found. Installing Java..."
  if command -v apt-get &>/dev/null; then
    run_cmd "Installing Java (apt-get)" sudo apt-get update && sudo apt-get install -y default-jdk
  elif command -v yum &>/dev/null; then
    run_cmd "Installing Java (yum)" sudo yum install -y java-11-openjdk-devel
  else
    echo "No supported package manager found for installing Java." >&2
    exit 1
  fi
else
  log_info "--- Java is already installed. ---"
fi

# 2) Install unzip
if ! command -v unzip &>/dev/null; then
  log_info "unzip not found. Installing unzip..."
  if command -v apt-get &>/dev/null; then
    run_cmd "Installing unzip (apt-get)" sudo apt-get install -y unzip
  elif command -v yum &>/dev/null; then
    run_cmd "Installing unzip (yum)" sudo yum install -y unzip
  else
    echo "No supported package manager found for installing unzip." >&2
    exit 1
  fi
else
  log_info "--- unzip is already installed. ---"
fi

# 3) Install jq
if ! command -v jq &>/dev/null; then
  log_info "jq not found. Installing jq..."
  if command -v apt-get &>/dev/null; then
    run_cmd "Installing jq (apt-get)" sudo apt-get install -y jq
  elif command -v yum &>/dev/null; then
    run_cmd "Installing jq (yum)" sudo yum install -y jq
  else
    echo "No supported package manager found for installing jq." >&2
    exit 1
  fi
else
  log_info "--- jq is already installed. ---"
fi

# --- Ensure an SSH key exists ----------------------------------------------
mkdir -p ~/.ssh && chmod 700 ~/.ssh

# Any private key named id_* (excluding *.pub) already there?
if ls ~/.ssh/id_* 2>/dev/null | grep -qv '\.pub$'; then
  log_info "--- SSH key already present in ~/.ssh. ---"
else
  log_info "!--- No SSH key found – generating id_rsa... ---!"
  ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
fi

# 4) Install Groovy if missing
if ! command -v groovy &>/dev/null; then
  log_info "Groovy not found. Installing Groovy..."
  if command -v apt-get &>/dev/null; then
    run_cmd "Installing Groovy (apt-get)" sudo apt-get install -y groovy
  elif command -v yum &>/dev/null; then
    run_cmd "Installing Groovy (yum)" sudo yum install -y groovy
  else
    echo "No supported package manager found for installing Groovy." >&2
    exit 1
  fi
else
  log_info "--- Groovy is already installed. ---"
fi

# 5) Ensure JAVA_HOME is set
if [[ -z "${JAVA_HOME:-}" ]]; then
  JAVA_PATH="$(dirname "$(dirname "$(readlink -f "$(which java)")")")"
  log_info "Setting JAVA_HOME to $JAVA_PATH"
  export JAVA_HOME="$JAVA_PATH"
  echo "export JAVA_HOME=$JAVA_PATH" >> ~/.bashrc
else
  log_info "--- JAVA_HOME is already set to $JAVA_HOME ---"
fi

log_info "--- Running pre-flight checks Complete ---"

# 6) Optional environment setup
if [[ "$ENV_SETUP" == true ]]; then
  log_info "--- env-setup flag detected: running fetchfiles.sh and configgenerate.sh ---"
  git archive --format=tar  --remote=git@gitgraz.reval.com:reval-devops/itg-deployment.git ITG-6662-Rebase:shared/compose setup_fetch_files.sh | tar -x -C "$script_dir"
  chmod +x "$script_dir"/setup_fetch_files.sh
  run_cmd "Fetching files" bash "$script_dir/setup_fetch_files.sh"
  log_info "--- Fetch Files Complete ---"
  run_cmd "Generating config" env AUTO_YES=true bash "$script_dir/config_generate.sh"
  log_info "--- Config Generation for ShiftLeft Setup Complete ---"
fi

get_hub_token() {
  for cmd in curl jq; do
    command -v "$cmd" >/dev/null || {
      echo "Error: '$cmd' is required for tenant-sync" >&2
      return 1
    }
  done

  local curl_cmd="curl -sSf -X POST \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -d client_id=${HUB_CLIENT_ID} \
    -d client_secret=${HUB_CLIENT_SECRET} \
    -d grant_type=${HUB_GRANT_TYPE} \
    ${HUB_BASE_URL}${HUB_TOKEN_ENDPOINT}"

  log_verbose "⇢ ${curl_cmd}" >&2
  HUB_TOKEN=$(eval "$curl_cmd" | jq -er '.access_token') || {
    echo "Error: access_token not found" >&2
    return 1
  }
}

sync_tenants() {
  [[ -z $HUB_TOKEN ]] && { echo "Error: empty token" >&2; return 1; }

  local curl_cmd="curl -sS -o /tmp/sync_resp -w '%{http_code}' \
    -H 'Authorization: Bearer ${HUB_TOKEN}' \
    ${HUB_BASE_URL}${HUB_SYNC_ENDPOINT}"

  log_verbose "⇢ ${curl_cmd}"
  local http_code
  http_code=$(eval "$curl_cmd") || return 1

  if [[ $http_code != 200 ]]; then
    echo "Sync-tenants call failed (HTTP $http_code)" >&2
    cat /tmp/sync_resp >&2
    return 1
  fi

  echo "✔ Tenants synchronised (HTTP 200)"
}

# --- Step 0: Schema setup (db-provision override) ---
provision_choice=""
if [[ -n $DB_PROVISION ]]; then
  case "${DB_PROVISION,,}" in
    initialize|i) provision_choice=1 ;;
    dump|d)       provision_choice=2 ;;
    existing|e)   provision_choice=3 ;;
    *) echo "Warning: unknown --db-provision '$DB_PROVISION'; will prompt interactively." >&2 ;;
  esac
fi

if [[ -n $provision_choice ]]; then
  case $provision_choice in
    1) run_cmd "Init new schema" bash -c "cd \"$script_dir\" && ./database_init.sh" ;;
    2) run_cmd "Restore schema - WIP"   bash -c "cd \"$script_dir\" && ./database_restore.sh" ;;
    3) log_info "Using existing DB; skipping schema setup" ;;
  esac
fi

# --- Step 1: Run DB Update (skip if requested) ---
if [[ "$DBUPDATE" == false ]]; then
  log_info "--- DBUPDATE flag not set -> Skipping dbUpdate ---"
else
  # 1a) Start SQL Server
   log_info "--- DB update flow START ---"
  run_cmd ">>> Starting SQL Server" "$script_dir/service_start.sh" sqlserver

  # 1b) If verbose, show every scenario entry (non-blank, non-comment)
  if [[ "$LOG_LEVEL" == "verbose" ]]; then
    log_verbose "Scenario-file entries from $SCENARIO_FILE:"
    grep -v '^\s*#' "$SCENARIO_FILE" | sed 's/^/    /'
  fi

  # 1c) Gather and apply all “-db-update” steps
  db_updates=$(mktemp)
  set +e
    grep -v '^\s*#' "$SCENARIO_FILE" | grep -E '\-db-update$' > "$db_updates"
  set -e

  if [[ -s "$db_updates" ]]; then
    run_cmd ">>> Applying DB update scenario" \
      "$script_dir/service_scenario_apply.sh" "$db_updates"
  else
    log_info "No DB-update steps found in $SCENARIO_FILE; skipping."
  fi

  rm -f "$db_updates"
  log_info "--- DB update flow END ---"
fi

# --- Step 2: Enable services ---

if $SERVICE_START ; then

  services=$(mktemp)
  # collect all scenario lines except comments and “-db-update” steps
  grep -v '^\s*#' "$SCENARIO_FILE" | grep -Ev '\-db-update$' > "$services"

  if [[ -s "$services" ]]; then
    run_cmd ">>> Enabling services" \
      "$script_dir/service_scenario_apply.sh" "$services"
    run_cmd ">>> Starting services" \
      "$script_dir/service_start.sh" sqlserver hub keycloak spot mock camunda
  else
    log_info "No services found in $SCENARIO_FILE; skipping service startup."
  fi

  rm -f "$services"
fi


# --- Optional tenant-sync trigger ---
if $TRIGGER_SYNC ; then
  log_info ">>> Triggering tenant sync via Hub Admin API"
  set +e
    get_hub_token || true
    sync_tenants
    rc=$?
  set -e
  ((rc)) && echo "Warning: tenant-sync failed (code $rc), continuing…" >&2
fi

if [[ "$USECASE" != "custom" ]]; then
# --- Step 3: Pull Docker image ---
	if $ADK_VERSION_SET; then
	log_info "Auto: pulling Docker image ($USECASE-adk:$ADK_VERSION)"
	run_cmd ">>> Pulling Docker image" docker pull "graudocreg01.reval.com:8091/reval/${USECASE}-adk:$ADK_VERSION"
	else
		run_cmd ">>> Pulling Docker image ($USECASE-adk:latest)" docker pull "graudocreg01.reval.com:8091/reval/${USECASE}-adk:latest"
	fi


# --- Step 4: Prepare test configuration ---
	if $CONFIGURE_ADK ; then
	log_info ">>> Preparing config"
	if [[ -d $REPO_DIR ]]; then
		run_cmd "    - Repo exists, pulling latest" git -C "$REPO_DIR" pull
	else
		run_cmd "    - Cloning repository" git clone "$REPO_URL" "$REPO_DIR"
	fi
	mkdir -p "$DEST_DIR"
	run_cmd "    - Copying configs & data" \
		cp "$REPO_DIR/pctconfig/"*.properties "$DEST_DIR/" && \
		cp -r "$REPO_DIR"/{secretkeys,staticdata,testdata} "$DEST_DIR/" && \
		cp "$REPO_DIR/dockerrun.sh" "$DEST_DIR/"
	log_info ">>> Configuration prepared"
	fi


# --- Step 5: Initialize static data ---
	if $CREATE_STATICDATA_DATALOADER ; then
	log_info ">>> Setting up static data"
	mkdir -p "$STATIC_DIR"
	for cmd in git jq; do
		command -v "$cmd" >/dev/null || { echo "Error: '$cmd' is required." >&2; exit 1; }
	done
	git archive --format=tar --remote="$data_loader_repo" master: "$data_loader_path" | tar -xf - -C "$STATIC_DIR"
	run_cmd "    - chmod +x init script" chmod +x "$STATIC_DIR/$data_loader_path"
	run_cmd "    - Copying env file"       cp "$DEST_DIR/secretkeys/config.sut.env" "$STATIC_DIR/"
	run_cmd "    - Normalizing CRLF"       sed -i 's/\r$//' "$STATIC_DIR/config.sut.env"

	set +e
	run_pushd "$STATIC_DIR"
		if [[ "$LOG_LEVEL" == "verbose" ]]; then
		ENV=sut "./$data_loader_path"
		else
		ENV=sut "./$data_loader_path" &>/dev/null
		fi
	run_popd
	rc=$?
	set -e

	(( rc )) && echo "Error: init_staticdata.sh failed with code $rc, continuing…" >&2
	fi

# --- Step 6: Run dockerrun.sh ---
	if $RUN_TEST ; then
	set +e
		run_cmd ">>> Executing dockerrun.sh" \
		bash -c "cd \"$DEST_DIR\" && chmod +x dockerrun.sh && ./dockerrun.sh $ADK_VERSION"
		rc=$?
	set -e
	((rc)) && echo "Error: dockerrun.sh failed with code $rc, continuing…" >&2
	fi

else
  log_info "=== Running with usecase custom; skipping - ADK Docker Image Pull,Static data Creation, Run Test, StaticData CleanUp Steps. ==="
fi

# --- Step 8: Cleanup ---
cleanup_choice=""
if [[ -n $CLEANUP_PROVISION ]]; then
  case "${CLEANUP_PROVISION,,}" in
    all|a) cleanup_choice=1 ;;
    containers|c)       cleanup_choice=2 ;;
    dbconfigs|d)   cleanup_choice=3 ;;
	staticdata|s)   cleanup_choice=4 ;;
    *) echo "Warning: unknown --cleanup-provision '$CLEANUP_PROVISION'; will prompt interactively." >&2 ;;
  esac
fi

if [[ -n $cleanup_choice ]]; then
  case $cleanup_choice in
    1) 
	  delete_images
	  delete_containers
      clean_directories "${TARGET_DIRS[@]}"
      ;;
    2) 
	  delete_images "${EXCLUDES_IMAGES[@]}"
	  delete_containers "${EXCLUDES_CONTAINERS[@]}"
      ;;
    3) 
	  clean_directories "${TARGET_DIRS[@]/%//sqlserverdata}"
	  delete_containers "${CONTAINERS_TO_KEEP[@]}"
      ;;
	4)
	  # --- Step 7: Cleanup static data ---
	  log_info ">>> Deleting static data via data-loader"
	  git archive --format=tar --remote="$data_loader_repo" master: "$data_loader_path" | tar -xf - -C "$STATIC_DIR"
	  run_cmd "    - chmod +x init script" chmod +x "$STATIC_DIR/$data_loader_path"
	  run_cmd "    - Copying env file"       cp "$DEST_DIR/secretkeys/config.sut.env" "$STATIC_DIR/"
	  run_cmd "    - Normalizing CRLF"       sed -i 's/\r$//' "$STATIC_DIR/config.sut.env"
	  run_pushd "$STATIC_DIR"
		  ENV=sut "./$data_loader_path" --delete $([[ $LOG_LEVEL != verbose ]] && echo "&>/dev/null")
	  run_popd
  esac
fi

log_info "=== PCT Driver completed ==="
