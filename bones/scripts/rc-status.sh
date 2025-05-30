#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-status.sh
# Purpose: Outputs a high-level status report on recent rituals and artifacts
# Version: 0.1.9.9
# Updated: 2025-05-27
# -----------------------------------------
set -euo pipefail
IFS=$'\n\t'

LOG_FILE="bones/logs/rc-status-$(date +%Y-%m-%d_%H%M).log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
  local level="$1"; shift
  printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" | tee -a "$LOG_FILE"
}

log "INFO" "Running rc-status.sh"

echo "🩺 Rotkeeper Status Report"
echo "=========================="

# Last record entry
if [[ -f bones/logs/record.log ]]; then
  echo "🧾 Last Record:"
  tail -n 5 bones/logs/record.log | sed 's/^/   /'
else
  echo "🧾 No record log found."
fi

# Last changelog bless
if [[ -f bones/logs/changelog.md ]]; then
  echo -e "\n📜 Last Blessing:"
  grep -m1 '^## ' bones/logs/changelog.md | sed 's/^/   /'
else
  echo -e "\n📜 No changelog found."
fi

# Last pack artifact
if ls bones/archive/*.tar.gz 1> /dev/null 2>&1; then
  latest_pack=$(ls -t bones/archive/*.tar.gz | head -n1)
  echo -e "\n📦 Latest Tomb:"
  echo "   $(basename "$latest_pack")"
else
  echo -e "\n📦 No packed archive found."
fi

# Last render output
rendered=$(find output -type f -name '*.html' | wc -l | xargs)
echo -e "\n🖋 Rendered HTML Files:"
echo "   $rendered file(s) in output/"

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