#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-docbook.sh
# Purpose: Generate docbook reports
# Version: 0.1.0
# Updated: 2025-05-29
# -----------------------------------------

set -euo pipefail
IFS=$'\n\t'

# --- Log File Setup ---
SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPTDIR/../logs/rc-docbook-$(date +%Y-%m-%d_%H%M).log"
mkdir -p "$(dirname "$LOG_FILE")"

# Source shared Rotkeeper helpers
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/rc-env.sh"

inject_changelog_to_docbook() {
  local target_file="$REPORT_DIR/rotkeeper-docbook.md"
  mkdir -p "$(dirname "$target_file")"
  {
    echo "# Rotkeeper Docbook Report"
    echo "Generated on $(date '+%Y-%m-%d %H:%M')"
    echo ""
    git log --oneline --graph --decorate -n 10
  } > "$target_file"
}

mkdir -p "$REPORT_DIR"
OUTPUT="$REPORT_DIR/rotkeeper-docbook.md"

# Parse common flags and handle help
parse_flags "$@"
if [[ "$HELP" == true ]]; then
  show_help
fi

main() {
  require_bins git date
  log "INFO" "Running rc-docbook.sh."
  mkdir -p "$LOG_DIR"
  if [[ "$DRY_RUN" == false ]]; then
    inject_changelog_to_docbook
  else
    log "DRY-RUN" "Would generate docbook report at $OUTPUT"
  fi

  log "INFO" "rc-docbook.sh completed successfully."
}

main "$@"