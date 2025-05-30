#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-docs-fix.sh
# Purpose: Search, replace, and backup doc files based on given pattern
# Version: 0.1.9.9
# Updated: 2025-05-27
# -----------------------------------------
set -euo pipefail
IFS=$'\n\t'

LOGDIR="bones/logs"
mkdir -p "$LOGDIR"
LOG_FILE="$LOGDIR/rc-docs-fix.log"

log() {
    local level="$1"; shift
    printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" | tee -a "$LOG_FILE"
}

cleanup() {
    log "INFO" "Cleaning up after rc-docs-fix.sh."
    # Add cleanup commands here
}
trap cleanup EXIT INT TERM

check_dependencies() {
    local deps=(git rsync ssh pandoc date)
    for cmd in "${deps[@]}"; do
        command -v "$cmd" >/dev/null 2>&1 || {
            log "ERROR" "$cmd required but not installed."
            exit 1
        }
    done
}

main() {
    check_dependencies
    log "INFO" "Running rc-docs-fix.sh."

# rc-docs-fix.sh — grep & fix your docs with automatic backup
# Usage: ./rc-docs-fix.sh --pattern PATTERN --replace REPLACEMENT [--dry-run]

print_usage() {
  cat <<EOF
Usage: $0 --pattern PATTERN --replace REPLACEMENT [--dry-run]

Options:
  --pattern    Regex or literal string to search for
  --replace    Replacement string (must be quoted if contains spaces)
  --dry-run    Show what would change without writing files
  --backup-only  Only archive the docs without making any replacements
  --search-only  Perform search and log matches without applying replacements
EOF
}

# parse args
DRY_RUN=false
BACKUP_ONLY=false
SEARCH_ONLY=false
PATTERN=
REPLACEMENT=

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pattern)    PATTERN="$2"; shift 2;;
    --replace)    REPLACEMENT="$2"; shift 2;;
    --dry-run)    DRY_RUN=true; shift;;
    --backup-only) BACKUP_ONLY=true; shift;;
    --search-only) SEARCH_ONLY=true; shift;;
    -h|--help)    print_usage; exit;;
    *) echo "Unknown arg: $1"; print_usage; exit 1;;
  esac
done

if [[ -z "$PATTERN" || -z "$REPLACEMENT" ]]; then
  echo "Error: --pattern and --replace are required"
  print_usage
  exit 1
fi

# Ensure docs/ exists, else skip or simulate for test safety
if [[ ! -d "docs" ]]; then
  log "WARN" "docs/ folder not found. Skipping operations."
  if $DRY_RUN || $SEARCH_ONLY || $BACKUP_ONLY; then
    echo "Simulated: docs/ folder not present; no operations performed."
    exit 0
  else
    exit 0
  fi
fi

TIMESTAMP=$(date +%Y%m%dT%H%M%S)
BACKUP="docs_backup_$TIMESTAMP.tar.gz"

echo "📦 Archiving docs/ → $BACKUP"
tar czf "$BACKUP" docs/
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Archived docs to $BACKUP" >> "$LOG_FILE"

if $BACKUP_ONLY; then
  echo "✅ Backup-only mode: archive created at $BACKUP. Exiting."
  exit 0
fi

if $SEARCH_ONLY; then
  echo "🔍 Search-only mode: finding '$PATTERN'..."
  grep -RIn --exclude-dir=".git" "$PATTERN" docs/ | tee -a "$LOG_FILE"
  echo "✅ Search logged to $LOG_FILE"
  exit 0
fi

echo "🔍 Searching for “$PATTERN”…"
grep -RIn --exclude-dir=".git" "$PATTERN" docs/ || echo "(no matches)"

if $DRY_RUN; then
  echo "⚠️ Dry run: showing diffs only"
  MATCHES=$(grep -RIl --exclude-dir=".git" "$PATTERN" docs/)
  if [[ -z "$MATCHES" ]]; then
    echo "(no matches)"
  else
    echo "$MATCHES" | xargs sed -n "s/$PATTERN/$REPLACEMENT/gp"
  fi
else
  echo "🔧 Applying replacement: $PATTERN → $REPLACEMENT"
  grep -RIl --exclude-dir=".git" "$PATTERN" docs/ \
    | xargs sed -i.bak "s/$PATTERN/$REPLACEMENT/g"
  echo "✅ Replacement complete. Backup of each file saved as *.bak"
fi

if $DRY_RUN; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Dry-run replacement for pattern '$PATTERN' to '$REPLACEMENT'" >> "$LOG_FILE"
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Applied replacement: '$PATTERN' → '$REPLACEMENT'" >> "$LOG_FILE"
fi

echo "🎉 Done! Review your docs or remove *.bak files when you’re satisfied."
    log "INFO" "rc-docs-fix.sh completed successfully."
}

main "$@"
