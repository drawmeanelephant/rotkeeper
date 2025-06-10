#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-verify.sh
# Purpose: Verify file integrity using asset-manifest.yaml and SHA256 digests
# Version: 0.2.5-pre
# Updated: 2025-06-03
# -----------------------------------------
set -euo pipefail
IFS=$'\n\t'

init_log "rc-verify"

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
    COUNT=$(yq e 'length' "$MANIFEST")
    log "INFO" "Verifying $COUNT file(s)..."

    STATUS=0

    # No mapfile: instead, loop through lines directly
    yq e '.[] | [.path, .sha256] | @tsv' "$MANIFEST" | while IFS=$'\t' read -r RELPATH EXPECTED; do
        if [[ -z "$RELPATH" ]]; then
            log "WARN" "Skipping empty path entry in manifest."
            continue
        fi
        FILE="home/assets/$RELPATH"

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


# Help handler (before invoking main)
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "rc-verify.sh — Verify files against manifest SHA256 hashes"
  echo
  echo "Usage: rc-verify.sh [options]"
  echo
  echo "Options:"
  echo "  --help, -h       Show this help message and exit"
  echo "  --dry-run        Show what would be verified without checking hashes"
  echo "  --regen          Re-run rc-assets.sh to regenerate the manifest before verifying"
  exit 0
fi

main "$@"
