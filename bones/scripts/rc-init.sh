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
#  Version : 0.3.0.20
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================


# Source shared Rotkeeper helpers
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
rk_init_script "rc-init" "$@"

set -euo pipefail
IFS=$'\n\t'


show_help() {
  cat << EOF
rc-init.sh — Initialize environment

Usage: rc-init.sh [options]

Options:
  --help, -h       Show this help message and exit
  --dry-run        Preview actions
  --verbose        Show detailed logs
EOF
  exit 0
}


# Resolve script directory for sibling commands
SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESEED_CMD="$SCRIPTDIR/rc-reseed.sh"

# Make all rc-*.sh and rc-utils.bats scripts executable
log "INFO" "🔐 Blessing scripts with +x permissions..."
find "$SCRIPTDIR" -type f \( -name "rc-*.sh" -o -name "rc-utils.bats" \) -exec chmod +x {} \;

main() {
    # Verify required tools
    check_dependencies
    $VERBOSE && log "INFO" "Dependencies verified."

    if [[ ! -d "$SCRIPTDIR/../templates" ]]; then
      log "ERROR" "bones/templates directory is missing. Cannot proceed."
      exit 1
    fi

    log "INFO" "🔄 Starting initialization..."
    run "$RESEED_CMD" --force
    
    # Generate a heavily commented test-file.md as an example for blind users
    mkdir -p "$SCRIPTDIR/../../home/content"
    cat << 'EOF_HELLO' > "$SCRIPTDIR/../../home/content/test-file.md"
---
title: "Test File"
slug: test-file
template: rotkeeper-blog.html
# Valid templates can be found by running: ./rotkeeper.sh templates
description: "A simple starter page to demonstrate YAML frontmatter in Rotkeeper."
---

# Test File!

This is a demonstration page created during initialization. 
It shows you exactly how to format your Markdown files with the required YAML frontmatter at the top.

To render this page into HTML, run:
`./rotkeeper.sh render`
EOF_HELLO
    log "INFO" "📄 Generated starter content at home/content/test-file.md"

    run "$SCRIPTDIR/rc-assets.sh"
    run "$SCRIPTDIR/rc-render.sh" --verbose
    run "$SCRIPTDIR/rc-scan.sh"
    log "INFO" "✅ Initialization complete."
    log "INFO" "Next: run ./rotkeeper.sh new my-first-page"
}

main "$@"
