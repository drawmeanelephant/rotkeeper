#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# ============================================================
#  Project : Rotkeeper
#  Script  : bones/scripts/rc-preflight.sh
#  Purpose : Report Oliver renderer availability and compatibility
#  Version : 0.5.1
#  Updated : 2026-08-12
# ============================================================
# Env assumptions: reads DRY_RUN, OLIVER_BIN, RK_OLIVER_BIN, SCRIPT_DIR, TMP_DIR, VERSION (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.
# CWD assumptions: No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.
# Input/Output contracts: CLI args and env vars in; files and stdout/stderr out; respects --dry-run (no writes) and --verbose.
# @HELP
# rc-preflight.sh — Report Oliver renderer availability (v{VERSION})
#
# Usage:
#   rotkeeper.sh preflight [options]
#
# Description:
#   Reports whether the Oliver renderer is discoverable, executable, and
#   actually runnable (a live smoke render through the real CLI; see
#   home/content/docs/oliver-contract.md). This is the single renderer
#   health check; render routes through the same check.
#
# Options:
#   --verbose        Show detailed findings
#   --dry-run        Report the check without invoking the Oliver binary
#   --help, -h       Show this help message and exit
#   --version, -v    Show script version and quit
#
# Examples:
#   bash rotkeeper.sh preflight              Verify rendering is ready
#   bash rotkeeper.sh preflight --verbose    Show discovery details
#
# Exit codes:
#   0    Rendering ready
#   1    Renderer missing or unusable (with one actionable setup message)
# @END-HELP

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
rk_init_script "rc-preflight" "$@"
require_env_vars TMP_DIR

# ---
# main: Execute the Oliver preflight check and report pass/fail.
# Inputs: none (reads DRY_RUN, TMP_DIR)
# Outputs: Exits 0 on pass, 1 on fail; prints MARKER summary
# Env: Reads DRY_RUN, OLIVER_BIN, RK_OLIVER_BIN, TMP_DIR (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
main() {
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log "DRY-RUN" "Preflight would report Oliver renderer availability and compatibility."
    log "MARKER" "Oliver preflight: DRY-RUN (checks skipped). Set RK_OLIVER_BIN or PATH, then run without --dry-run."
    exit 0
  fi

  if rk_oliver_preflight; then
    log "MARKER" "Oliver preflight: PASS ($OLIVER_BIN)."
    exit 0
  fi
  log "MARKER" "Oliver preflight: FAIL."
  exit 1
}

main "$@"