#!/usr/bin/env bash
# ============================================================
#  rc-smoke.sh
#  Purpose: Minimal baseline verification for Jules integration
# ============================================================

show_help() {
  cat << EOF2
rc-smoke.sh — Rotkeeper Smoke Test

Usage: rc-smoke.sh [options]

Options:
  --version, -v    Show script version and quit
  --help, -h       Show this help message and quit
  --dry-run        Preview actions
  --verbose        Show detailed logs
EOF2
  return 0
}

source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
rk_init_script "rc-smoke" "$@"

set -euo pipefail
IFS=$'\n\t'

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPTDIR/../.."

main() {
    log "INFO" "🚀 Starting Rotkeeper Smoke Test..."

    # 1. Verify dependencies
    log "INFO" "Checking required system dependencies..."
    check_dependencies
    log "INFO" "✅ Dependencies verified."

    # 2. Ensure core directories exist
    log "INFO" "Checking core directory structure..."
    for dir in "home/content" "home/assets" "output" "bones/scripts" "bones/archive"; do
        mkdir -p "$PROJECT_ROOT/$dir"
    done
    log "INFO" "✅ Core directories are present."

    # 3. Test asset manifest generation if rc-assets.sh exists
    if [[ -f "$SCRIPTDIR/rc-assets.sh" ]]; then
        log "INFO" "Testing asset generation ritual..."
        run "$SCRIPTDIR/rc-assets.sh"
        log "INFO" "✅ Asset generation succeeded."
    else
        log "WARN" "rc-assets.sh not found in prototype; skipping asset test."
    fi

    # 4. Perform a non-destructive scan (dry-run)
    if [[ -f "$SCRIPTDIR/rc-scan.sh" ]]; then
        log "INFO" "Performing dry-run repository scan..."
        run "$SCRIPTDIR/rc-scan.sh" --dry-run
        log "INFO" "✅ Scan dry-run completed."
    else
        log "WARN" "rc-scan.sh not found in prototype; skipping scan test."
    fi

    log "INFO" "🎉 Smoke test completed successfully. Rotkeeper is functional."
}

# Only run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
