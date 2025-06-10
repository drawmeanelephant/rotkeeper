#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-cleanup-bones.sh
# Purpose: Backup and prune unneeded directories and templates from bones/
# Version: 0.2.5
# Updated: 2025-06-03
# -----------------------------------------

# Source shared Rotkeeper helpers
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"

show_help() {
  cat << EOF
rc-cleanup-bones.sh — Backup and prune unneeded directories and templates from bones/ (v0.2.1)

Usage: rc-cleanup-bones.sh [options]

Options:
  --help, -h       Show this help message and exit
  --dry-run        Preview actions without executing
  --verbose        Show detailed logs
  --days N         Set retention window in days (default: 30)
EOF
  exit 0
}

set -euo pipefail
IFS=$'\n\t'

# Initialize flags
HELP=false
DRY_RUN=false
VERBOSE=false
RETAIN_DAYS=30

# Parse common flags and handle help
parse_flags "$@"
if [[ "$HELP" == true ]]; then
  show_help
fi

log "DEBUG" "HELP=$HELP, DRY_RUN=$DRY_RUN, VERBOSE=$VERBOSE, RETAIN_DAYS=$RETAIN_DAYS"

main() {
  check_dependencies

  log "INFO" "Running rc-cleanup-bones.sh."

  BACKUP_DIR="bones/backups"
  TIMESTAMP=$(date +%Y-%m-%d_%H%M)
  BACKUP_NAME="bones-backup-$TIMESTAMP.tar.gz"
  BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

  if [[ "$DRY_RUN" == true ]]; then
    log "INFO" "Dry run mode: simulating backup and cleanup actions"
    echo "Would create backup: $BACKUP_PATH"
    echo "Would prune backups older than $RETAIN_DAYS days from $BACKUP_DIR"
    echo "Would prune logs older than $RETAIN_DAYS days from bones/logs"
    echo "Would delete contents of bones/ except backups/ and logs/"
    find bones -maxdepth 1 -mindepth 1 ! -name backups ! -name logs -print | sed 's/^/  - /'
    log "INFO" "🧪 Dry run complete — no changes made."
    log "INFO" "🪦 Ritual concluded at $(date +'%Y-%m-%d %H:%M') — bones remain undisturbed."
    return 0
  fi

  log "INFO" "Backing up bones/ to $BACKUP_PATH"
  run mkdir -p "$BACKUP_DIR"
  run tar --exclude="$BACKUP_DIR" -czf "$BACKUP_PATH" bones/

  if [[ ! -s "$BACKUP_PATH" ]]; then
    log "ERROR" "Backup tarball appears to be missing or empty: $BACKUP_NAME"
    exit 1
  fi

  BACKUP_SIZE=$(du -h "$BACKUP_PATH" | cut -f1)
  log "INFO" "Backup created successfully: $BACKUP_NAME ($BACKUP_SIZE)"

  log "INFO" "Pruning backups older than $RETAIN_DAYS days"
  run find "$BACKUP_DIR" -type f -mtime +"$RETAIN_DAYS" -print -delete

  LOG_DIR="bones/logs"
  log "INFO" "Pruning logs older than $RETAIN_DAYS days in $LOG_DIR"
  run find "$LOG_DIR" -type f -mtime +"$RETAIN_DAYS" -print -delete

  log "INFO" "Removing non-essential files and folders in bones/"
  find bones -maxdepth 1 -mindepth 1 ! -name backups ! -name logs -print0 | xargs -0 rm -rf

  log "INFO" "✅ Cleanup complete: bones/ pruned, logs trimmed, backup created: $BACKUP_NAME ($BACKUP_SIZE)"
  log "INFO" "🪦 Ritual concluded at $(date +'%Y-%m-%d %H:%M') — decay logged and archived."
}

main "$@"
