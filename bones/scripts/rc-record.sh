#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-record.sh
# Purpose: Record current git commit and timestamp
# Version: 0.2.1
# Updated: 2025-05-29
# -----------------------------------------


# Source shared Rotkeeper helpers
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"

show_help() {
  cat << EOF
rc-record.sh — Record current git commit and timestamp (v0.2.1)

Usage: rc-record.sh [options]

Options:
  --help, -h       Show this help message and exit
  --dry-run        Preview the record action without writing to file
  --verbose        Show detailed logs
EOF
  exit 0
}


set -euo pipefail
IFS=$'\n\t'

# Parse flags and handle help
parse_flags "$@"
if [[ "$HELP" == true ]]; then
  show_help
fi

main() {
  # Ensure git is available
  check_deps git

  log "INFO" "Running rc-record.sh."

  # Prepare log directory and file
  SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  LOG_DIR="$SCRIPTDIR/../logs"
  mkdir -p "$LOG_DIR"
  RECORD_FILE="$LOG_DIR/record.log"

  # Gather data
  SHA=$(git rev-parse HEAD 2>/dev/null || echo "(no git repo)")
  TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
  HOSTNAME=$(hostname)
  USERNAME=$(whoami)

  RECORD_LINE="$TIMESTAMP  $SHA  user:$USERNAME host:$HOSTNAME"

  # Write or preview
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "Would record: $RECORD_LINE to $RECORD_FILE"
  else
    echo "$RECORD_LINE" >> "$RECORD_FILE"
    log "INFO" "Recorded state to $RECORD_FILE: $RECORD_LINE"
  fi
}

main "$@"
