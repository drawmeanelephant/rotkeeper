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

# Parse common flags and handle help
parse_flags "$@"
if [[ "$HELP" == true ]]; then
  show_help
fi

main() {
  # Initialize flags
  HELP=false
  DRY_RUN=false
  VERBOSE=false
  RETAIN_DAYS=30

  # Parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        HELP=true
        shift
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --verbose)
        VERBOSE=true
        shift
        ;;
      --days)
        RETAIN_DAYS="$2"
        shift 2
        ;;
      *)
        break
        ;;
    esac
  done

  # Show help if requested
  if [[ "$HELP" == true ]]; then
    show_help
  fi

  require_bins tar find rm
  log "INFO" "Running rc-cleanup-bones.sh."

  BACKUP_DIR="bones/backups"
  TIMESTAMP=$(date +%Y-%m-%d_%H%M)
  BACKUP_NAME="bones-backup-$TIMESTAMP.tar.gz"

  log "INFO" "Backing up bones/ to $BACKUP_DIR/$BACKUP_NAME"
  run mkdir -p "$BACKUP_DIR"
  run tar --exclude="$BACKUP_DIR" -czf "$BACKUP_DIR/$BACKUP_NAME" bones/

  if [[ "$DRY_RUN" == true ]]; then
    log "INFO" "Dry run enabled — skipping backup verification and deletion steps."
    find bones -maxdepth 1 -mindepth 1 \( -name "backups" -o -name "logs" \) -prune -o -print | sed 's/^/  - /'
    return 0
  fi

  BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"
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

  find bones -maxdepth 1 -mindepth 1 \( -name "backups" -o -name "logs" \) -prune -o -print0 | xargs -0 rm -rf

  log "INFO" "✅ Cleanup complete."
}

main "$@"
