#!/usr/bin/env bash
# ============================================================
#  ██████╗  ██████╗ ████████╗██╗  ██╗███████╗███████╗██████╗
#  ██╔══██╗██╔═══██╗╚══██╔══╝██║ ██╔╝██╔════╝██╔════╝██╔══██╗
#  ██████╔╝██║   ██║   ██║   █████╔╝ █████╗  █████╗  ██████╔╝
#  ██╔══██╗██║   ██║   ██║   ██╔═██╗ ██╔══╝  ██╔══╝  ██╔═══╝
#  ██║  ██║╚██████╔╝   ██║   ██║  ██╗███████╗███████╗██║
#  ╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-assets.sh
#  Purpose : Generate a selective YAML manifest of referenced assets
#  Version : 0.3.0.4
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
set -euo pipefail
IFS=$'\n\t'

# --- Helpers & Flag Parsing ---
DRY_RUN=false
VERBOSE=false
HELP=false
GENERATE_SITEMAP=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)   DRY_RUN=true; shift ;;
    --verbose)   VERBOSE=true; shift ;;
    --help|-h)   HELP=true; shift ;;
    --sitemap)   GENERATE_SITEMAP=true; shift ;;
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
  --sitemap        Generate sitemap.yaml manifest (opt-in)
EOF
  exit 0
}

if [[ "$HELP" == true ]]; then
  show_help
fi

init_log "rc-assets"

trap 'trap_err $LINENO' ERR



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

    [[ "$DRY_RUN" == false ]] && > "$REPORT"

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

    if [[ "$GENERATE_SITEMAP" == true ]]; then
        generate_sitemap
    fi
}

generate_sitemap() {
    set +e  # disable strict mode temporarily
    local sitemap_md="$REPORT_DIR/rotkeeper-sitemap.md"
    if [[ -f "$sitemap_md" && ! -s "$sitemap_md" ]]; then
      log "WARN" "Skipping sitemap generation: empty file exists at $sitemap_md"
      return 0
    fi
    mkdir -p "$REPORT_DIR"
    log "INFO" "Generating sitemap at $sitemap_md"

    mapfile -t html_files < <(find "$OUTPUT_DIR" -type f -name '*.html' 2>/dev/null | sort)
    if [[ $? -ne 0 ]]; then
      log "ERROR" "Failed to read .html files from $OUTPUT_DIR"
      set -e
      return 1
    fi

    {
      echo "---"
      echo "title: \"${PROJECT} Sitemap\""
      echo "slug: sitemap"
      echo "template: rotkeeper-doc.html"
      echo "version: \"0.3.0\""
      echo "updated: $(date +%Y-%m-%d)"
      echo "description: \"Rendered output paths and resolved markdown equivalents.\""
      echo "tags: [report, sitemap]"
      echo "asset_meta:"
      echo "  name: \"rotkeeper-sitemap.md\""
      echo "  version: \"0.3.0\""
      echo "  author: \"${AUTHOR}\""
      echo "  project: \"${PROJECT}\""
      echo "  tracked: true"
      echo "  license: \"CC-BY-SA-4.0\""
      echo "---"
      echo
      echo "# Sitemap"
      echo

      if [[ "${#html_files[@]}" -eq 0 ]]; then
        log "WARN" "No .html files found in $OUTPUT_DIR"
        echo "_No pages found._"
      else
        echo "| Path | Markdown Equivalent |"
        echo "| ---- | ------------------- |"
        for file in "${html_files[@]}"; do
            relpath="${file#$OUTPUT_DIR/}"
            md_path="${relpath%.html}.md"
            echo "| $relpath | $md_path |"
        done
      fi
      echo
    } > "$sitemap_md"

    if [[ ! -s "$sitemap_md" ]]; then
      log "ERROR" "Sitemap generation failed: $sitemap_md is empty or missing"
      return 1
    fi

    log "INFO" "Sitemap markdown successfully written to: $sitemap_md"
    set -e
    return 0
}

# --- Entry Point ---
main "$@"
