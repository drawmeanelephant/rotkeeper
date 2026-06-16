#!/usr/bin/env bash
# ============================================================
#  Project : Rotkeeper
#  Script  : rc-timeline.sh
#  Purpose : Generate a reverse-chronological history report of tombs
# ============================================================

source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
set -euo pipefail
IFS=$'\n\t'

rk_init_script "rc-timeline" "$@"

show_help() {
  cat << EOF
rc-timeline.sh — Generate a tomb timeline

Usage: rc-timeline.sh [options]

Options:
  --help, -h        Show this help message and exit
  --dry-run         Preview actions
  --verbose         Print detailed logs
EOF
  exit 0
}

main() {
  check_dependencies

  log "INFO" "Generating tomb timeline..."

  local TIMELINE_FILE="$REPORT_DIR/rotkeeper-timeline.md"
  
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "Would generate timeline at $TIMELINE_FILE"
    exit 0
  fi

  {
    echo "# Rotkeeper Tomb Timeline"
    echo "Generated on: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "A reverse-chronological history of archived tombs."
    echo ""
    
    if ls "$ARCHIVE_DIR"/*.tar.gz 1> /dev/null 2>&1; then
      # List tar.gz files sorted by modification time (newest first)
      for archive in $(ls -t "$ARCHIVE_DIR"/*.tar.gz); do
        filename=$(basename "$archive")
        filesize=$(du -h "$archive" | cut -f1)
        timestamp=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$archive" 2>/dev/null || stat -c %y "$archive" 2>/dev/null | cut -d'.' -f1)
        
        echo "## $filename"
        echo "- **Date:** $timestamp"
        echo "- **Size:** $filesize"
        
        # If there's an embedded metadata.json, we could extract it, but for a simple timeline, just listing them is enough.
        echo ""
      done
    else
      echo "*No tombs found in $ARCHIVE_DIR.*"
    fi
  } > "$TIMELINE_FILE"

  log "INFO" "Timeline generated at $TIMELINE_FILE"
  echo "Timeline written to $TIMELINE_FILE"
}

main "$@"
