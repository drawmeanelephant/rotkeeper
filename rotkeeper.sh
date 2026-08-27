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
#  Script  : rotkeeper.sh
#  Purpose : CLI dispatcher for aligned single framework release structures
#  Version : 0.5.1
# ============================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BONES="$SCRIPT_DIR/bones/scripts"

VERSION=""
if [[ -n "${ROTKEEPER_VERSION:-}" ]]; then
  VERSION="$ROTKEEPER_VERSION"
elif [[ -f "$SCRIPT_DIR/bones/config/version" ]]; then
  VERSION="$(tr -d '[:space:]' < "$SCRIPT_DIR/bones/config/version")"
  VERSION="${VERSION#v}"
fi
[[ -n "$VERSION" ]] || VERSION="unknown"

on_err() {
  local status=$?
  printf 'ERROR: status=%s file=%s line=%s function=%s command=%q\n' \
    "$status" "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}" \
    "${BASH_LINENO[0]:-$LINENO}" "${FUNCNAME[1]:-MAIN}" \
    "$BASH_COMMAND" >&2
  return "$status"
}
trap 'on_err' ERR

command="${1:-}"
if [[ $# -gt 0 ]]; then shift; fi

show_help() {
  cat <<HELP_EOF
rotkeeper.sh — Rotkeeper CLI v$VERSION

Usage:
  rotkeeper.sh <command> [options]

Commands:
  init        Initialize environment
  new <file>  Scaffold a new markdown file
  render      Convert markdown into HTML tombs
  pack        Archive rendered HTML into a versioned tarball
  preflight   Report Oliver renderer availability and compatibility
  release     Package the project into a single canonical framework zip file
  bump        Record a microrelease update and synchronize version markers
  test        Run the integration test harness matrix (alias: smoke)
  scan        Verify manifest entries against actual files
  assets      Generate asset manifest
  autopsy     Catalog script help and output behavior
  glue        Auto-generate navigation glue for unindexed content directories
  links       Audit links and local assets in rendered HTML
  a11y        Audit theme accessibility: contrast, focus states, legibility
  showcase    Generate showcase content for every HTML template
  dip         Audit documentation coverage via DIP
  book        Generate aggregated documentation book targets
  status      Display environment health status reports

Examples:
  bash rotkeeper.sh init --full          Initialize sample env, assets, render, scan
  bash rotkeeper.sh render               Render content tombs into HTML
  bash rotkeeper.sh pack                 Archive rendered HTML into a tomb
  bash rotkeeper.sh release 0.8.0        Package the canonical distribution

Exit codes:
  0    Success
  1    Unknown command or ritual failure
HELP_EOF
}

case "$command" in
  --version|-v)
    echo "rotkeeper v$VERSION"
    ;;
  --help|-h|help|"")
    show_help
    ;;
  init)
    bash "$BONES/rc-init.sh" "$@"
    ;;
  new)
    bash "$BONES/rc-new.sh" "$@"
    ;;
  render)
    bash "$BONES/rc-render.sh" "$@"
    ;;
  pack)
    bash "$BONES/rc-pack.sh" "$@"
    ;;
  preflight)
    bash "$BONES/rc-preflight.sh" "$@"
    ;;
  release)
    rel_ver="$VERSION"
    if [[ $# -gt 0 && "$1" != -* ]]; then
       rel_ver="$1"
       shift
    fi
    if [[ $# -gt 0 && ( "$1" == "--help" || "$1" == "-h" || "$1" == "--version" || "$1" == "-v" ) ]]; then
      bash "$BONES/rc-release.sh" "$@"
    else
      echo "Creating standardized single canonical framework distribution..."
      bash "$BONES/rc-release.sh" "$rel_ver" "$@"
    fi
    ;;
  bump)
    if [[ "${1:-}" == "--version" || "${1:-}" == "-v" ]]; then
      echo "rc-bump.sh v$VERSION"
    else
      bash "$BONES/rc-bump.sh" "$@"
    fi
    ;;
  scan)
    bash "$BONES/rc-scan.sh" "$@"
    ;;
  assets)
    bash "$BONES/rc-assets.sh" "$@"
    ;;
  autopsy)
    bash "$BONES/rc-autopsy.sh" "$@"
    ;;
  glue)
    bash "$BONES/rc-glue.sh" "$@"
    ;;
  links)
    bash "$BONES/rc-links.sh" "$@"
    ;;
  a11y)
    bash "$BONES/rc-a11y.sh" "$@"
    ;;
  showcase)
    bash "$BONES/rc-showcase.sh" "$@"
    ;;
  dip)
    bash "$BONES/rc-dip.sh" "$@"
    ;;
  book)
    bash "$BONES/rc-book.sh" "$@"
    ;;
  cleanup)
    echo "ERROR: The 'cleanup' command has been permanently removed. Rotkeeper no longer owns aggressive deletion workflows."
    exit 1
    ;;
  ingest)
    echo "ERROR: The 'ingest' command has been permanently removed. Rotkeeper no longer owns message ingestion workflows."
    exit 1
    ;;
  sync-inbox)
    echo "ERROR: The 'sync-inbox' command has been permanently removed. Rotkeeper no longer owns message ingestion workflows."
    exit 1
    ;;
  reseed)
    echo "ERROR: The 'reseed' command has been permanently removed. Rotkeeper initialization is now non-destructive and layout-driven."
    exit 1
    ;;
  status)
    bash "$BONES/rc-status.sh" "$@"
    ;;
  test|smoke)
    bash "$BONES/rc-test.sh" "$@"
    ;;
  *)
    printf 'ERROR: Unknown command: %s\n' "$command" >&2
    printf '       Run: bash rotkeeper.sh help  (lists all commands)\n' >&2
    exit 1
    ;;
esac
