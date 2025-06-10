#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-utils.sh
# Purpose: Shared Rotkeeper helper functions and runtime sanity wrappers
# Version: 0.2.4-dev
# Updated: 2025-05-31
# -----------------------------------------


set -euo pipefail
IFS=$'\n\t'

# --- Global Flags ---
DRY_RUN=false
VERBOSE=false
HELP=false

# Parse common flags: --dry-run, --verbose, --help
parse_flags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)   DRY_RUN=true; shift ;;
      --verbose)   VERBOSE=true; shift ;;
      --help|-h)   HELP=true; shift ;;
      *) break ;;
    esac
  done
}

# Default help handler (can be overridden by scripts)
show_help() {
  log "INFO" "No help available for this command."
  exit 0
}

# Logging function: prints timestamped messages and writes to $LOG_FILE if set
log() {
  local level="$1"; shift
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  local msg="[$ts] [$level] $*"
  echo "$msg"
  [[ -n "${LOG_FILE:-}" ]] && echo "$msg" >> "$LOG_FILE"
}

# Runner: dry-run and verbose wrapper for commands
run() {
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log "DRY-RUN" "$*"
  else
    [[ "$VERBOSE" == true ]] && log "INFO" "$*"
    command "$@"
  fi
}

# Require explicitly listed command-line tools (use in main scripts)
require_bins() {
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      log "ERROR" "Missing required dependency: $cmd"
      exit 2
    fi
  done
}

# Check all core binary dependencies used by Rotkeeper scripts
check_dependencies() {
  require_bins bash pandoc sha256sum
  require_yq_version
  require_gawk_version
}

# Require yq version 4.x or higher (Go-based CLI)
require_yq_version() {
  if ! yq eval '.foo' <<< 'foo: bar' >/dev/null 2>&1; then
    log "ERROR" "yq version 4.x required. Install from https://github.com/mikefarah/yq"
    exit 2
  fi
}

# Require GNU awk (gawk) instead of macOS/BSD awk
require_gawk_version() {
  if ! awk --version 2>&1 | grep -qi 'GNU Awk'; then
    log "ERROR" "GNU Awk required. Install it via: brew install gawk"
    exit 2
  fi
}

# Error trap: report error line and exit
trap_err() {
  log "ERROR" "Error on line ${1:-unknown}"
  exit 2
}

# Cleanup hook: override in scripts to perform teardown
cleanup() {
  :
}

set_traps() {
  trap 'trap_err $LINENO' ERR
  trap 'cleanup' EXIT INT TERM
}

# Load rc-env.sh from script root
source_rc_env() {
  local ENV_FILE="$(dirname "${BASH_SOURCE[0]:-$0}")/rc-env.sh"
  if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
  else
    log "WARN" "rc-env.sh not found at $ENV_FILE"
  fi
}

# Initialize log file with script name
init_log() {
  local name="${1:-$(basename "$0" .sh)}"
  LOG_FILE="bones/logs/${name}-$(date +%Y-%m-%d_%H%M).log"
  mkdir -p "$(dirname "$LOG_FILE")"
}

# Return script directory
resolve_script_dir() {
  cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

# Check if file has YAML frontmatter
has_frontmatter() {
  local file="$1"
  grep -q '^---' "$file"
}

# Extract value from YAML frontmatter key (primitive)
get_yaml_key() {
  local key="$1"
  local file="$2"
  awk -v k="$key" '$0 ~ "^"k":" {print $2; exit}' "$file"
}

# List markdown files in a directory
list_md_files() {
  find "$1" -type f -name '*.md'
}

# Require env vars to be set
require_env_vars() {
  for var in "$@"; do
    if [[ -z "${!var:-}" ]]; then
      log "ERROR" "Required env var not set: $var"
      exit 1
    fi
  done
}

# Auto-load environment unless explicitly skipped
: "${ROT_SKIP_ENV:=false}"
if [[ "$ROT_SKIP_ENV" != true ]]; then
  source_rc_env
fi