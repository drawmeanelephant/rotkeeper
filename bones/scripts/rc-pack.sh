#!/usr/bin/env bash
# Source shared Rotkeeper helpers
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-pack.sh
# Purpose: Bundle the rendered output into a versioned .tar.gz archive and export markdown content to JSON.
# Version: 0.2.0
# Updated: 2025-05-27
# -----------------------------------------
set -euo pipefail
IFS=$'\n\t'

LOG_FILE="bones/logs/rc-pack-$(date +%Y-%m-%d_%H%M).log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    local level="$1"; shift
    printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" | tee -a "$LOG_FILE"
}

cleanup() {
    log "INFO" "Cleaning up after rc-pack.sh."
    # Add cleanup commands here
}
trap cleanup EXIT INT TERM


run() {
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "$*"
  else
    log "INFO" "$*"
    eval "$*"
  fi
}

show_help() {
  cat << EOF
rc-pack.sh — Ritual Compression Packager (v0.2.0)

Usage: rc-pack.sh [options]

Options:
  --help, -h       Show this help message and exit
  --dry-run        Preview actions without writing files
  --self           Archive the full Rotkeeper system (rotkeeper.sh, bones/, home/, output/)
  --verbose        Enable detailed debug logging
EOF
  exit 0
}

# =============================================================================
# rc-pack.sh – Ritual Compression Packager
#
#   When rendering ends and the tombs are aligned,
#   This script collects what rot left behind.
#   With tarball and timestamp, it seals the decay,
#   And preps it for transit or end-of-day.
#
#   MODES:
#   - Default: archive only rendered output/
#   - --self:  full system bundle (rotkeeper.sh, bones/, home/, output/)
#   - --dry-run: preview without writing
#
#   FUTURE:
#   - Modular targeting, asset tagging, alt formats (Tiki, Sora, etc.)
#
# 💀 MANDATE:
# Preserve the rot. Export with intention. Archive before deletion.
# =============================================================================
main() {
    log "INFO" "Running rc-pack.sh."

    # --- Flag parsing ---
    DRY_RUN=false
    SELF_MODE=false
    VERBOSE=false
    HELP=false
    for arg in "$@"; do
      case "$arg" in
        --dry-run)   DRY_RUN=true ;;
        --self)      SELF_MODE=true ;;
        --verbose)   VERBOSE=true ;;
        --help|-h)   HELP=true ;;
      esac
    done
    if [[ "$HELP" == true ]]; then
      show_help
    fi

    require_bins tar jq pandoc
    $VERBOSE && log "DEBUG" "Dependencies verified."

    # --- Shared Configuration ---
    CONFIG_DIR="bones"
    ARCHIVE_DIR="$CONFIG_DIR/archive"
    SOURCE_DIR="home/content"
    OUTPUT_DIR="output"
    MANIFEST_FILE="$CONFIG_DIR/manifest.txt"
    VERSION=$(date +%Y-%m-%d_%H%M)
    TOMB="tomb-$VERSION.tar"
    EXPORT_JSON="$ARCHIVE_DIR/tomb-export-$VERSION.json"

    mkdir -p "$ARCHIVE_DIR"
    mkdir -p "$(dirname "$LOG_FILE")"

    # Ensure the rendered output directory exists before packing.
    if [ ! -d "$OUTPUT_DIR" ]; then
      echo "❌ No output directory to pack: $OUTPUT_DIR"
      exit 1
    fi

    if [[ "$SELF_MODE" == false ]]; then
      if [[ "$DRY_RUN" == false ]]; then
        echo "📦 Packing $OUTPUT_DIR into $TOMB"
        run "tar -cf \"$ARCHIVE_DIR/$TOMB\" \"$OUTPUT_DIR\""
        # Count files in the created archive and log summary
        if [[ "$DRY_RUN" == false ]]; then
          count=$(tar -tf "$ARCHIVE_DIR/$TOMB" | wc -l)
          log "INFO" "Packaged $count files into $TOMB"
        fi
        if [[ "$DRY_RUN" == false ]]; then
          SHA=$(sha256sum "$ARCHIVE_DIR/$TOMB" | cut -d' ' -f1)
          echo "$TOMB  $SHA" >> "$MANIFEST_FILE"
        fi

        # Embed metadata into archive
        if [[ "$DRY_RUN" == false ]]; then
          METADATA_FILE="$(mktemp)"
          jq -n \
            --arg name "$TOMB" \
            --arg sha "$SHA" \
            --arg timestamp "$VERSION" \
            --arg mode "default" \
            --arg count "$count" \
            '{name: $name, sha256: $sha, timestamp: $timestamp, mode: $mode, file_count: $count|tonumber}' > "$METADATA_FILE"
          run "tar --append --file=\"$ARCHIVE_DIR/$TOMB\" -C \"$(dirname "$METADATA_FILE")\" \"$(basename "$METADATA_FILE")\""
          run "gzip -f \"$ARCHIVE_DIR/$TOMB\""
          rm "$METADATA_FILE"
          TOMB="$TOMB.gz"
          log "INFO" "Embedded metadata.json into $TOMB"
        fi

        echo "🧾 Archived to $ARCHIVE_DIR/$TOMB"
      else
        log "DRYRUN" "Would pack $OUTPUT_DIR into $ARCHIVE_DIR/$TOMB"
      fi
    fi

    if [[ "$SELF_MODE" == true ]]; then
      SELF_ARCHIVE="tombkit-$VERSION.tar"
      echo "📦 Packing full rotkeeper system into $SELF_ARCHIVE"
      run "tar --exclude=\"$ARCHIVE_DIR\" -cf \"$ARCHIVE_DIR/$SELF_ARCHIVE\" rotkeeper.sh bones/ home/ output/"
      # Count files in the self archive and log summary
      if [[ "$DRY_RUN" == false ]]; then
        count=$(tar -tf "$ARCHIVE_DIR/$SELF_ARCHIVE" | wc -l)
        log "INFO" "Packaged $count files into $SELF_ARCHIVE"
      fi
      if [[ "$DRY_RUN" == false ]]; then
        SHA=$(sha256sum "$ARCHIVE_DIR/$SELF_ARCHIVE" | cut -d' ' -f1)
        echo "$SELF_ARCHIVE  $SHA" >> "$MANIFEST_FILE"
      fi

      # Embed metadata into archive
      if [[ "$DRY_RUN" == false ]]; then
        METADATA_FILE="$(mktemp)"
        jq -n \
          --arg name "$SELF_ARCHIVE" \
          --arg sha "$SHA" \
          --arg timestamp "$VERSION" \
          --arg mode "self" \
          --arg count "$count" \
          '{name: $name, sha256: $sha, timestamp: $timestamp, mode: $mode, file_count: $count|tonumber}' > "$METADATA_FILE"
        run "tar --append --file=\"$ARCHIVE_DIR/$SELF_ARCHIVE\" -C \"$(dirname "$METADATA_FILE")\" \"$(basename "$METADATA_FILE")\""
        run "gzip -f \"$ARCHIVE_DIR/$SELF_ARCHIVE\""
        rm "$METADATA_FILE"
        SELF_ARCHIVE="$SELF_ARCHIVE.gz"
        log "INFO" "Embedded metadata.json into $SELF_ARCHIVE"
      fi

      echo "🧾 Archived full tombkit to $ARCHIVE_DIR/$SELF_ARCHIVE"
    fi

    if [[ "$SELF_MODE" == false ]]; then
      # --- Optional JSON Export ---
      # Export all Markdown files from the source content directory into a single JSON array.

      if [[ "$DRY_RUN" == false ]]; then
        echo "🧬 Exporting .md from $SOURCE_DIR to JSON: $EXPORT_JSON"
        TMP_EXPORT=$(mktemp)
        echo "[" > "$TMP_EXPORT"
        FIRST=true
        find "$SOURCE_DIR" -name '*.md' | while read -r mdfile; do
          if ! CONTENT=$(pandoc "$mdfile" -t json 2>/dev/null); then
            log "ERROR" "Pandoc failed on $mdfile, skipping."
            continue
          fi

          JSON_ENTRY=$(jq -n --arg path "$mdfile" --argjson content "$CONTENT" \
            '{path: $path, pandoc_json: $content}')

          if [ "$FIRST" = true ]; then
            FIRST=false
          else
            echo "," >> "$TMP_EXPORT"
          fi
          echo "$JSON_ENTRY" >> "$TMP_EXPORT"
        done
        echo "]" >> "$TMP_EXPORT"
        run "mv \"$TMP_EXPORT\" \"$EXPORT_JSON\""
        echo "$EXPORT_JSON" >> "$MANIFEST_FILE"
        echo "✅ Export complete: $EXPORT_JSON"
      else
        log "DRYRUN" "Would export markdown from $SOURCE_DIR to JSON: $EXPORT_JSON"
      fi
    fi
    log "INFO" "rc-pack.sh completed successfully."
}

main "$@"
