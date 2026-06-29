#!/usr/bin/env bash
# ============================================================
#   █████╗ ███████╗███████╗███████╗████████╗███████╗
#  ██╔══██╗██╔════╝██╔════╝██╔════╝╚══██╔══╝██╔════╝
#  ███████║███████╗███████╗█████╗     ██║   ███████╗
#  ██╔══██║╚════██║╚════██║██╔══╝     ██║   ╚════██║
#  ██║  ██║███████║███████║███████╗   ██║   ███████║
#  ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝   ╚═╝   ╚══════╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-assets.sh
#  Purpose : Generate a selective YAML manifest of referenced assets
#  Version : 0.4.0
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================
show_help() {
  cat << EOF
rc-assets.sh — Generate a selective YAML manifest of referenced assets

Usage: rc-assets.sh [options]

Options:
  --version, -v    Show script version and quit
  --help, -h       Show this help message and exit
  --dry-run        Preview actions without writing files
  --verbose        Show detailed logs
  --sitemap        Generate sitemap.yaml manifest (opt-in)
EOF
  exit 0
}

source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
VERSION="${ROTKEEPER_VERSION:-0.3.1.4}"

rk_init_script "rc-assets" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR ASSETS_DIR
set -euo pipefail
IFS=$'\n\t'


# --- Helpers & Flag Parsing ---
GENERATE_SITEMAP=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version|-v) echo "$(basename "$0") v${VERSION:-unknown}"; exit 0 ;;
    --dry-run)   DRY_RUN=true; shift ;;
    --verbose)   VERBOSE=true; shift ;;
    --help|-h)   show_help ;;
    --sitemap)   GENERATE_SITEMAP=true; shift ;;
    *) break ;;
  esac
done






cleanup() {
    log "INFO" "Cleaning up after rc-assets.sh."
}


main() {
    TIMESTAMP=$(date +%Y-%m-%d_%H%M)
    check_dependencies
    $VERBOSE && log "INFO" "Dependencies verified."

    MANIFEST="$BONES_DIR/asset-manifest.yaml"
    REPORT="$REPORT_DIR/asset-report-$TIMESTAMP.yaml"
    OUTPUT_ASSET_DIR="$OUTPUT_DIR/assets"

    run mkdir -p "$OUTPUT_ASSET_DIR" "$ARCHIVE_DIR" "$REPORT_DIR"

    if [[ -f "$MANIFEST" ]]; then
        run mv "$MANIFEST" "$ARCHIVE_DIR/asset-manifest-$TIMESTAMP.yaml"
        log "INFO" "Archived old manifest"
    fi

    ASSET_PATHS=$(find "$ASSETS_DIR" -type f | sed "s|^$ASSETS_DIR/||" | sort)

    asset_count=$(echo "$ASSET_PATHS" | grep -c . || true)
    log "INFO" "Found $asset_count assets in $ASSETS_DIR"

    [[ "$DRY_RUN" == false ]] && : > "$REPORT"

    if [[ "$asset_count" -eq 0 ]]; then
        log "WARN" "No assets found under $ASSETS_DIR"
        echo "# assets: []" > "$REPORT"
        run cp "$REPORT" "$MANIFEST"
        log "INFO" "Empty manifest generated at: $MANIFEST"
    else
        echo "$ASSET_PATHS" | while read -r relpath; do
            src="$ASSETS_DIR/$relpath"
            dest="$OUTPUT_ASSET_DIR/$relpath"
            if [[ -f "$src" ]]; then
                run mkdir -p "$(dirname "$dest")"
                run rsync -a "$src" "$dest"
                checksum=$(sha256sum "$src" | awk '{print $1}')
                log "INFO" "Copied asset: $relpath"
                {
                    echo "- path: \"$relpath\""
                    echo "  sha256: \"$checksum\""
                } >> "$REPORT"
            else
                log "WARN" "Missing asset file unexpectedly: $relpath"
            fi
        done
        run cp "$REPORT" "$MANIFEST"
        log "INFO" "Full asset manifest generated at: $MANIFEST"
    fi

    # SITEMAP PURGED ENTIRELY FROM CORE PIPELINE.
}

# --- Entry Point ---
main "$@"
