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
#  Script  : rc-init.sh
#  Purpose : Initialize environment: reseed, bless scripts, render, and validate
#  Version : 0.3.0.16
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================


# Source shared Rotkeeper helpers
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"

set -euo pipefail
IFS=$'\n\t'


# Normalize environment variable overrides before the flag parser
: "${DRY_RUN:=${RK_DRY:-false}}"
: "${VERBOSE:=${RK_VERBOSE:-false}}"
HELP=false

# Parse common flags
parse_flags "$@"
if [[ "$HELP" == true ]]; then
  show_help
fi

# Setup logging (must be after rc-utils is sourced and flags are parsed)
LOGDIR="bones/logs"
mkdir -p "$LOGDIR"
LOG_FILE="$LOGDIR/rc-init.log"
exec > >(tee -a "$LOG_FILE") 2>&1


# Resolve script directory for sibling commands
SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESEED_CMD="$SCRIPTDIR/rc-reseed.sh"

# Make all rc-*.sh and rc-utils.bats scripts executable
log "INFO" "🔐 Blessing scripts with +x permissions..."
find "$SCRIPTDIR" -type f \( -name "rc-*.sh" -o -name "rc-utils.bats" \) -exec chmod +x {} \;

cleanup() {
    log "INFO" "Cleaning up after rc-init.sh."
    # Add cleanup commands here
}
trap cleanup EXIT INT TERM

# Trap error handler for unhandled errors (v0.2.4-dev standard)
trap_err() {
  log "ERROR" "Unhandled error in ${BASH_SOURCE[1]} at line $1"
  exit 1
}
trap 'trap_err $LINENO' ERR

main() {
    # Verify required tools
    check_dependencies
    $VERBOSE && log "INFO" "Dependencies verified."

    log "INFO" "🔄 Starting initialization..."
    run "$RESEED_CMD" --force
    
    # Generate a heavily commented hello-world.md as an example for blind users
    mkdir -p "$SCRIPTDIR/../home/content"
    cat << 'EOF_HELLO' > "$SCRIPTDIR/../home/content/hello-world.md"
---
title: "Hello World"
slug: hello-world
template: rotkeeper-blog.html
# Valid templates can be found by running: ./rotkeeper.sh templates
description: "A simple starter page to demonstrate YAML frontmatter in Rotkeeper."
---

# Hello World!

This is a demonstration page created during initialization. 
It shows you exactly how to format your Markdown files with the required YAML frontmatter at the top.

To render this page into HTML, run:
`./rotkeeper.sh render`
EOF_HELLO
    log "INFO" "📄 Generated starter content at home/content/hello-world.md"

    run "$SCRIPTDIR/rc-assets.sh"
    run "$SCRIPTDIR/rc-render.sh" --verbose
    run "$SCRIPTDIR/rc-scan.sh"
    log "INFO" "✅ Initialization complete."
}

main "$@"
