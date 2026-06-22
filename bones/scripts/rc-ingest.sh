#!/usr/bin/env bash
# ============================================================
#  ██╗███╗   ██╗ ██████╗ ███████╗███████╗████████╗
#  ██║████╗  ██║██╔════╝ ██╔════╝██╔════╝╚══██╔══╝
#  ██║██╔██╗ ██║██║  ███╗█████╗  ███████╗   ██║
#  ██║██║╚██╗██║██║   ██║██╔══╝  ╚════██║   ██║
#  ██║██║ ╚████║╚██████╔╝███████╗███████║   ██║
#  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚══════╝   ╚═╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-ingest.sh
#  Purpose : Ingests .tar.gz archives from an inbox into the local content repository safely
#  Version : 0.3.1.4
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

show_help() {
  cat << EOF
rc-ingest.sh — Rotkeeper Ingestion Pipeline

Usage: rc-ingest.sh [options]

Options:
  --version, -v    Show script version and quit
  --help, -h       Show this help message and exit
  --inbox DIR      Specify a custom inbox directory (default: messages-from-my-friends)
  --verbose        Enable detailed debug logging
EOF
  exit 0
}

source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
rk_init_script "rc-ingest" "$@"
set -euo pipefail
IFS=$'\n\t'

VERSION="0.3.1.4"


# --- Shared Configuration ---
INBOX_DIR="messages-from-my-friends"

# --- Flag parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version|-v) echo "$(basename "$0") v${VERSION:-unknown}"; exit 0 ;;
    --inbox)     INBOX_DIR="$2"; shift 2 ;;
    --verbose)   VERBOSE=true; shift ;;
    --help|-h)   show_help ;;
    *) break ;;
  esac
done

main() {
    log "INFO" "Running rc-ingest.sh"
    check_dependencies

    INGESTED_ARCHIVE_DIR="bones/ingested"
    TARGET_CONTENT_DIR="$CONTENT_DIR/messages"

    mkdir -p "$INGESTED_ARCHIVE_DIR"
    mkdir -p "$TARGET_CONTENT_DIR"
    mkdir -p "$INBOX_DIR"

    # Check for .tar.gz files in the inbox
    shopt -s nullglob
    archives=("$INBOX_DIR"/*.tar.gz)
    shopt -u nullglob

    if [[ ${#archives[@]} -eq 0 ]]; then
      echo "📭 Inbox is empty. No new messages found in $INBOX_DIR/."
      log "INFO" "No archives found to ingest."
      exit 0
    fi

    echo "📬 Found ${#archives[@]} message(s) in inbox. Beginning ingestion..."

    for archive in "${archives[@]}"; do
      basename_archive=$(basename "$archive" .tar.gz)
      echo "📦 Ingesting: $(basename "$archive")"
      log "INFO" "Ingesting $archive"

      # Create safe subdirectory for this specific payload
      SAFE_DEST="$TARGET_CONTENT_DIR/$basename_archive"
      if [[ -d "$SAFE_DEST" ]]; then
        log "WARN" "Destination $SAFE_DEST already exists. Appending timestamp."
        SAFE_DEST="${SAFE_DEST}_$(date +%s)"
      fi
      mkdir -p "$SAFE_DEST"

      # Extract to temp
      TMP_EXTRACT=$(mktemp -d)
      run tar -xzf "$archive" -C "$TMP_EXTRACT"

      # Retroactive cleanup: remove redundant docs from older payloads
      rm -rf "$TMP_EXTRACT/home/content/docs" "$TMP_EXTRACT/home/content/help" 2>/dev/null || true
      rm -f "$TMP_EXTRACT/home/content/"*_temp.md 2>/dev/null || true

      # Identify if the archive has a home/content directory structure
      if [[ -d "$TMP_EXTRACT/home/content" ]]; then
        # Move everything from home/content into the safe destination
        run mv "$TMP_EXTRACT"/home/content/* "$SAFE_DEST"/ 2>/dev/null || true
      else
        # Just move everything from the root of the extract
        run mv "$TMP_EXTRACT"/* "$SAFE_DEST"/ 2>/dev/null || true
      fi

      rm -rf "$TMP_EXTRACT"

      # Move original archive to ingested vault
      run mv "$archive" "$INGESTED_ARCHIVE_DIR/"
      echo "✅ Successfully unboxed into home/content/messages/$(basename "$SAFE_DEST")/"
    done

    echo "🎉 Ingestion complete! Applying navigation glue..."
    bash "$SCRIPT_DIR/rc-glue.sh" || true
    echo "🎉 Run ./rotkeeper.sh render to compile."
    log "INFO" "rc-ingest.sh completed successfully."
}

main "$@"
