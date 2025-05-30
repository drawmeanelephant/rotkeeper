#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-reseed.sh
# Purpose: Rehydrate tomb archives and trigger expand + render
# Version: 0.1.9.9
# Updated: 2025-05-27
# -----------------------------------------
# =============================================================================
# rc-reseed.sh — Resurrection script for Rotkeeper tombkits
#
#   When tombs are packed and sealed away,
#   This script returns them to the fray.
#   Unzips the bones and renders true,
#   Expands the rot — rebirth for you.
#
#   🔮 Usage: rotkeeper.sh reseed <archive.tar.gz>
# =============================================================================
set -euo pipefail
IFS=$'\n\t'

# Logging function — standard rotkeeper format to both stdout and logfile
log() {
    local level="$1"; shift
    printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" | tee -a "$LOG_FILE"
}

# Cleanup trap — echoes final message on EXIT or interrupt
cleanup() {
    log "INFO" "Cleaning up after rc-reseed.sh."
}

# Hook cleanup on script exit
trap cleanup EXIT INT TERM

# Main resurrection logic
# - Validates archive presence
# - Extracts archive into restored-$TIMESTAMP/
# - If full system present, runs expand and render automatically
main() {
    DRY_RUN=false
    for arg in "$@"; do
      [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
    done

    # Whispering boot message
    echo "🪦 Whispering resurrection... Stand by, tombwalker."
    log "INFO" "Running rc-reseed.sh."

    ARCHIVE=${1:-}
    if [[ -z "$ARCHIVE" ]]; then
        echo "Usage: rc-reseed.sh <archive.tar.gz> [--dry-run]"
        log "ERROR" "No archive provided."
        exit 1
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log "DRY" "Would extract: $ARCHIVE"
        log "DRY" "Would create: restored-<timestamp>"
        log "DRY" "Would run: ./rotkeeper.sh expand"
        log "DRY" "Would run: ./rotkeeper.sh render"
        return
    fi

    if [[ ! -f "$ARCHIVE" ]]; then
        log "ERROR" "File not found: $ARCHIVE"
        exit 1
    fi

    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    RESTORE_DIR="restored-$TIMESTAMP"
    mkdir -p "$RESTORE_DIR"

    log "INFO" "Unpacking $ARCHIVE into $RESTORE_DIR"
    tar -xzf "$ARCHIVE" -C "$RESTORE_DIR"

    log "INFO" "Rehydration complete. Running expand and render..."
    if [[ ! -f "$RESTORE_DIR/rotkeeper.sh" ]]; then
        log "WARN" "No rotkeeper.sh found in archive. This may be a display-only tomb."
        return
    fi
    bash "$RESTORE_DIR/rotkeeper.sh" expand --verbose || log "WARN" "Expand failed or already done"
    bash "$RESTORE_DIR/rotkeeper.sh" render

    log "INFO" "rc-reseed.sh completed. Welcome back, tombwalker."
}

LOG_FILE="bones/logs/rc-reseed-$(date +%Y-%m-%d_%H%M).log"
mkdir -p "$(dirname "$LOG_FILE")"

main "$@"
