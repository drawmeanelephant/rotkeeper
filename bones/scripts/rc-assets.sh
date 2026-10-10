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
# Env assumptions: reads `ASSETS_DIR`, `OUTPUT_DIR`, `BONES_DIR`, `ARCHIVE_DIR`, `REPORT_DIR`, `CONFIG_DIR`, `LOG_DIR`, `ROOT_DIR`, `SCRIPT_DIR`, `TMP_DIR`, `DRY_RUN`, `VERBOSE`, `VERSION` through `rk_load_env`; `ROTKEEPER_VERSION` can override the version. Requires `bash`, `rsync`, and either `sha256sum` or `shasum`.
# CWD assumptions: none; paths come from the active layout through `rk_load_env`, not the working directory.
# Input/Output contracts: reads every regular file under `ASSETS_DIR` except `.DS_Store`, sorted by relative path; does not scan HTML or content references. Writes the `OUTPUT_DIR/assets` mirror, `BONES_DIR/asset-manifest.yaml`, `ARCHIVE_DIR/asset-manifest-<timestamp>.yaml`, and `REPORT_DIR/asset-report-<timestamp>.yaml`. Reports progress and errors through the shared logger. `--dry-run` previews asset changes without changing assets, manifests, reports, or the output ownership marker; bootstrap logging still writes under `LOG_DIR`.
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-assets.sh
#  Purpose : Mirror the source asset tree and generate a YAML manifest of relative paths and SHA-256 checksums.
#  Version : 0.5.1
#  Updated : 2026-10-01
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================
# @HELP
# rc-assets.sh — Mirror assets and generate a SHA-256 manifest (v{VERSION})
#
# Usage:
#   bash rotkeeper.sh assets [options]
#
# Description:
#   Enumerates the source asset tree, copies valid paths into output/assets,
#   and writes a path/checksum manifest. Prunes stale assets only from an
#   output tree carrying the .rotkeeper-generated ownership marker.
#
# Options:
#   --dry-run        Preview asset changes; only bootstrap logs are written
#   --verbose        Show detailed logs
#   --help, -h       Show this help message and exit
#   --version, -v    Show script version and quit
#
# Examples:
#   bash rotkeeper.sh assets                # Generate the asset manifest
#   bash rotkeeper.sh assets --dry-run      # Preview asset changes
#   bash rotkeeper.sh assets --dry-run --verbose
#   bash rotkeeper.sh assets --help         # Show help without starting a run
#
# Exit codes:
#   0    Success
#   1    Configuration/environment validation failure, or source assets skipped (illegal path characters)
#   2    Missing required dependency
#   nonzero    I/O failures propagate the failing command's exit status
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

    # SIDE EFFECT (write): creates `OUTPUT_DIR/assets`, `ARCHIVE_DIR` (`bones/archive` by default), and `REPORT_DIR` (`bones/reports` by default) if missing
    run mkdir -p "$OUTPUT_ASSET_DIR" "$ARCHIVE_DIR" "$REPORT_DIR"

    # SIDE EFFECT (delete+write): moves the previous `bones/asset-manifest.yaml` into `ARCHIVE_DIR/asset-manifest-<timestamp>.yaml`; does not merge manifests
    if [[ -f "$MANIFEST" ]]; then
        run mv "$MANIFEST" "$ARCHIVE_DIR/asset-manifest-$TIMESTAMP.yaml"
        if [[ "$DRY_RUN" == true ]]; then
            log "DRY-RUN" "Would archive old manifest"
        else
            log "INFO" "Archived old manifest"
        fi
    fi

    # Enumerate assets: find excludes .DS_Store, sed strips prefix for relpaths, sort for determinism.
    ASSET_PATHS=$(find "$ASSETS_DIR" -type f ! -name '.DS_Store' | sed "s|^$ASSETS_DIR/||" | sort)

    asset_count=$(echo "$ASSET_PATHS" | grep -c . || true)
    copied_count=0
    skipped_count=0
    log "INFO" "Found $asset_count assets in $ASSETS_DIR"

    # SIDE EFFECT (write): truncates `REPORT_DIR/asset-report-<timestamp>.yaml` (real runs only)
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
                    # SIDE EFFECT (delete): removes files under `OUTPUT_DIR/assets` that have no source counterpart, only when the output tree carries `.rotkeeper-generated`
                    rm -f "$generated_asset"
                    log "INFO" "Pruned stale generated asset: $rel_generated"
                fi
            fi
        done < <(find "$OUTPUT_ASSET_DIR" -type f -print0)
    fi

    if [[ "$asset_count" -eq 0 ]]; then
        log "WARN" "No assets found under $ASSETS_DIR"
        if [[ "$DRY_RUN" == true ]]; then
            log "DRY-RUN" "Would generate empty manifest at: $MANIFEST"
        else
            # SIDE EFFECT (write): records an empty manifest entry in the report
            echo "# assets: []" > "$REPORT"
            run cp "$REPORT" "$MANIFEST"
            log "INFO" "Empty manifest generated at: $MANIFEST"
        fi
    else
        while IFS= read -r relpath; do
            src="$ASSETS_DIR/$relpath"
            dest="$OUTPUT_ASSET_DIR/$relpath"
            if [[ -f "$src" ]]; then
                if [[ "$relpath" == *"../"* ]] || [[ ! "$relpath" =~ ^[a-zA-Z0-9/._-]+$ ]]; then
                    log "ERROR" "Illegal characters in asset path: $relpath"
                    skipped_count=$((skipped_count + 1))
                    continue
                fi
                # SIDE EFFECT (write): copies each valid source asset into `OUTPUT_DIR/assets` via `rsync`
                run mkdir -p "$(dirname "$dest")"
                run rsync -a "$src" "$dest"
                copied_count=$((copied_count + 1))
                if [[ "$DRY_RUN" == true ]]; then
                    log "DRY-RUN" "Would copy asset: $relpath"
                else
                    # Checksum: rk_sha256 prints "<hash>  <file>"; awk extracts hash.
                    checksum=$(rk_sha256 "$src" | awk '{print $1}')
                    log "INFO" "Copied asset: $relpath"
                    # SIDE EFFECT (write): appends `path`/`sha256` entries to `REPORT_DIR/asset-report-<timestamp>.yaml`
                    {
                        echo "- path: \"$relpath\""
                        echo "  sha256: \"$checksum\""
                    } >> "$REPORT"
                fi
            else
                log "WARN" "Missing asset file unexpectedly: $relpath"
                skipped_count=$((skipped_count + 1))
            fi
        done <<< "$ASSET_PATHS"
        if [[ "$DRY_RUN" == true ]]; then
            log "DRY-RUN" "Would generate full asset manifest at: $MANIFEST"
        else
            # SIDE EFFECT (write): publishes the report as `BONES_DIR/asset-manifest.yaml`
            run cp "$REPORT" "$MANIFEST"
            log "INFO" "Full asset manifest generated at: $MANIFEST"
        fi
    fi

    # SIDE EFFECT (write): creates or truncates `OUTPUT_DIR/.rotkeeper-generated` through `mark_output_generated`; skipped during `--dry-run`
    mark_output_generated

    log "MARKER" "Assets synchronized: $copied_count of $asset_count source assets -> $OUTPUT_ASSET_DIR"
    if [[ "$skipped_count" -gt 0 ]]; then
        log "ERROR" "$skipped_count source asset(s) were skipped; output mirror is incomplete"
        echo "ERROR: $skipped_count source asset(s) skipped (illegal characters in path or vanished source); '$OUTPUT_ASSET_DIR' is incomplete." >&2
        exit 1
    fi

    # SITEMAP PURGED ENTIRELY FROM CORE PIPELINE.
}

# --- Entry Point ---
main "$@"
