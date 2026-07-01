#!/usr/bin/env bash
# ============================================================
#  Project : Rotkeeper
#  Script  : rc-sync-inbox.sh
#  Purpose : Inbox Autopilot - automates AI documentation ingestion loop
# ============================================================

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPTDIR}/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }

show_help() {
  cat <<EOF
rc-sync-inbox.sh — Inbox Autopilot
Automates the AI documentation ingestion loop: scan → ingest → dip → render

Usage: rc-sync-inbox.sh [options]
Options:
  --dry-run     Preview phases without executing
  --verbose     Show detailed logs
  --help, -h    Show this message
  --version, -v Show version
EOF
  exit 0
}

VERSION="${ROTKEEPER_VERSION:-0.4.0.3}"
rk_init_script "rc-sync-inbox" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONTENT_DIR LOG_DIR
set -euo pipefail
IFS=$'\n\t'

log "INFO" "Phase 1: Scanning drop zone..."
INBOX_DIR="$ROOT_DIR/messages-from-my-friends"

# Scan for payloads
shopt -s nullglob
archives=("$INBOX_DIR"/*.tar.gz)
shopt -u nullglob

if [[ ${#archives[@]} -eq 0 ]]; then
    log "INFO" "No pending payloads found in $INBOX_DIR. Exiting gracefully."
    exit 0
fi

log "INFO" "Found ${#archives[@]} payload(s)."

log "INFO" "Phase 2: Unpack & Ingest..."
if [[ "$DRY_RUN" != true ]]; then
    if ! "$ROOT_DIR/rotkeeper.sh" ingest; then
        log "ERROR" "Ingest ritual failed."
        exit 1
    fi
fi

log "INFO" "Phase 3: Stitch the Docs (Auto-DIP)..."
if [[ "$DRY_RUN" != true ]]; then
    if ! "$ROOT_DIR/rotkeeper.sh" dip; then
        log "ERROR" "DIP ritual failed."
        exit 1
    fi
fi

log "INFO" "Phase 4: Publish the HTML..."
if [[ "$DRY_RUN" != true ]]; then
    if ! "$ROOT_DIR/rotkeeper.sh" render; then
        log "ERROR" "Render ritual failed."
        exit 1
    fi
fi

log "INFO" "Inbox Autopilot completed successfully!"
exit 0
