#!/usr/bin/env bash
# ============================================================
#  ██████╗  █████╗  ██████╗██╗  ██╗
#  ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝
#  ██████╔╝███████║██║     █████╔╝
#  ██╔═══╝ ██╔══██║██║     ██╔═██╗
#  ██║     ██║  ██║╚██████╗██║  ██╗
#  ╚═╝     ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-pack.sh
#  Purpose : Bundle rendered output into versioned .tar.gz archive and export markdown to JSON
#  Version : 0.4.0.1
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================
show_help() {
  cat << EOF
rc-pack.sh — Ritual Compression Packager (v0.3.1.4)

Usage: rc-pack.sh [options]

Options:
  --version, -v    Show script version and quit
  --help, -h       Show this help message and exit
  --dry-run        Preview actions without writing files
  --self           Archive the full Rotkeeper system (rotkeeper.sh, bones/, home/, output/)
  --content        Archive only the home/content directory to preserve source files
  --verbose        Enable detailed debug logging
EOF
  exit 0
}

source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
VERSION="${ROTKEEPER_VERSION:-0.3.1.4}"

rk_init_script "rc-pack" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR CONTENT_DIR DOCS_DIR OUTPUT_DIR
set -euo pipefail
IFS=$'\n\t'



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
#   - --content: bundle only the home/content/ directory
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

    SELF_MODE=false
    CONTENT_MODE=false

    # --- Flag parsing ---
    for arg in "$@"; do
      case "$arg" in
        --dry-run)   DRY_RUN=true ;;
        --verbose)   VERBOSE=true ;;
        --help|-h)   show_help ;;
        --self)      SELF_MODE=true ;;
        --content)   CONTENT_MODE=true ;;
      esac
    done

    check_dependencies
    $VERBOSE && log "DEBUG" "Dependencies verified."

    # --- Shared Configuration ---
    CONFIG_DIR="$BONES_DIR"
    ARCHIVE_DIR="$ARCHIVE_DIR"
    SOURCE_DIR="$CONTENT_DIR"
    OUTPUT_DIR="$OUTPUT_DIR"
    MANIFEST_FILE="$CONFIG_DIR/manifest.txt"
    TIMESTAMP_VERSION=$(date +%Y-%m-%d_%H%M)
    TOMB="tomb-$TIMESTAMP_VERSION.tar"
    EXPORT_JSON="$ARCHIVE_DIR/tomb-export-$TIMESTAMP_VERSION.json"

    run mkdir -p "$ARCHIVE_DIR"
    run mkdir -p "$LOG_DIR"

    # Ensure the rendered output directory exists before packing (only if default mode).
    if [[ "$SELF_MODE" == false && "$CONTENT_MODE" == false ]]; then
      if [ ! -d "$OUTPUT_DIR" ]; then
        if [[ "$DRY_RUN" == true ]]; then
          log "DRYRUN" "No output directory to pack: $OUTPUT_DIR (skipping exit)"
        else
          echo "❌ No output directory to pack: $OUTPUT_DIR"
          exit 1
        fi
      fi
    fi

    if [[ "$CONTENT_MODE" == true ]]; then
      CONTENT_ARCHIVE="tomb-content-$TIMESTAMP_VERSION.tar"
      if [[ "$DRY_RUN" == false ]]; then
        echo "📦 Packing \"$SOURCE_DIR\" into \"$CONTENT_ARCHIVE\""
        run tar --exclude="home/content/help" \
                --exclude="*_temp.md" \
                -cf "$ARCHIVE_DIR/$CONTENT_ARCHIVE" "home/content"
        count=$(tar -tf "$ARCHIVE_DIR/$CONTENT_ARCHIVE" | wc -l)
        log "INFO" "Packaged $count files into $CONTENT_ARCHIVE"
        SHA=$(sha256sum "$ARCHIVE_DIR/$CONTENT_ARCHIVE" | cut -d' ' -f1)
        echo "$CONTENT_ARCHIVE  $SHA" >> "$MANIFEST_FILE"

        run gzip -f "$ARCHIVE_DIR/$CONTENT_ARCHIVE"
        CONTENT_ARCHIVE="$CONTENT_ARCHIVE.gz"
        log "INFO" "Archived content to $CONTENT_ARCHIVE"
        echo "🧾 Archived source content to \"$ARCHIVE_DIR/$CONTENT_ARCHIVE\""
      else
        log "DRYRUN" "Would pack \"$SOURCE_DIR\" into \"$ARCHIVE_DIR/$CONTENT_ARCHIVE.gz\""
      fi
    fi

    if [[ "$SELF_MODE" == false && "$CONTENT_MODE" == false ]]; then
      if [[ "$DRY_RUN" == false ]]; then
        echo "📦 Packing \"$OUTPUT_DIR\" into \"$TOMB\""
        run tar -cf "$ARCHIVE_DIR/$TOMB" "$OUTPUT_DIR"
        count=$(tar -tf "$ARCHIVE_DIR/$TOMB" | wc -l)
        log "INFO" "Packaged $count files into $TOMB"
        SHA=$(sha256sum "$ARCHIVE_DIR/$TOMB" | cut -d' ' -f1)
        echo "$TOMB  $SHA" >> "$MANIFEST_FILE"

        # Embed metadata into archive
        METADATA_FILE="$(mktemp)"
        jq -n \
          --arg name "$TOMB" \
          --arg sha "$SHA" \
          --arg timestamp "$TIMESTAMP_VERSION" \
          --arg mode "default" \
          --arg count "$count" \
          '{name: $name, sha256: $sha, timestamp: $timestamp, mode: $mode, file_count: $count|tonumber}' > "$METADATA_FILE"
        run tar --append --file="$ARCHIVE_DIR/$TOMB" -C "$(dirname "$METADATA_FILE")" "$(basename "$METADATA_FILE")"
        run gzip -f "$ARCHIVE_DIR/$TOMB"
        rm "$METADATA_FILE"
        TOMB="$TOMB.gz"
        log "INFO" "Embedded metadata.json into $TOMB"

        echo "🧾 Archived to \"$ARCHIVE_DIR/$TOMB\""
      else
        log "DRYRUN" "Would pack \"$OUTPUT_DIR\" into \"$ARCHIVE_DIR/$TOMB\""
      fi
    fi

    if [[ "$SELF_MODE" == true ]]; then
      SELF_ARCHIVE="tombkit-$TIMESTAMP_VERSION.tar"
      echo "📦 Packing full rotkeeper system into \"$SELF_ARCHIVE\""
      run tar --exclude="$ARCHIVE_DIR" -cf "$ARCHIVE_DIR/$SELF_ARCHIVE" rotkeeper.sh bones/ home/ output/
      count=$(tar -tf "$ARCHIVE_DIR/$SELF_ARCHIVE" | wc -l)
      log "INFO" "Packaged $count files into $SELF_ARCHIVE"
      SHA=$(sha256sum "$ARCHIVE_DIR/$SELF_ARCHIVE" | cut -d' ' -f1)
      echo "$SELF_ARCHIVE  $SHA" >> "$MANIFEST_FILE"

      # Embed metadata into archive
      METADATA_FILE="$(mktemp)"
      jq -n \
        --arg name "$SELF_ARCHIVE" \
        --arg sha "$SHA" \
        --arg timestamp "$TIMESTAMP_VERSION" \
        --arg mode "self" \
        --arg count "$count" \
        '{name: $name, sha256: $sha, timestamp: $timestamp, mode: $mode, file_count: $count|tonumber}' > "$METADATA_FILE"
      run tar --append --file="$ARCHIVE_DIR/$SELF_ARCHIVE" -C "$(dirname "$METADATA_FILE")" "$(basename "$METADATA_FILE")"
      run gzip -f "$ARCHIVE_DIR/$SELF_ARCHIVE"
      rm "$METADATA_FILE"
      SELF_ARCHIVE="$SELF_ARCHIVE.gz"
      log "INFO" "Embedded metadata.json into $SELF_ARCHIVE"

      echo "🧾 Archived full tombkit to \"$ARCHIVE_DIR/$SELF_ARCHIVE\""
    fi

    if [[ "$SELF_MODE" == false && "$CONTENT_MODE" == false ]]; then
      # --- Optional JSON Export ---
      # Export all Markdown files from the source content directory into a single JSON array.

      if [[ "$DRY_RUN" == false ]]; then
        echo "🧬 Exporting .md from \"$SOURCE_DIR\" to JSON: \"$EXPORT_JSON\""
        TMP_EXPORT=$(mktemp)
        echo "[" > "$TMP_EXPORT"
        FIRST=true
        find "$SOURCE_DIR" -name '*.md' | while read -r mdfile; do
          if ! AST_CONTENT=$(pandoc "$mdfile" -t json 2>/dev/null); then
            log "ERROR" "Pandoc failed on $mdfile, skipping."
            continue
          fi

          ABS_PATH=$(realpath "$mdfile")
          REL_PATH="${mdfile#"$ROOT_DIR"/}"
          FM_CONTENT=$(yq --front-matter="extract" -o=json '.' "$mdfile" 2>/dev/null || echo "{}")

          JSON_ENTRY=$(jq -n --arg abs "$ABS_PATH" --arg rel "$REL_PATH" --argjson ast "$AST_CONTENT" --argjson fm "$FM_CONTENT" \
            '{absolute_path: $abs, relative_path: $rel, frontmatter: (if $fm != null then $fm else {} end), pandoc_ast: (if $ast != null then $ast else {} end)}')

          if [ "$FIRST" = true ]; then
            FIRST=false
          else
            echo "," >> "$TMP_EXPORT"
          fi
          echo "$JSON_ENTRY" >> "$TMP_EXPORT"
        done
        echo "]" >> "$TMP_EXPORT"
        run mv "$TMP_EXPORT" "$EXPORT_JSON"
        echo "$EXPORT_JSON" >> "$MANIFEST_FILE"
        echo "✅ Export complete: \"$EXPORT_JSON\""
      else
        log "DRYRUN" "Would export markdown from \"$SOURCE_DIR\" to JSON: \"$EXPORT_JSON\""
      fi
    fi
    log "INFO" "rc-pack.sh completed successfully."
}

main "$@"
