#!/usr/bin/env bash
set -uo pipefail

LOG_LEVEL=${LOG_LEVEL:-info}

log_warn() {
  echo "⚠️  $*" >&2
}

log_info() {
  [[ $LOG_LEVEL != quiet ]] && echo "$@"
}

log_verbose() {
  [[ $LOG_LEVEL == verbose ]] && echo "[VERBOSE] $@"
}

run_cmd() {
  local msg=$1
  shift
  log_info "$msg"
  "$@"
  local rc=$?
  if ((rc!=0)); then
    log_warn "$msg failed with exit code $rc"
  fi
  return $rc
}

run_pushd()  { pushd "$1" >/dev/null; }
run_popd()   { popd >/dev/null; }

