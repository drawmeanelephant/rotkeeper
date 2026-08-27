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
# @HELP
# rc-assets.sh — Generate a selective YAML manifest of referenced assets (v{VERSION})
#
# Usage:
#   rotkeeper.sh assets [options]
#
# Description:
#   Scans content sources for referenced local assets and writes a
#   selective YAML manifest so asset usage stays auditable.
#
# Options:
#   --dry-run        Preview actions without writing files
#   --verbose        Show detailed logs
#   --help, -h       Show this help message and exit
#   --version, -v    Show script version and quit
#
# Examples:
#   bash rotkeeper.sh assets                Generate the asset manifest
#   bash rotkeeper.sh assets --dry-run      Preview without writing
#
# Exit codes:
#   0    Success
#   1    Manifest generation failure
# @END-HELP


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
rk_init_script "rc-assets" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR ASSETS_DIR


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

    # SIDE EFFECT (write): creates output/assets, bones/archives, and bones/reports if missing
    run mkdir -p "$OUTPUT_ASSET_DIR" "$ARCHIVE_DIR" "$REPORT_DIR"

    # SIDE EFFECT (delete+write): rotates the previous asset-manifest.yaml into bones/archives (removes it from bones/)
    if [[ -f "$MANIFEST" ]]; then
        run mv "$MANIFEST" "$ARCHIVE_DIR/asset-manifest-$TIMESTAMP.yaml"
        log "INFO" "Archived old manifest"
    fi

    # Enumerate assets: find excludes .DS_Store, sed strips prefix for relpaths, sort for determinism.
    ASSET_PATHS=$(find "$ASSETS_DIR" -type f ! -name '.DS_Store' | sed "s|^$ASSETS_DIR/||" | sort)

    asset_count=$(echo "$ASSET_PATHS" | grep -c . || true)
    log "INFO" "Found $asset_count assets in $ASSETS_DIR"

    # SIDE EFFECT (write): truncates bones/reports/asset-report-<ts>.yaml (real runs only)
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
                    # SIDE EFFECT (delete): removes generated assets no longer present in the source tree
                    rm -f "$generated_asset"
                    log "INFO" "Pruned stale generated asset: $rel_generated"
                fi
            fi
        done < <(find "$OUTPUT_ASSET_DIR" -type f -print0)
    fi

    if [[ "$asset_count" -eq 0 ]]; then
        log "WARN" "No assets found under $ASSETS_DIR"
        # SIDE EFFECT (write): records an empty manifest entry in the report
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
                # SIDE EFFECT (write): copies each source asset into output/assets via rsync
                run mkdir -p "$(dirname "$dest")"
                run rsync -a "$src" "$dest"
                # Checksum: rk_sha256 prints "<hash>  <file>"; awk extracts hash.
                checksum=$(rk_sha256 "$src" | awk '{print $1}')
                log "INFO" "Copied asset: $relpath"
                # SIDE EFFECT (write): appends path/sha256 entries to bones/reports/asset-report-<ts>.yaml
                {
                    echo "- path: \"$relpath\""
                    echo "  sha256: \"$checksum\""
                } >> "$REPORT"
            else
                log "WARN" "Missing asset file unexpectedly: $relpath"
            fi
        done <<< "$ASSET_PATHS"
        # SIDE EFFECT (write): publishes the report as bones/asset-manifest.yaml
        run cp "$REPORT" "$MANIFEST"
        log "INFO" "Full asset manifest generated at: $MANIFEST"
    fi

    mark_output_generated

    log "MARKER" "Assets synchronized: $asset_count source assets -> $OUTPUT_ASSET_DIR"

    # SITEMAP PURGED ENTIRELY FROM CORE PIPELINE.
}

# --- Entry Point ---
main "$@"
