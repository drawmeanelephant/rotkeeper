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
#  Script  : rc-sitemap.sh
#  Purpose : Extract sitemap/navigation info from the most recent render log
#  Version : 0.3.0.4
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

set -euo pipefail
VERBOSE=""
DRY_RUN=""
HELP=""
 # Ensure environment variables are loaded early and reliably
 source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/rc-env.sh"
TMP_YAML=""
trap '[[ -n "${TMP_YAML:-}" ]] && rm -f "$TMP_YAML"' EXIT
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-sitemap.sh
# Purpose: Extract sitemap/navigation info from the most recent render log
# Requires: rc-env.sh, rc-utils.sh


VERBOSE=""
DRY_RUN=""
HELP=""

source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --verbose) VERBOSE=true; shift ;;
    --help|-h) HELP=true; shift ;;
    *) break ;;
  esac
done

# Locate latest render log
RENDER_LOG="${1:-$(ls -t "$LOG_DIR"/rc-render-*.log 2>/dev/null | head -n 1)}"

if [[ -z "$RENDER_LOG" || ! -f "$RENDER_LOG" ]]; then
  if [[ "$DRY_RUN" == true ]]; then
    log "DRYRUN" "No render log found in $LOG_DIR (skipping exit)"
  else
    log "ERROR" "No render log found in $LOG_DIR."
    exit 1
  fi
fi

log "INFO" "Using render log: $RENDER_LOG"
OUTPUT_YAML="$REPORT_DIR/site-index.yaml"
if [[ -z "$REPORT_DIR" || ! -d "$REPORT_DIR" ]]; then
  echo "[WARN] REPORT_DIR not found or empty; defaulting to local output"
  OUTPUT_YAML="./site-index.yaml"
fi

echo "[DEBUG] REPORT_DIR = $REPORT_DIR"
echo "[DEBUG] OUTPUT_YAML = $OUTPUT_YAML"
echo "[DEBUG] ROOT_DIR = $ROOT_DIR"

TMP_YAML=$(mktemp)
echo "[DEBUG] TMP_YAML created: $TMP_YAML"
touch "$TMP_YAML" || echo "[ERROR] Cannot write to TMP_YAML"
echo "---" > "$TMP_YAML"

# Parse render lines and extract metadata from source files
grep 'Rendering' "$RENDER_LOG" | while IFS= read -r line; do
  SRC=$(echo "$line" | awk -F'Rendering | with template:' '{print $2}')
  SLUG=$(basename "$SRC" .md)
  SRC_PATH="$ROOT_DIR/$SRC"

  echo "- slug: $SLUG" >> "$TMP_YAML"
  echo "  path: \"$SRC\"" >> "$TMP_YAML"
done

echo "[DEBUG] Final YAML output contents:"
cat "$TMP_YAML"

mv "$TMP_YAML" "$OUTPUT_YAML"
log "INFO" "Sitemap written to: $OUTPUT_YAML"
