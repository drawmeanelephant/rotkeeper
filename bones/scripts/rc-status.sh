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
#  Script  : rc-status.sh
#  Purpose : Output a high-level status report on recent rituals and artifacts
#  Version : 0.3.0.8
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

source "$(dirname "$0")/rc-utils.sh"
set -euo pipefail
IFS=$'\n\t'

LOG_FILE="$LOG_DIR/rc-status-$(date +%Y-%m-%d_%H%M).log"
mkdir -p "$LOG_DIR"

log() {
  local level="$1"; shift
  printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" | tee -a "$LOG_FILE"
}

log "INFO" "Running rc-status.sh"
check_dependencies

echo "🩺 Rotkeeper Status Report"
echo "=========================="

# Last record entry
if [[ -f "$LOG_DIR/record.log" ]]; then
  echo "🧾 Last Record:"
  tail -n 5 "$LOG_DIR/record.log" | sed 's/^/   /'
else
  echo "🧾 No record log found."
fi


# Last pack artifact
if ls "$ARCHIVE_DIR"/*.tar.gz 1> /dev/null 2>&1; then
  latest_pack=$(ls -t "$ARCHIVE_DIR"/*.tar.gz | head -n1)
  echo -e "\n📦 Latest Tomb:"
  echo "   $(basename "$latest_pack")"
else
  echo -e "\n📦 No packed archive found."
fi

# Last render output
if [[ -d "$OUTPUT_DIR" ]]; then
  rendered=$(find "$OUTPUT_DIR" -type f -name '*.html' | wc -l | xargs)
  echo -e "\n🖋 Rendered HTML Files:"
  echo "   $rendered file(s) in $OUTPUT_DIR/"
else
  echo -e "\n🖋 Rendered HTML Files:"
  echo "   No $OUTPUT_DIR/ found."
fi

# Available templates
if [[ -d "bones/templates" ]]; then
  echo -e "\n🎨 Available Templates:"
  for t in bones/templates/*.html; do
    [[ -f "$t" ]] && echo "   - $(basename "$t")"
  done
fi

# Git status
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  commit=$(git rev-parse --short HEAD)
  branch=$(git rev-parse --abbrev-ref HEAD)
  echo -e "\n🌱 Git:"
  echo "   Branch: $branch"
  echo "   Commit: $commit"
else
  echo -e "\n🌱 Git: Not a repo"
fi

log "INFO" "rc-status.sh completed"
