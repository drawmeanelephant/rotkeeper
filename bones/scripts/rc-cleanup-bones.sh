#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-cleanup-bones.sh
# Purpose: Backup and prune unneeded directories and templates from bones/
# Version: 0.2.1
# Updated: 2025-05-29
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

# Parse common flags and handle help
parse_flags "$@"
if [[ "$HELP" == true ]]; then
  show_help
fi

main() {
  check_deps tar find rm
  log "INFO" "Running rc-cleanup-bones.sh."

  # Retention window (days)
  RETAIN_DAYS=30
  # Allow override: --days N
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --days) RETAIN_DAYS="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  BACKUP_DIR="bones/backups"
  TIMESTAMP=$(date +%Y-%m-%d_%H%M)
  BACKUP_NAME="bones-backup-$TIMESTAMP.tar.gz"

  log "INFO" "Backing up bones/ to $BACKUP_DIR/$BACKUP_NAME"
  run "mkdir -p \"$BACKUP_DIR\""
  run "tar --exclude=\"$BACKUP_DIR\" -czf \"$BACKUP_DIR/$BACKUP_NAME\" bones/"

  log "INFO" "Pruning backups older than $RETAIN_DAYS days"
  run "find \"$BACKUP_DIR\" -type f -mtime +$RETAIN_DAYS -print -delete"

  LOG_DIR="bones/logs"
  log "INFO" "Pruning logs older than $RETAIN_DAYS days in $LOG_DIR"
  run "find \"$LOG_DIR\" -type f -mtime +$RETAIN_DAYS -print -delete"

  log "INFO" "✅ Cleanup complete."
}

main "$@"
