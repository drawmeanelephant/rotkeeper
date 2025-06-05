#!/usr/bin/env bash
# Source shared Rotkeeper helpers
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/rc-env.sh"
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-assets.sh
# Purpose: Generate a selective YAML manifest of referenced assets
# Version: 0.2.5-pre
# Updated: 2025-06-03
# -----------------------------------------

set -euo pipefail
IFS=$'\n\t'

# --- Helpers & Flag Parsing ---
DRY_RUN=false
VERBOSE=false
HELP=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)   DRY_RUN=true; shift ;;
    --verbose)   VERBOSE=true; shift ;;
    --help|-h)   HELP=true; shift ;;
    *) break ;;
  esac
done

show_help() {
  cat << EOF
rc-assets.sh — Generate a selective YAML manifest of referenced assets

Usage: rc-assets.sh [options]

Options:
  --help, -h       Show this help message and exit
  --dry-run        Preview actions without writing files
  --verbose        Show detailed logs
EOF
  exit 0
}

if [[ "$HELP" == true ]]; then
  show_help
fi

log() {
  local level="$1"; shift
  local msg="$*"
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  printf '[%s] [%s] %s\n' "$ts" "$level" "$msg" | tee -a "$LOG_FILE"
}

run() {
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "$(printf '%q ' "$@")"
  else
    log "INFO" "$(printf '%q ' "$@")"
    "$@"
  fi
}

trap_err() {
  log "ERROR" "Error on line $1"
  exit 2
}
trap 'trap_err $LINENO' ERR


TIMESTAMP=$(date +%Y-%m-%d_%H%M)
LOG_FILE="$LOG_DIR/rc-assets-$TIMESTAMP.log"
mkdir -p "$(dirname "$LOG_FILE")"

cleanup() {
    log "INFO" "Cleaning up after rc-assets.sh."
}
trap cleanup EXIT INT TERM


main() {
    require_bins sha256sum rsync grep sed find sort uniq
    $VERBOSE && log "INFO" "Dependencies verified."

    : "${ASSETS_DIR:?Missing ASSETS_DIR from rc-env.sh}"
    : "${OUTPUT_DIR:?Missing OUTPUT_DIR from rc-env.sh}"
    : "${MANIFEST_FILE:=$CONFIG_DIR/asset-manifest.yaml}"
    : "${ARCHIVE_DIR:?Missing ARCHIVE_DIR from rc-env.sh}"
    : "${REPORT_DIR:?Missing REPORT_DIR from rc-env.sh}"

    ASSET_DIR="$ASSETS_DIR"
    OUTPUT_ASSET_DIR="$OUTPUT_DIR/assets"
    MANIFEST="$MANIFEST_FILE"
    REPORT="$REPORT_DIR/asset-report-$TIMESTAMP.yaml"

    mkdir -p "$OUTPUT_ASSET_DIR" "$ARCHIVE_DIR" "$(dirname "$REPORT")"

    if [[ -f "$MANIFEST" ]]; then
        run mv "$MANIFEST" "$ARCHIVE_DIR/asset-manifest-$TIMESTAMP.yaml"
        log "INFO" "Archived old manifest"
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log "INFO" "[DRY RUN] Would scan and copy assets from $ASSET_DIR to $OUTPUT_ASSET_DIR"
    else
        log "INFO" "Scanning rendered HTML for referenced assets..."
    fi

    ASSET_PATHS=$(grep -rhoE '(src|href)="\/?assets/[^"]+"' "$OUTPUT_DIR"/*.html 2>/dev/null | \
        sed -E 's/(src|href)="\/?assets\/([^"]+)"/\2/' | sort | uniq)

    asset_count=$(echo "$ASSET_PATHS" | grep -c . || true)
    log "INFO" "Found $asset_count asset references."

    [[ "$DRY_RUN" == false ]] && > "$REPORT"

    if [[ -z "${ASSET_PATHS// }" ]]; then
        log "WARN" "No asset references found in rendered HTML files."
        echo "# assets: []" > "$REPORT"
        run cp "$REPORT" "$MANIFEST"
        log "INFO" "Empty manifest generated at: $MANIFEST"
    else
        echo "$ASSET_PATHS" | while read -r relpath; do
            [[ -z "$relpath" ]] && continue
            src="$ASSET_DIR/$relpath"
            dest="$OUTPUT_ASSET_DIR/$relpath"

            if [[ -f "$src" ]]; then
                if [[ "$DRY_RUN" == false ]]; then
                    mkdir -p "$(dirname "$dest")"
                    run rsync -a "$src" "$dest"
                    checksum=$(sha256sum "$src" | awk '{print $1}')
                    log "INFO" "Copied referenced asset: $relpath"

                    {
                        echo "- path: \"$relpath\""
                        echo "  sha256: \"$checksum\""
                    } >> "$REPORT"
                else
                    log "INFO" "[DRY RUN] Would copy referenced asset: $relpath"
                fi
            else
                log "WARN" "Referenced but missing asset: $relpath"
            fi
        done
        [[ "$DRY_RUN" == false ]] && run cp "$REPORT" "$MANIFEST"
        if [[ "$DRY_RUN" == false ]]; then
            log "INFO" "Selective asset manifest generated at: $MANIFEST"
            log "INFO" "Selective asset copy complete."
        else
            log "INFO" "[DRY RUN] Would generate selective asset manifest at: $MANIFEST"
            log "INFO" "[DRY RUN] Selective asset copy complete."
        fi
    fi
}

main "$@"
