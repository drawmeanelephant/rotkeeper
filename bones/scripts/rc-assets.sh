#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# ============================================================
#   █████╗ ███████╗███████╗███████╗████████╗███████╗
#  ██╔══██╗██╔════╝██╔════╝██╔════╝╚══██╔══╝██╔════╝
#  ███████║███████╗███████╗█████╗     ██║   ███████╗
#  ██╔══██║╚════██║╚════██║██╔══╝     ██║   ╚════██║
#  ██║  ██║███████║███████║███████╗   ██║   ███████║
#  ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝   ╚═╝   ╚══════╝
# ============================================================
# Env assumptions: reads ARCHIVE_DIR, ASSETS_DIR, BONES_DIR, CONFIG_DIR, DRY_RUN, LOG_DIR, OUTPUT_DIR, REPORT_DIR, ROOT_DIR, SCRIPT_DIR, TMP_DIR, VERBOSE, VERSION (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.
# CWD assumptions: No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.
# Input/Output contracts: CLI args and env vars in; files and stdout/stderr out; respects --dry-run (no writes) and --verbose.
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-assets.sh
#  Purpose : Generate a selective YAML manifest of referenced assets
#  Version : 0.5.1
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================
# ---
# show_help: Print asset manifest usage and exit.
# Inputs: none (reads VERSION)
# Outputs: Prints help and exits 0
# Env: Reads ARCHIVE_DIR, ASSETS_DIR, BONES_DIR, CONFIG_DIR, DRY_RUN, LOG_DIR ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
show_help() {
  cat << EOF
rc-assets.sh — Generate a selective YAML manifest of referenced assets

Usage: rc-assets.sh [options]

Options:
  --version, -v    Show script version and quit
  --help, -h       Show this help message and exit
  --dry-run        Preview actions without writing files
  --verbose        Show detailed logs
EOF
  exit 0
}


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
rk_init_script "rc-assets" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR ASSETS_DIR
set -euo pipefail
IFS=$'\n\t'


# --- Helpers & Flag Parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version|-v) echo "$(basename "$0") v${VERSION:-unknown}"; exit 0 ;;
    --dry-run)   DRY_RUN=true; shift ;;
    --verbose)   VERBOSE=true; shift ;;
    --help|-h)   show_help ;;
    *) break ;;
  esac
done






# ---
# cleanup: EXIT handler for asset sync (no temp files to remove).
# Inputs: none
# Outputs: Logs cleanup; respects cleanup_ran guard via base cleanup()
# Env: Reads ARCHIVE_DIR, ASSETS_DIR, BONES_DIR, DRY_RUN, OUTPUT_DIR, QUIET ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
cleanup() {
    log "INFO" "Cleaning up after rc-assets.sh."
}

# ---
# main: Synchronize assets, prune stale output, and generate manifests.
# Inputs: none (reads ASSETS_DIR, OUTPUT_DIR, ARCHIVE_DIR, REPORT_DIR)
# Outputs: Writes asset-manifest.yaml and report; syncs assets to output/assets
# Env: Reads ARCHIVE_DIR, ASSETS_DIR, BONES_DIR, DRY_RUN, OUTPUT_DIR, REPORT_DIR ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
main() {
    TIMESTAMP=$(date +%Y-%m-%d_%H%M)
    require_bins bash rsync
    require_sha256
    $VERBOSE && log "INFO" "Dependencies verified."

    MANIFEST="$BONES_DIR/asset-manifest.yaml"
    REPORT="$REPORT_DIR/asset-report-$TIMESTAMP.yaml"
    OUTPUT_ASSET_DIR="$OUTPUT_DIR/assets"

    run mkdir -p "$OUTPUT_ASSET_DIR" "$ARCHIVE_DIR" "$REPORT_DIR"

    if [[ -f "$MANIFEST" ]]; then
        run mv "$MANIFEST" "$ARCHIVE_DIR/asset-manifest-$TIMESTAMP.yaml"
        log "INFO" "Archived old manifest"
    fi

    # Enumerate assets: find excludes .DS_Store, sed strips prefix for relpaths, sort for determinism.
    ASSET_PATHS=$(find "$ASSETS_DIR" -type f ! -name '.DS_Store' | sed "s|^$ASSETS_DIR/||" | sort)

    asset_count=$(echo "$ASSET_PATHS" | grep -c . || true)
    log "INFO" "Found $asset_count assets in $ASSETS_DIR"

    [[ "$DRY_RUN" == false ]] && : > "$REPORT"

    # Keep generated assets synchronized with the source tree so deleted
    # assets do not linger in output/ and surprise static servers. Stale
    # output is only pruned when the output tree is marked generated.
    if output_is_generated && [[ -d "$OUTPUT_ASSET_DIR" ]]; then
        while IFS= read -r -d '' generated_asset; do
            rel_generated="${generated_asset#"$OUTPUT_ASSET_DIR"/}"
            if ! grep -Fxq "$rel_generated" <<< "$ASSET_PATHS"; then
                if [[ "$DRY_RUN" == true ]]; then
                    log "DRY-RUN" "Would prune stale generated asset: $rel_generated"
                else
                    rm -f "$generated_asset"
                    log "INFO" "Pruned stale generated asset: $rel_generated"
                fi
            fi
        done < <(find "$OUTPUT_ASSET_DIR" -type f -print0)
    fi

    if [[ "$asset_count" -eq 0 ]]; then
        log "WARN" "No assets found under $ASSETS_DIR"
        echo "# assets: []" > "$REPORT"
        run cp "$REPORT" "$MANIFEST"
        log "INFO" "Empty manifest generated at: $MANIFEST"
    else
        while IFS= read -r relpath; do
            src="$ASSETS_DIR/$relpath"
            dest="$OUTPUT_ASSET_DIR/$relpath"
            if [[ -f "$src" ]]; then
                if [[ "$relpath" == *"../"* ]] || [[ ! "$relpath" =~ ^[a-zA-Z0-9/._-]+$ ]]; then
                    log "ERROR" "Illegal characters in asset path"
                    continue
                fi
                run mkdir -p "$(dirname "$dest")"
                run rsync -a "$src" "$dest"
                # Checksum: rk_sha256 prints "<hash>  <file>"; awk extracts hash.
                checksum=$(rk_sha256 "$src" | awk '{print $1}')
                log "INFO" "Copied asset: $relpath"
                {
                    echo "- path: \"$relpath\""
                    echo "  sha256: \"$checksum\""
                } >> "$REPORT"
            else
                log "WARN" "Missing asset file unexpectedly: $relpath"
            fi
        done <<< "$ASSET_PATHS"
        run cp "$REPORT" "$MANIFEST"
        log "INFO" "Full asset manifest generated at: $MANIFEST"
    fi

    mark_output_generated

    log "MARKER" "Assets synchronized: $asset_count source assets -> $OUTPUT_ASSET_DIR"

    # SITEMAP PURGED ENTIRELY FROM CORE PIPELINE.
}

# --- Entry Point ---
main "$@"
