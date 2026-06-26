#!/usr/bin/env bash
# ============================================================
#  Project : Rotkeeper
#  Script  : rc-sync-inbox.sh
#  Purpose : Inbox Autopilot - automates AI documentation ingestion loop
# ============================================================

set -euo pipefail

# Source standard environment variables
source "$(dirname "${BASH_SOURCE[0]}")/rc-env.sh"

echo "Phase 1: Scanning drop zone..."
INBOX_DIR="$ROOT_DIR/messages-from-my-friends"

# Scan for payloads
shopt -s nullglob
archives=("$INBOX_DIR"/*.tar.gz)
shopt -u nullglob

if [[ ${#archives[@]} -eq 0 ]]; then
    echo "No pending payloads found in $INBOX_DIR. Exiting gracefully."

    exit 0
fi

echo "Found ${#archives[@]} payload(s)."

echo "Phase 2: Unpack & Ingest..."
if ! "$ROOT_DIR/rotkeeper.sh" ingest; then
    echo "Error: Ingest ritual failed."
    exit 1
fi

echo "Phase 3: Stitch the Docs (Auto-DIP)..."
if ! "$ROOT_DIR/rotkeeper.sh" dip; then
    echo "Error: DIP ritual failed."
    exit 1
fi

echo "Phase 4: Publish the HTML..."
if ! "$ROOT_DIR/rotkeeper.sh" render; then
    echo "Error: Render ritual failed."
    exit 1
fi

echo "Inbox Autopilot completed successfully!"
exit 0
