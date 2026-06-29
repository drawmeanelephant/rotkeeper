#!/usr/bin/env bash
# ============================================================
#  ██╗   ██╗████████╗██╗██╗     ███████╗
#  ██║   ██║╚══██╔══╝██║██║     ██╔════╝
#  ██║   ██║   ██║   ██║██║     ███████╗
#  ██║   ██║   ██║   ██║██║     ╚════██║
#  ╚██████╔╝   ██║   ██║███████╗███████║
#   ╚═════╝    ╚═╝   ╚═╝╚══════╝╚══════╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-utils.sh
#  Purpose : Shared Rotkeeper helper functions and runtime sanity wrappers
#  Version : 0.4.0
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

set -euo pipefail
IFS=$'\n\t'


# --- Global Flags ---
DRY_RUN=false
VERBOSE=false
QUIET=true
DEBUG=false
HELP=false

# Parse common flags: --dry-run, --verbose, --help
# ---
# parse_flags: Interprets the whispered command-line flags (--dry-run, --verbose, --help)
# Inputs: $@ (all arguments)
# Outputs: Modifies global DRY_RUN, VERBOSE, HELP flags
# ---
# Interprets the whispered command-line flags (--dry-run, --verbose, --help)
parse_flags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --version|-v) echo "$(basename "$0") v${VERSION:-unknown}"; exit 0 ;;
      --dry-run)   DRY_RUN=true; shift ;;
      --verbose)   VERBOSE=true; QUIET=false; shift ;;
      --quiet)     QUIET=true; shift ;;
      --debug)     DEBUG=true; VERBOSE=true; QUIET=false; shift ;;
      --help|-h)   HELP=true; shift ;;
      *) break ;;
    esac
  done
}

# Default help handler (can be overridden by scripts)
# ---
# show_help: Displays the eternal void (default help text) if a script has no manual
# ---
# Displays the eternal void (default help text) if a script has no manual
if ! declare -f show_help > /dev/null; then
  show_help() {
    log "INFO" "No help available for this command."
    exit 0
  }
fi

# Logging function: prints timestamped messages and writes to $LOG_FILE if set
# ---
# log: Writes timestamped missives to the console and to the sacred $LOG_FILE
# Inputs: $1 (Level: INFO, ERROR, WARN), $2+ (Message)
# ---
log() {
  local level="$1"; shift
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  local msg="[$ts] [$level] $*"

  # Three-tier verbosity filter for standard stdout
  if [[ "$level" == "MARKER" ]]; then
    echo "$*" >&3
  elif [[ "$QUIET" == true && ( "$level" == "INFO" || "$level" == "DEBUG" || "$level" == "WARN" || "$level" == "DRY-RUN" ) ]]; then
    : # Skip stdout
  elif [[ "$level" == "DEBUG" && "$DEBUG" != true ]]; then
    : # Skip stdout
  else
    echo "$msg"
  fi

  # Always write standard logs to file if present
  if [[ -n "${LOG_FILE:-}" ]]; then
    if [[ "$level" == "MARKER" ]]; then
      echo "[$ts] [MARKER] $*" >> "$LOG_FILE"
    else
      echo "$msg" >> "$LOG_FILE"
    fi
  fi
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
# ---
# require_bins: Checks if the required earthly binaries exist in the PATH
# Inputs: $@ (List of binary names like 'pandoc' or 'jq')
# Outputs: Exits with code 2 if a tool is missing
# ---
# Checks if the required earthly binaries exist in the PATH
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

# ---
# set_traps: Binds the err and exit hooks to ensure graceful demise upon failure
# ---
# Binds the err and exit hooks to ensure graceful demise upon failure
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

# Standardize script initialization: sets name, logs, traps, and parses common flags
VERSION="${ROTKEEPER_VERSION:-0.3.1.4}"

rk_init_script() {
  SCRIPTNAME="${1:-$(basename "$0" .sh)}"
  shift

  : "${DRY_RUN:=${RK_DRY:-false}}"
  : "${VERBOSE:=${RK_VERBOSE:-false}}"
  : "${QUIET:=${RK_QUIET:-true}}"
  : "${DEBUG:=${RK_DEBUG:-false}}"
  : "${HELP:=false}"

  parse_flags "$@"
  if [[ "$HELP" == true ]]; then
    show_help
    exit 0
  fi

  init_log "$SCRIPTNAME"
  set_traps

  # Save original stdout to fd 3 for MARKER bypass
  exec 3>&1

  # Redirect output to log file as well
  if [[ "$QUIET" == true ]]; then
    exec > "$LOG_FILE" 2>&1
  else
    if (exec > >(true) 2>/dev/null); then
      exec > >(tee -a "$LOG_FILE") 2>&1
    else
      exec >> "$LOG_FILE" 2>&1
    fi
  fi

  # If debug is enabled, dump env and turn on tracing
  if [[ "$DEBUG" == true ]]; then
    env
    set -x
  fi
}

get_base_no_ext() {
    local file="$1"
    local dir_part="."
    if [[ "$file" == */* ]]; then
        dir_part="${file%/*}"
    fi
    local file_part="${file##*/}"
    local base_name
    if [[ "$file_part" =~ ^\.[^.]+\. ]]; then
        base_name="${file_part%.*}"
    elif [[ "$file_part" =~ ^\.[^.]+$ ]]; then
        base_name="$file_part"
    else
        base_name="${file_part%.*}"
    fi
    if [ "$dir_part" = "." ]; then
        echo "$base_name"
    else
        echo "${dir_part}/${base_name}"
    fi
}

get_sidecar_path() {
    local target="$1"
    local base_no_ext
    base_no_ext=$(get_base_no_ext "$target")

    # If it's a directory, point to path.soul.md, else file.soul.md
    if [[ -d "$ROOT_DIR/$target" ]]; then
        echo "${META_DIR}/${target}.soul.md"
    else
        echo "${META_DIR}/${base_no_ext}.soul.md"
    fi
}

read_meta_sidecar_body() {
    local target_file="$1"
    local sidecar
    sidecar=$(get_sidecar_path "$target_file")
    if [[ -f "$sidecar" ]]; then
        sed "1{/^---$/!q;}; 1,/^---$/d" "$sidecar"
    fi
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

# Run main only if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main() {
        # placeholder main logic for rc-utils.sh
        :
    }
    main "$@"
fi
