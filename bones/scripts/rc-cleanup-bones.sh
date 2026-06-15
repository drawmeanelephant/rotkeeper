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
#  Script  : rc-cleanup-bones.sh
#  Purpose : Backup and prune unneeded directories and templates from bones
#  Version : 0.3.0.12
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"

showhelp() {
  cat <<EOF
rc-cleanup-bones.sh — Backup and prune unneeded directories and templates from bones
v0.3.0.12

Usage: rc-cleanup-bones.sh [options]

Options:
  --help, -h     Show this help message and exit
  --dry-run      Preview actions without executing
  --verbose      Show detailed logs
  --days N       Set retention window in days (default: 30)
EOF
  exit 0
}

set -euo pipefail
IFS=$'\n\t'

HELP=false
DRYRUN=false
VERBOSE=false
RETAINDAYS=30

parseflags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        HELP=true
        shift
        ;;
      --dry-run)
        DRYRUN=true
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

if $HELP; then showhelp; fi

log DEBUG "HELP=$HELP, DRYRUN=$DRYRUN, VERBOSE=$VERBOSE, RETAINDAYS=$RETAINDAYS"

main() {
  checkdependencies
  log INFO "Running rc-cleanup-bones.sh."

  BACKUPDIR="bones/backups"
  TIMESTAMP=$(date +%Y-%m-d_%H%M)
  BACKUPNAME="bones-backup-${TIMESTAMP}.tar.gz"
  BACKUPPATH="${BACKUPDIR}/${BACKUPNAME}"

  if $DRYRUN; then
    log INFO "Dry run mode: simulating backup and cleanup actions"
    echo "Would create backup: $BACKUPPATH"
    echo "Would prune backups older than $RETAINDAYS days from $BACKUPDIR"
    echo "Would prune logs older than $RETAINDAYS days from bones/logs"
    echo "Would delete contents of bones/ except backups and logs:"
    find bones -maxdepth 1 -mindepth 1 ! -name backups ! -name logs -print | sed 's/^/  - /'
    log INFO "Dry run complete: no changes made."
    log INFO "Ritual concluded at $(date +%Y-%m-d\ %H:%M) — bones remain undisturbed."
    return 0
  fi

  log INFO "Backing up bones to $BACKUPPATH"
  run mkdir -p "$BACKUPDIR"

  # FIX: use -C "$ROOTDIR" so archive paths are relative (bones/...) not absolute
  run tar --exclude="$BACKUPDIR" -czf "$BACKUPPATH" -C "$ROOTDIR" bones

  if [[ ! -s "$BACKUPPATH" ]]; then
    log ERROR "Backup tarball appears to be missing or empty: $BACKUPNAME"
    exit 1
  fi

  BACKUPSIZE=$(du -h "$BACKUPPATH" | cut -f1)
  log INFO "Backup created successfully: $BACKUPNAME ($BACKUPSIZE)"

  log INFO "Pruning backups older than $RETAINDAYS days"
  run find "$BACKUPDIR" -type f -mtime +"$RETAINDAYS" -print -delete

  LOGDIR="bones/logs"
  log INFO "Pruning logs older than $RETAINDAYS days in $LOGDIR"
  run find "$LOGDIR" -type f -mtime +"$RETAINDAYS" -print -delete

  log INFO "Removing non-essential files and folders in bones/"
  find bones -maxdepth 1 -mindepth 1 ! -name backups ! -name logs -print0 \
    | xargs -0 rm -rf

  log INFO "Cleanup complete: bones pruned, logs trimmed, backup created: $BACKUPNAME ($BACKUPSIZE)"
  log INFO "Ritual concluded at $(date +%Y-%m-d\ %H:%M) — decay logged and archived."
}

main
