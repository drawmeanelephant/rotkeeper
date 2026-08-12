#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# ============================================================
#  Project : Rotkeeper
#  Script  : bones/scripts/rc-preflight.sh
#  Purpose : Report Apex renderer availability and compatibility
#  Version : 0.5.1
#  Updated : 2026-08-12
# ============================================================
# shellcheck disable=SC2329 # invoked indirectly by rk_init_script's help handling
show_help() {
  cat << EOF
rc-preflight.sh — Report Apex renderer availability (v$VERSION)

Usage: rc-preflight.sh

Reports whether the Apex renderer is discoverable, executable, within the
supported 1.1.x version range (see home/content/docs/apex-contract.md), and
actually runnable. Exits 0 when rendering is ready; exits 1 with one
actionable setup message when it is not.

Options:
  --version, -v    Show script version and quit
  --help, -h       Show this help message and exit
  --verbose        Show detailed findings
  --dry-run        Report the check without invoking the Apex binary
EOF
  exit 0
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
rk_init_script "rc-preflight" "$@"
require_env_vars TMP_DIR

main() {
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log "DRY-RUN" "Preflight would report Apex renderer availability and compatibility."
    log "MARKER" "Apex preflight: DRY-RUN (checks skipped). Set RK_APEX_BIN or PATH, then run without --dry-run."
    exit 0
  fi

  if rk_apex_preflight; then
    log "MARKER" "Apex preflight: PASS ($APEX_BIN)."
    exit 0
  fi
  log "MARKER" "Apex preflight: FAIL."
  exit 1
}

main "$@"