#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
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
#  Version : 0.5.1
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================
show_help() {
  cat << EOF
rc-pack.sh — Ritual Compression Packager (v$VERSION)

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


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
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

PARTIAL_ARCHIVE=""

# --- cleanup: on failure, remove any half-written archive so no partial
# --- tomb (bare .tar or truncated .gz) survives an interrupted pack.
cleanup() {
  if [[ "${cleanup_ran:-false}" == true ]]; then return 0; fi
  cleanup_ran=true
  if [[ -n "$PARTIAL_ARCHIVE" ]]; then
    rm -f "$PARTIAL_ARCHIVE" "$PARTIAL_ARCHIVE.gz"
    log "WARN" "Removed partial archive after failure: ${PARTIAL_ARCHIVE##*/}"
  fi
}

# --- pack_archive: run a tar command, record the entry count, and register
# --- the target as an in-flight partial for cleanup on failure.
pack_archive() {
  local target="$1"
  shift
  PARTIAL_ARCHIVE="$target"
  run "$@"
  count=$(tar -tf "$target" | wc -l | tr -d ' ')
  log "INFO" "Packaged $count files into ${target##*/}"
}

# --- validate_gz: confirm a freshly compressed archive is not truncated.
validate_gz() {
  local gz="$1"
  if ! gzip -t "$gz" 2>/dev/null; then
    log "ERROR" "Archive integrity check failed: $gz"
    return 1
  fi
  PARTIAL_ARCHIVE=""
  log "INFO" "Archive integrity verified: ${gz##*/}"
  return 0
}

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

    require_bins bash jq tar gzip
    require_sha256
    require_yq_version
    $VERBOSE && log "DEBUG" "Dependencies verified."

    # --- Shared Configuration ---
    CONFIG_DIR="$CONFIG_DIR"
    ARCHIVE_DIR="$ARCHIVE_DIR"
    SOURCE_DIR="$CONTENT_DIR"
    OUTPUT_DIR="$OUTPUT_DIR"
    MANIFEST_FILE="$BONES_DIR/manifest.txt"
    TIMESTAMP_VERSION=$(date +%Y-%m-%d_%H%M%S)
    # Collision hardening: %N (nanoseconds) is GNU-only, so two packs within
    # the same second would otherwise name-collide. A per-process random tag
    # keeps every archive name unique on both GNU and BSD platforms.
    TIMESTAMP_VERSION="${TIMESTAMP_VERSION}-$(printf '%04d' $((RANDOM % 10000)))"
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
        pack_archive "$ARCHIVE_DIR/$CONTENT_ARCHIVE" \
          tar --exclude="${CONTENT_DIR#"$ROOT_DIR"/}/help" \
              --exclude="*_temp.md" \
              -cf "$ARCHIVE_DIR/$CONTENT_ARCHIVE" "${CONTENT_DIR#"$ROOT_DIR"/}"
        run gzip -f "$ARCHIVE_DIR/$CONTENT_ARCHIVE"
        validate_gz "$ARCHIVE_DIR/$CONTENT_ARCHIVE.gz" || exit 1
        CONTENT_ARCHIVE="$CONTENT_ARCHIVE.gz"
        SHA=$(rk_sha256 "$ARCHIVE_DIR/$CONTENT_ARCHIVE" | cut -d' ' -f1)
        rel_archive="${ARCHIVE_DIR#"$ROOT_DIR"/}/$CONTENT_ARCHIVE"
        echo "$rel_archive  $SHA" >> "$MANIFEST_FILE"
        log "INFO" "Archived content to $CONTENT_ARCHIVE"
        echo "🧾 Archived source content to \"$ARCHIVE_DIR/$CONTENT_ARCHIVE\""
      else
        log "DRYRUN" "Would pack \"$SOURCE_DIR\" into \"$ARCHIVE_DIR/$CONTENT_ARCHIVE.gz\""
      fi
    fi

    if [[ "$SELF_MODE" == false && "$CONTENT_MODE" == false ]]; then
      if [[ "$DRY_RUN" == false ]]; then
        echo "📦 Packing \"$OUTPUT_DIR\" into \"$TOMB\""
        pack_archive "$ARCHIVE_DIR/$TOMB" \
          tar -C "$ROOT_DIR" -cf "$ARCHIVE_DIR/$TOMB" "${OUTPUT_DIR#"$ROOT_DIR"/}"
        SHA_UNCOMPRESSED=$(rk_sha256 "$ARCHIVE_DIR/$TOMB" | cut -d' ' -f1)

        # Embed metadata into archive as metadata.json
        PACK_META_DIR=$(mktemp -d "$TMP_DIR/packmeta.XXXXXX" 2>/dev/null || mktemp -d)
        jq -n \
          --arg name "$TOMB" \
          --arg sha "$SHA_UNCOMPRESSED" \
          --arg timestamp "$TIMESTAMP_VERSION" \
          --arg mode "default" \
          --arg count "$count" \
          '{name: $name, sha256: $sha, timestamp: $timestamp, mode: $mode, file_count: $count|tonumber}' > "$PACK_META_DIR/metadata.json"
        run tar --append --file="$ARCHIVE_DIR/$TOMB" -C "$PACK_META_DIR" metadata.json
        rm -rf "$PACK_META_DIR"
        run gzip -f "$ARCHIVE_DIR/$TOMB"
        validate_gz "$ARCHIVE_DIR/$TOMB.gz" || exit 1
        TOMB="$TOMB.gz"
        SHA_COMPRESSED=$(rk_sha256 "$ARCHIVE_DIR/$TOMB" | cut -d' ' -f1)
        rel_tomb="${ARCHIVE_DIR#"$ROOT_DIR"/}/$TOMB"
        echo "$rel_tomb  $SHA_COMPRESSED" >> "$MANIFEST_FILE"
        log "INFO" "Embedded metadata.json into $TOMB"

        echo "🧾 Archived to \"$ARCHIVE_DIR/$TOMB\""
        echo "📦 Tomb summary: $(basename "$TOMB") | sha256 ${SHA_COMPRESSED:0:16}… | files $count | $(du -h "$ARCHIVE_DIR/$TOMB" | cut -f1)"
      else
        log "DRYRUN" "Would pack \"$OUTPUT_DIR\" into \"$ARCHIVE_DIR/$TOMB\""
      fi
    fi

    if [[ "$SELF_MODE" == true ]]; then
      SELF_ARCHIVE="tombkit-$TIMESTAMP_VERSION.tar"
      if [[ "$DRY_RUN" == false ]]; then
        echo "📦 Packing full rotkeeper system into \"$SELF_ARCHIVE\""
        pack_archive "$ARCHIVE_DIR/$SELF_ARCHIVE" \
          tar --exclude="$ARCHIVE_DIR" -C "$ROOT_DIR" -cf "$ARCHIVE_DIR/$SELF_ARCHIVE" rotkeeper.sh "${BONES_DIR#"$ROOT_DIR"/}/" "${CONTENT_DIR#"$ROOT_DIR"/}/" "${OUTPUT_DIR#"$ROOT_DIR"/}/"
        SHA=$(rk_sha256 "$ARCHIVE_DIR/$SELF_ARCHIVE" | cut -d' ' -f1)
        echo "$SELF_ARCHIVE  $SHA" >> "$MANIFEST_FILE"

        # Embed metadata into archive as metadata.json
        PACK_META_DIR=$(mktemp -d "$TMP_DIR/packmeta.XXXXXX" 2>/dev/null || mktemp -d)
        jq -n \
          --arg name "$SELF_ARCHIVE" \
          --arg sha "$SHA" \
          --arg timestamp "$TIMESTAMP_VERSION" \
          --arg mode "self" \
          --arg count "$count" \
          '{name: $name, sha256: $sha, timestamp: $timestamp, mode: $mode, file_count: $count|tonumber}' > "$PACK_META_DIR/metadata.json"
        run tar --append --file="$ARCHIVE_DIR/$SELF_ARCHIVE" -C "$PACK_META_DIR" metadata.json
        rm -rf "$PACK_META_DIR"
        run gzip -f "$ARCHIVE_DIR/$SELF_ARCHIVE"
        validate_gz "$ARCHIVE_DIR/$SELF_ARCHIVE.gz" || exit 1
        SELF_ARCHIVE="$SELF_ARCHIVE.gz"
        log "INFO" "Embedded metadata.json into $SELF_ARCHIVE"

        echo "🧾 Archived full tombkit to \"$ARCHIVE_DIR/$SELF_ARCHIVE\""
      else
        log "DRYRUN" "Would pack full rotkeeper system into \"$ARCHIVE_DIR/$SELF_ARCHIVE.gz\""
      fi
    fi

    if [[ "$SELF_MODE" == false && "$CONTENT_MODE" == false ]]; then
      # --- Optional JSON Export ---
      # Export all Markdown files from the source content directory into a single JSON array.

      if [[ "$DRY_RUN" == false ]]; then
        echo "🧬 Exporting .md from \"$SOURCE_DIR\" to JSON: \"$EXPORT_JSON\""
        TMP_EXPORT=$(mktemp "$TMP_DIR/packexport.XXXXXX" 2>/dev/null || mktemp)
        echo "[" > "$TMP_EXPORT"
        FIRST=true

        while IFS= read -r -d '' mdfile; do
          ABS_PATH=$(rk_canonical_path "$mdfile")
          REL_PATH="${mdfile#"$ROOT_DIR"/}"
          FM_CONTENT=$(yq --front-matter="extract" -o=json '.' "$mdfile" 2>/dev/null || echo "{}")

          JSON_ENTRY=$(jq -n --arg abs "$ABS_PATH" --arg rel "$REL_PATH" --rawfile src "$mdfile" --argjson fm "$FM_CONTENT" \
            '{absolute_path: $abs, relative_path: $rel, frontmatter: (if $fm != null then $fm else {} end), source_markdown: $src}')

          if [ "$FIRST" = true ]; then
            FIRST=false
          else
            echo "," >> "$TMP_EXPORT"
          fi
          echo "$JSON_ENTRY" >> "$TMP_EXPORT"
        done < <(find "$SOURCE_DIR" -name '*.md' -print0)
        echo "]" >> "$TMP_EXPORT"

        if jq empty "$TMP_EXPORT" >/dev/null 2>&1; then
            cp "$TMP_EXPORT" "$TMP_EXPORT.final"
            run mv "$TMP_EXPORT.final" "$EXPORT_JSON"
            rel_export="${EXPORT_JSON#"$ROOT_DIR"/}"
            echo "$rel_export" >> "$MANIFEST_FILE"
            echo "✅ Export complete: \"$EXPORT_JSON\""
        else
            log "ERROR" "Generated JSON is invalid, aborting export."
            exit 1
        fi
        rm -f "$TMP_EXPORT" "$TMP_EXPORT.final" || true
      else
        log "DRYRUN" "Would export markdown from \"$SOURCE_DIR\" to JSON: \"$EXPORT_JSON\""
      fi
    fi
    log "INFO" "rc-pack.sh completed successfully."
}

main "$@"
