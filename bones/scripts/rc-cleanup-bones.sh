#!/usr/bin/env bash
# ============================================================
#   ██████╗██╗     ███████╗ █████╗ ███╗   ██╗██╗   ██╗██████╗
#  ██╔════╝██║     ██╔════╝██╔══██╗████╗  ██║██║   ██║██╔══██╗
#  ██║     ██║     █████╗  ███████║██╔██╗ ██║██║   ██║██████╔╝
#  ██║     ██║     ██╔══╝  ██╔══██║██║╚██╗██║██║   ██║██╔═══╝
#  ╚██████╗███████╗███████╗██║  ██║██║ ╚████║╚██████╔╝██║
#   ╚═════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-cleanup-bones.sh
#  Purpose : Backup and prune unneeded directories and templates from bones
#  Version : 0.3.1.4
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

show_help() {
  cat <<EOF
rc-cleanup-bones.sh — Backup and prune unneeded directories and templates from bones
v0.3.1.4

Usage: rc-cleanup-bones.sh [options]

Options:
  --version, -v    Show script version and quit
  --help, -h     Show this help message and exit
  --dry-run      Preview actions without executing
  --confirm-prune Execute pruning and deletion of ephemeral data
  --verbose      Show detailed logs
  --days N       Set retention window in days (default: 30)
EOF
  exit 0
}

source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
VERSION="${ROTKEEPER_VERSION:-0.3.1.4}"

rk_init_script "rc-cleanup-bones" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR



set -euo pipefail
IFS=$'\n\t'



RETAINDAYS=30
CONFIRM_PRUNE=false

parseflags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --version|-v) echo "$(basename "$0") v${VERSION:-unknown}"; exit 0 ;;
      --help|-h)
        show_help
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --confirm-prune)
        CONFIRM_PRUNE=true
        shift
        ;;
      --verbose)
        VERBOSE=true
        shift
        ;;
      --days)
        RETAINDAYS="$2"
        shift 2
        ;;
      *)
        break
        ;;
    esac
  done
}

checkdependencies() {
  require_bins tar find rm
}

parseflags "$@"

log "DEBUG" "DRY_RUN=$DRY_RUN, VERBOSE=$VERBOSE, RETAINDAYS=$RETAINDAYS"

main() {
  checkdependencies
  log INFO "Running rc-cleanup-bones.sh."

  BACKUPDIR="bones/backups"
  TIMESTAMP=$(date +%Y-%m-%d_%H%M)
  BACKUPNAME="bones-backup-${TIMESTAMP}.tar.gz"
  BACKUPPATH="${BACKUPDIR}/${BACKUPNAME}"

  if [[ "$DRY_RUN" == true ]] || [[ "$CONFIRM_PRUNE" == false ]]; then
    log INFO "Dry run / preview mode: simulating backup and cleanup actions"
    echo "Would create backup: $BACKUPPATH"
    echo "Would prune backups older than $RETAINDAYS days from $BACKUPDIR"
    echo "Would prune logs older than $RETAINDAYS days from bones/logs"
    echo "Would explicitly delete the following ephemeral directories under $ROOT_DIR/bones/:"
    for d in "tmp" "archive" "reports" "book-reports" "ingested"; do
      echo "  - $ROOT_DIR/bones/$d"
    done
    if [[ "$CONFIRM_PRUNE" == false && "$DRY_RUN" == false ]]; then
      log INFO "Run with --confirm-prune to execute actual deletion."
    else
      log INFO "Dry run complete: no changes made."
    fi
    log INFO "Ritual concluded at $(date +%Y-%m-%d\ %H:%M) — bones remain undisturbed."
    return 0
  fi

  log INFO "Starting cleanup sequence for $RETAINDAYS days retention."

  if [ ! -d "$BACKUPDIR" ]; then
      log WARN "Backup directory $BACKUPDIR does not exist. Creating it."
      run mkdir -p "$BACKUPDIR"
  fi

  log INFO "Backing up bones to $BACKUPPATH"

  # FIX: use -C "$ROOT_DIR" so archive paths are relative (bones/...) not absolute
  run tar --exclude="$BACKUPDIR" -czf "$BACKUPPATH" -C "$ROOT_DIR" bones

  if [[ ! -s "$BACKUPPATH" ]]; then
    log ERROR "Backup tarball appears to be missing or empty: $BACKUPNAME"
    exit 1
  fi

  BACKUPSIZE=$(du -h "$BACKUPPATH" | cut -f1)
  log INFO "Backup created successfully: $BACKUPNAME ($BACKUPSIZE)"

  log INFO "Pruning backups older than $RETAINDAYS days in $BACKUPDIR"
  run find "$BACKUPDIR" -type f -name "bones-backup-*.tar.gz" -mtime +"$RETAINDAYS" -print -delete

  LOGDIR="bones/logs"
  log INFO "Pruning logs older than $RETAINDAYS days in $LOGDIR"
  run find "$LOGDIR" -type f -mtime +"$RETAINDAYS" -print -delete

  log INFO "Removing non-essential files and folders in bones/"
  for d in "tmp" "archive" "reports" "book-reports" "ingested"; do
    target="$ROOT_DIR/bones/$d"
    if [[ -d "$target" ]]; then
      run rm -rf "$target"
    fi
  done

  log INFO "Cleanup complete: bones pruned, logs trimmed, backup created: $BACKUPNAME ($BACKUPSIZE)"
  log INFO "Ritual concluded at $(date +%Y-%m-%d\ %H:%M) — decay logged and archived."
}

main
