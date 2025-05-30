#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-verify.sh
# Purpose: Verify file integrity using asset-manifest.yaml and SHA256 digests
# Version: 0.2.0
# Updated: 2025-05-27
# -----------------------------------------
set -euo pipefail
IFS=$'\n\t'

TIMESTAMP=$(date +%Y-%m-%d_%H%M)
LOG_PATH="bones/logs/rc-verify-$TIMESTAMP.log"
mkdir -p "$(dirname "$LOG_PATH")"

log() {
    local level="$1"; shift
    printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" | tee -a "$LOG_PATH"
}

cleanup() {
    log "INFO" "Cleaning up after rc-verify.sh."
    # Add additional cleanup commands here if needed
}
trap cleanup EXIT INT TERM

check_dependencies() {
    local deps=(sha256sum yq date awk)
    for cmd in "${deps[@]}"; do
        command -v "$cmd" >/dev/null 2>&1 || {
            log "ERROR" "$cmd required but not installed."
            exit 1
        }
    done
}

main() {
    DRY_RUN=false
    REGEN=false
    for arg in "$@"; do
        [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
        [[ "$arg" == "--regen" ]] && REGEN=true
    done

    if [[ "$REGEN" == true ]]; then
        log "INFO" "Regenerating asset manifest..."
        ./bones/scripts/rc-assets.sh
    fi

    check_dependencies

    MANIFEST="bones/asset-manifest.yaml"
    if [[ ! -f "$MANIFEST" ]]; then
        log "ERROR" "Missing manifest: $MANIFEST"
        log "INFO" "You may need to run: ./rotkeeper.sh assets"
        exit 2
    fi

    log "INFO" "Starting verification against $MANIFEST"

    STATUS=0

    # No mapfile: instead, loop through lines directly
    yq e '.[] | [.path, .sha256] | @tsv' "$MANIFEST" | while IFS=$'\t' read -r RELPATH EXPECTED; do
        FILE="home/$RELPATH"

        if [[ "$DRY_RUN" == true ]]; then
            if [[ -f "$FILE" ]]; then
                log "DRY" "Would verify: $FILE"
            else
                log "DRY" "Missing file: $FILE (would report error)"
            fi
        else
            if [[ ! -f "$FILE" ]]; then
                log "ERROR" "Missing file: $FILE"
                STATUS=2
                continue
            fi

            ACTUAL=$(sha256sum "$FILE" | awk '{print $1}')

            if [[ "$EXPECTED" == "$ACTUAL" ]]; then
                log "OK" "Verified: $FILE"
            else
                log "ERROR" "Checksum mismatch: $FILE (expected: $EXPECTED, got: $ACTUAL)"
                STATUS=1
            fi
        fi
    done

    log "INFO" "rc-verify.sh completed with status $STATUS"
    exit $STATUS
}

main "$@"
