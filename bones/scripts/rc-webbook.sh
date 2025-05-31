#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-webbook.sh
# Purpose: Bundle rendered HTML output into a single markdown reference book
# Version: 0.2.1
# Updated: 2025-05-29
# -----------------------------------------

# Source shared Rotkeeper helpers
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"

set -euo pipefail

# Parse common flags and handle help
parse_flags "$@"
if [[ "$HELP" == true ]]; then
  show_help
fi

# Ensure log directory exists and set up LOG_FILE
SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPTDIR/../logs/rc-webbook-$(date +%Y-%m-%d_%H%M).log"
mkdir -p "$(dirname "$LOG_FILE")"

main() {
  require_bins find mkdir cat
  log "INFO" "Running rc-webbook.sh."

  OUTPUT="bones/reports/rotkeeper-webbook.md"
  SOURCE_DIR="output"

  # Prepare output file
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "Would create directory $(dirname \"$OUTPUT\")"
    log "DRY-RUN" "Would write header to $OUTPUT"
  else
    mkdir -p "$(dirname "$OUTPUT")"
    echo "# 🌐 Rotkeeper Rendered Output Book" > "$OUTPUT"
    echo "" >> "$OUTPUT"
  fi

  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "Would append webbook entries for HTML files in $SOURCE_DIR"
  else
    log "INFO" "Appending webbook entries"
    while IFS= read -r file; do
      {
        echo "## 🌐 $file"
        echo '```html'
        cat "$file"
        echo '```'
        echo ""
      } >> "$OUTPUT"
    done < <(find "$SOURCE_DIR" -type f -name "*.html" | sort)
  fi

  log "INFO" "✅ Webbook compiled to $OUTPUT"
}

main "$@"
