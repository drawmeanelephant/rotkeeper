
#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-utils.sh
# Purpose: Shared Rotkeeper helper functions
# Version: 0.2.1
# Updated: 2025-05-29
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

# Logging function: prints timestamped messages
log() {
  local level="$1"; shift
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  printf '[%s] [%s] %s\n' "$ts" "$level" "$*"
}

# Runner: dry-run and verbose wrapper for commands
run() {
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "$*"
  else
    [[ "$VERBOSE" == true ]] && log "INFO" "$*"
    eval "$*"
  fi
}

# Dependency checker: ensure required commands are available
check_deps() {
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      log "ERROR" "Missing required dependency: $cmd"
      exit 2
    fi
  done
}

# Error trap: report error line and exit
trap_err() {
  log "ERROR" "Error on line $1"
  exit 2
}

# Cleanup hook: override in scripts to perform teardown
cleanup() {
  :
}

# Set traps for errors and exit
trap 'trap_err $LINENO' ERR
trap 'cleanup' EXIT INT TERM