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
# Env assumptions: reads ARCHIVE_DIR, BONES_DIR, CONFIG_DIR, CONTENT_DIR, DEBUG, DOCS_DIR, DRY_RUN, LOG_DIR, OUTPUT_DIR, ROOT_DIR, SCRIPT_DIR, TMP_DIR, VERBOSE, VERSION (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.
# CWD assumptions: No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.
# Input/Output contracts: CLI args and env vars in; files and stdout/stderr out; respects --dry-run (no writes) and --verbose.
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-pack.sh
#  Purpose : Bundle rendered output into versioned .tar.gz archive and export markdown to JSON
#  Version : 0.5.1
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================
# @HELP
# rc-pack.sh — Ritual Compression Packager (v{VERSION})
#
# Usage:
#   rotkeeper.sh pack [options]
#
# Description:
#   Archives rendered output into a unique versioned tar.gz tomb.
#   Default mode packs output/; --self bundles the whole system;
#   --content preserves source content only.
#
# Options:
#   --self           Archive the full Rotkeeper system (rotkeeper.sh, bones/, home/, output/)
#   --content        Archive only the home/content directory to preserve source files
#   --dry-run        Preview actions without writing files
#   --verbose        Enable detailed debug logging
#   --help, -h       Show this help message and exit
#   --version, -v    Show script version and quit
#
# Examples:
#   bash rotkeeper.sh pack                    Archive rendered output into a tomb
#   bash rotkeeper.sh pack --self             Full-system bundle
#   bash rotkeeper.sh pack --content --dry-run
#
# Exit codes:
#   0    Success
#   1    Packaging or archive-validation failure
# @END-HELP


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
rk_init_script "rc-pack" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR CONTENT_DIR DOCS_DIR OUTPUT_DIR



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
    # SIDE EFFECT (delete): removes half-written .tar and .gz from bones/archives after failure
    rm -f "$PARTIAL_ARCHIVE" "$PARTIAL_ARCHIVE.gz" || true
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
  # Count archive entries: tar -tf lists members, wc -l counts them.
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

# ---
# main: Pack output/content/self archives and export markdown JSON.
# Inputs: $@ (--self, --content, --dry-run, --verbose, --help)
# Outputs: Writes archives and export JSON under ARCHIVE_DIR; prunes on failure
# Env: Reads ARCHIVE_DIR, BONES_DIR, CONFIG_DIR, CONTENT_DIR, DEBUG, DRY_RUN ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
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

    # SIDE EFFECT (write): creates bones/archives and bones/logs if missing
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
        # SIDE EFFECT (archive): writes tomb-content-<ts>.tar (then .gz) under bones/archives
        pack_archive "$ARCHIVE_DIR/$CONTENT_ARCHIVE" \
          tar --exclude="${CONTENT_DIR#"$ROOT_DIR"/}/help" \
              --exclude="*_temp.md" \
              -cf "$ARCHIVE_DIR/$CONTENT_ARCHIVE" "${CONTENT_DIR#"$ROOT_DIR"/}"
        # SIDE EFFECT (write): gzips the content archive in place, replacing the bare .tar
        run gzip -f "$ARCHIVE_DIR/$CONTENT_ARCHIVE"
        validate_gz "$ARCHIVE_DIR/$CONTENT_ARCHIVE.gz" || exit 1
        CONTENT_ARCHIVE="$CONTENT_ARCHIVE.gz"
        SHA=$(rk_sha256 "$ARCHIVE_DIR/$CONTENT_ARCHIVE" | cut -d' ' -f1)
        rel_archive="${ARCHIVE_DIR#"$ROOT_DIR"/}/$CONTENT_ARCHIVE"
        # SIDE EFFECT (write): appends "<path>  <sha256>" line to bones/manifest.txt
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
        # SIDE EFFECT (archive): writes tomb-<ts>.tar under bones/archives
        pack_archive "$ARCHIVE_DIR/$TOMB" \
          tar -C "$ROOT_DIR" -cf "$ARCHIVE_DIR/$TOMB" "${OUTPUT_DIR#"$ROOT_DIR"/}"
        SHA_UNCOMPRESSED=$(rk_sha256 "$ARCHIVE_DIR/$TOMB" | cut -d' ' -f1)

        # Embed metadata into archive as metadata.json
        # SIDE EFFECT (write): mktemp creates a scratch dir under bones/tmp (or system tmp)
        PACK_META_DIR=$(mktemp -d "$TMP_DIR/packmeta.XXXXXX" 2>/dev/null || mktemp -d)
        # SIDE EFFECT (write): serializes metadata.json into the scratch dir
        jq -n \
          --arg name "$TOMB" \
          --arg sha "$SHA_UNCOMPRESSED" \
          --arg timestamp "$TIMESTAMP_VERSION" \
          --arg mode "default" \
          --arg count "$count" \
          '{name: $name, sha256: $sha, timestamp: $timestamp, mode: $mode, file_count: $count|tonumber}' > "$PACK_META_DIR/metadata.json"
        # SIDE EFFECT (archive): appends metadata.json member to tomb-<ts>.tar
        run tar --append --file="$ARCHIVE_DIR/$TOMB" -C "$PACK_META_DIR" metadata.json
        if ! CANONICAL_PACK_META=$(rk_guard_delete "$PACK_META_DIR" "$(dirname -- "$PACK_META_DIR")"); then
          echo "ERROR: Aborting pack; refusing unsafe deletion of '$PACK_META_DIR'." >&2
          exit 1
        fi
        # SIDE EFFECT (delete): removes the metadata.json scratch dir
        rm -rf "$CANONICAL_PACK_META"
        # SIDE EFFECT (write): gzips the tomb in place, replacing the bare .tar
        run gzip -f "$ARCHIVE_DIR/$TOMB"
        validate_gz "$ARCHIVE_DIR/$TOMB.gz" || exit 1
        TOMB="$TOMB.gz"
        SHA_COMPRESSED=$(rk_sha256 "$ARCHIVE_DIR/$TOMB" | cut -d' ' -f1)
        rel_tomb="${ARCHIVE_DIR#"$ROOT_DIR"/}/$TOMB"
        # SIDE EFFECT (write): appends "<path>  <sha256>" line to bones/manifest.txt
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
        # SIDE EFFECT (archive): writes tombkit-<ts>.tar (full system bundle) under bones/archives
        pack_archive "$ARCHIVE_DIR/$SELF_ARCHIVE" \
          tar --exclude="${ARCHIVE_DIR#"$ROOT_DIR"/}" --exclude="${ARCHIVE_DIR#"$ROOT_DIR"/}/*" -C "$ROOT_DIR" -cf "$ARCHIVE_DIR/$SELF_ARCHIVE" rotkeeper.sh "${BONES_DIR#"$ROOT_DIR"/}/" "${CONTENT_DIR#"$ROOT_DIR"/}/" "${OUTPUT_DIR#"$ROOT_DIR"/}/"
        SHA=$(rk_sha256 "$ARCHIVE_DIR/$SELF_ARCHIVE" | cut -d' ' -f1)
        # SIDE EFFECT (write): appends "<archive>  <sha256>" line to bones/manifest.txt
        echo "$SELF_ARCHIVE  $SHA" >> "$MANIFEST_FILE"

        # Embed metadata into archive as metadata.json
        # SIDE EFFECT (write): mktemp creates a scratch dir under bones/tmp (or system tmp)
        PACK_META_DIR=$(mktemp -d "$TMP_DIR/packmeta.XXXXXX" 2>/dev/null || mktemp -d)
        # SIDE EFFECT (write): serializes metadata.json into the scratch dir
        jq -n \
          --arg name "$SELF_ARCHIVE" \
          --arg sha "$SHA" \
          --arg timestamp "$TIMESTAMP_VERSION" \
          --arg mode "self" \
          --arg count "$count" \
          '{name: $name, sha256: $sha, timestamp: $timestamp, mode: $mode, file_count: $count|tonumber}' > "$PACK_META_DIR/metadata.json"
        # SIDE EFFECT (archive): appends metadata.json member to tombkit-<ts>.tar
        run tar --append --file="$ARCHIVE_DIR/$SELF_ARCHIVE" -C "$PACK_META_DIR" metadata.json
        if ! CANONICAL_PACK_META=$(rk_guard_delete "$PACK_META_DIR" "$(dirname -- "$PACK_META_DIR")"); then
          echo "ERROR: Aborting pack; refusing unsafe deletion of '$PACK_META_DIR'." >&2
          exit 1
        fi
        # SIDE EFFECT (delete): removes the metadata.json scratch dir
        rm -rf "$CANONICAL_PACK_META"
        # SIDE EFFECT (write): gzips the tombkit in place, replacing the bare .tar
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
        # SIDE EFFECT (write): mktemp creates scratch files under bones/tmp (or system tmp)
        TMP_EXPORT=$(mktemp "$TMP_DIR/packexport.XXXXXX" 2>/dev/null || mktemp)
        echo "[" > "$TMP_EXPORT"
        FIRST=true

        local _tmp_pack_find
        local _find_pack
        _find_pack="$(rk_find_command)"
        _tmp_pack_find=$(mktemp)
        "$_find_pack" "$SOURCE_DIR" -name '*.md' -print0 > "$_tmp_pack_find" 2>/dev/null || true
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
        done < "$_tmp_pack_find"
        # SIDE EFFECT (delete): removes the find scratch file
        rm -f "$_tmp_pack_find"
        echo "]" >> "$TMP_EXPORT"

        if jq empty "$TMP_EXPORT" >/dev/null 2>&1; then
            # SIDE EFFECT (write): atomically promotes the export into bones/archives/tomb-export-<ts>.json via mv
            cp "$TMP_EXPORT" "$TMP_EXPORT.final"
            run mv "$TMP_EXPORT.final" "$EXPORT_JSON"
            rel_export="${EXPORT_JSON#"$ROOT_DIR"/}"
            # SIDE EFFECT (write): appends the export path line to bones/manifest.txt
            echo "$rel_export" >> "$MANIFEST_FILE"
            echo "✅ Export complete: \"$EXPORT_JSON\""
        else
            log "ERROR" "Generated JSON is invalid, aborting export."
            exit 1
        fi
        # SIDE EFFECT (delete): removes the JSON scratch files
        rm -f "$TMP_EXPORT" "$TMP_EXPORT.final" || true
      else
        log "DRYRUN" "Would export markdown from \"$SOURCE_DIR\" to JSON: \"$EXPORT_JSON\""
      fi
    fi
    log "INFO" "rc-pack.sh completed successfully."
}

main "$@"
