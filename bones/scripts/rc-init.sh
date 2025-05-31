#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-init.sh
# Purpose: Initialize environment: expand and render
# Version: 0.2.1
# Updated: 2025-05-29
# -----------------------------------------

# Source shared Rotkeeper helpers
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"

set -euo pipefail
IFS=$'\n\t'

# Parse common flags
parse_flags "$@"
if [[ "$HELP" == true ]]; then
  show_help
fi

# Resolve script directory for sibling commands
SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPAND_CMD="$SCRIPTDIR/rc-expand.sh"
RENDER_CMD="$SCRIPTDIR/rc-render.sh"

LOGDIR="bones/logs"
mkdir -p "$LOGDIR"
LOG_FILE="$LOGDIR/rc-init.log"

cleanup() {
    log "INFO" "Cleaning up after rc-init.sh."
    # Add cleanup commands here
}
trap cleanup EXIT INT TERM

main() {
    # Verify required tools
    require_bins git rsync ssh pandoc date
    $VERBOSE && log "INFO" "Dependencies verified."

    log "INFO" "🔄 Starting initialization..."
    run "$EXPAND_CMD --force"
    run "$RENDER_CMD --verbose"
    log "INFO" "✅ Initialization complete."
}

main "$@"
