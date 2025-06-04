#!/usr/bin/env bash
set -euo pipefail

# === Defaults ===
ADK_VERSION="latest"                   # Docker image tag for <usecase>-adk
ADK_VERSION_SET=false                  # turned on if user passed -v/--adk-version
USECASE=""                             # e.g. "trustpair"
AUTO_YES=false
LOG_LEVEL="info"                       # "info" or "verbose"
DB_PROVISION=""                        # "initialize|i", "dump|d", or "existing|e"
SKIP_DBUPDATE=false                    # if true, skip Step 1 entirely
REPO_BASE="git@graugitlab01.reval.com:hawaii"
data_loader_repo="git@graugitlab01.reval.com:reval/itg-data-loader.git"
data_loader_path="init_staticdata.sh"

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Drive the PCT flow for <usecase>-adk, with optional static data init.

Options:
  -u, --usecase           Name of the usecase (required)
  -v, --adk-version VALUE ADK Docker image tag (default: "latest")
  -y, --yes               Automatically accept all prompts
  -l, --log-level VALUE   'info' (default) or 'verbose'
  --db-provision VALUE    initialize|i, dump|d, or existing|e
  --skip-dbUpdate         If set, step 1 (dbUpdate) is skipped entirely
  -h, --help              Show this help message
EOF
  exit 0
}

# --- Helpers ---
prompt_step() { $AUTO_YES && return 0; read -rp "$1 [y/N]: " c; [[ $c =~ ^[Yy]$ ]]; }
run_cmd()    { echo "$1"; shift; if [[ $LOG_LEVEL == verbose ]]; then "$@"; else "$@" &>/dev/null; fi }
safe_run()   { echo ">>> $1"; shift; set +e; "$@"; rc=$?; set -e; ((rc)) && echo "Error: '$1' failed (code $rc), continuing…" >&2; }
run_pushd()  { pushd "$1" &>/dev/null; }
run_popd()   { popd &>/dev/null; }
log_info()   { echo "$1"; }

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
    --skip-dbUpdate)
      SKIP_DBUPDATE=true; shift;;
    -h|--help)
      usage;;
    *)
      echo "Unknown option: $1" >&2; usage;;
  esac
done

if [[ -z $USECASE ]]; then
  echo "Error: --usecase is required" >&2
  usage
fi

# --- Derived paths & URLs ---
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="${REPO_BASE}/${USECASE}-adk.git"
REPO_DIR="$script_dir/${USECASE}-adk"
SCENARIO_FILE="$script_dir/scenarios/${USECASE}.scenario.txt"
DEST_DIR="$script_dir/pctrun${USECASE}"
STATIC_DIR="$DEST_DIR/staticdata"

# Verify that the scenario file exists early so later steps don't fail
if [[ ! -f $SCENARIO_FILE ]]; then
  echo "Error: scenario file '$SCENARIO_FILE' not found." >&2
  exit 1
fi

log_info "=== PCT Driver starting (usecase=$USECASE, adk-version=$ADK_VERSION${ADK_VERSION_SET:+ (set)}, log-level=$LOG_LEVEL) ==="

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
    1) safe_run "Init new $USECASE schema" bash -c "cd \"$script_dir\" && ./database_init.sh" ;;
    2) safe_run "Restore $USECASE schema"   bash -c "cd \"$script_dir\" && ./database_restore.sh" ;;
    3) log_info "Using existing DB; skipping schema setup" ;;
  esac

elif prompt_step "0) Setup schema for '$USECASE': initialize, restore, or use existing?"; then
  echo "    1) Initialize a brand-new schema"
  echo "    2) Restore schema from backup"
  echo "    3) Use existing database (assumes SQL Server is already up)"
  read -rp "Choose [1,2 or 3]: " c
  case $c in
    1) safe_run "Init new $USECASE schema" bash -c "cd \"$script_dir\" && ./database_init.sh" ;;
    2) safe_run "Restore $USECASE schema"   bash -c "cd \"$script_dir\" && ./database_restore.sh" ;;
    3) log_info "Assuming existing DB; skipping schema setup" ;;
    *) echo "Warning: invalid choice, skipping schema setup." >&2 ;;
  esac
fi

# --- Step 1: Run DB Update (skip if requested) ---
if ! $SKIP_DBUPDATE && prompt_step "1) Run dbUpdate for '$USECASE'?"; then
  run_cmd ">>> Starting SQL Server" "$script_dir/service_start.sh" sqlserver
  db_updates=$(mktemp)
  grep -v '^\s*#' "$SCENARIO_FILE" | grep -E '\-db-update$' > "$db_updates"
  run_cmd ">>> Applying DB update scenario" "$script_dir/service_scenario_apply.sh" "$db_updates"
  rm "$db_updates"
elif $SKIP_DBUPDATE; then
  log_info "Skipping Step 1 (dbUpdate) due to --skip-dbUpdate"
fi

# --- Step 2: Enable services ---
if prompt_step "2) Start services for '$USECASE'?"; then
  services=$(mktemp)
  grep -v '^\s*#' "$SCENARIO_FILE" | grep -Ev '\-db-update$' > "$services"
  run_cmd ">>> Starting services" "$script_dir/service_scenario_apply.sh" "$services"
  rm "$services"
fi

# --- Step 3: Pull Docker image ---
if $ADK_VERSION_SET; then
  log_info "Auto: pulling Docker image ($USECASE-adk:$ADK_VERSION)"
  run_cmd ">>> Pulling Docker image" docker pull "graudocreg01.reval.com:8091/reval/${USECASE}-adk:$ADK_VERSION"
else
  if prompt_step "3) Pull Docker image for '$USECASE'?"; then
    read -rp "Enter ADK version to pull (default: latest): " input_ver
    ADK_VERSION="${input_ver:-latest}"
    run_cmd ">>> Pulling Docker image ($USECASE-adk:$ADK_VERSION)" \
      docker pull "graudocreg01.reval.com:8091/reval/${USECASE}-adk:$ADK_VERSION"
  fi
fi

# --- Step 4: Prepare test configuration ---
if prompt_step "4) Prepare configuration?"; then
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
if prompt_step "5) Create static data using data-loader?"; then
  log_info ">>> Setting up static data"
  mkdir -p "$STATIC_DIR"
  for cmd in git jq; do
    command -v "$cmd" >/dev/null || { echo "Error: '$cmd' is required." >&2; exit 1; }
  done
  git archive --format=tar --remote="$data_loader_repo" master: "$data_loader_path" \
    | tar -xf - -C "$STATIC_DIR"
  run_cmd "    - chmod +x init script" chmod +x "$STATIC_DIR/$data_loader_path"
  run_cmd "    - Copying env file" cp "$DEST_DIR/secretkeys/config.sut.env" "$STATIC_DIR/"
  run_cmd "    - Normalizing CRLF" sed -i 's/\r$//' "$STATIC_DIR/config.sut.env"
  set +e
    run_pushd "$STATIC_DIR"
    ENV=sut "./$data_loader_path" $([[ $LOG_LEVEL != verbose ]] && echo "&>/dev/null")
    run_popd
    rc=$?
  set -e
  ((rc)) && echo "Error: init_staticdata.sh failed with code $rc, continuing…" >&2
fi

# --- Step 6: Run dockerrun.sh ---
if prompt_step "6) Run ADK tests?"; then
  set +e
    run_cmd ">>> Executing dockerrun.sh" \
      bash -c "cd \"$DEST_DIR\" && chmod +x dockerrun.sh && ./dockerrun.sh $ADK_VERSION"
    rc=$?
  set -e
  ((rc)) && echo "Error: dockerrun.sh failed with code $rc, continuing…" >&2
fi

# --- Step 7: Cleanup static data ---
if prompt_step "7) Cleanup static data after run?"; then
  log_info ">>> Deleting static data via data-loader"
  run_pushd "$STATIC_DIR"
    ENV=sut "./$data_loader_path" --delete $([[ $LOG_LEVEL != verbose ]] && echo "&>/dev/null")
  run_popd
fi

log_info "=== PCT Driver completed ==="
