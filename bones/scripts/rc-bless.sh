#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-bless.sh
# Purpose: Generate changelog entries and bless state
# Version: 0.2.1
# Updated: 2025-05-29
# -----------------------------------------

set -euo pipefail
IFS=$'\n\t'

# --- Log File Setup ---
SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPTDIR/../logs/rc-bless-$(date +%Y-%m-%d_%H%M).log"
mkdir -p "$(dirname "$LOG_FILE")"

# Source shared Rotkeeper helpers
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"

# Parse common flags and handle help
parse_flags "$@"
if [[ "$HELP" == true ]]; then
  show_help
fi

main() {
  require_bins git date
  log "INFO" "Running rc-bless.sh."
  mkdir -p bones/logs
  CHANGELOG="bones/logs/changelog.md"
  if [[ "$DRY_RUN" == false ]]; then
    run "{
      echo \"## $(date '+%Y-%m-%d %H:%M') — Blessing\"
      echo \"\"
      if git rev-parse HEAD~1 >/dev/null 2>&1; then
          git diff --name-status HEAD~1 HEAD
      else
          echo \"(no prior commit to diff against)\"
      fi
      echo \"\"
    } >> \"$CHANGELOG\""
  else
    log "DRY-RUN" "Would update changelog at $CHANGELOG"
  fi

  log "INFO" "rc-bless.sh completed successfully."
}

main "$@"