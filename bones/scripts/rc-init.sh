#!/usr/bin/env bash
# ============================================================
#  ██╗███╗   ██╗██╗████████╗
#  ██║████╗  ██║██║╚══██╔══╝
#  ██║██╔██╗ ██║██║   ██║
#  ██║██║╚██╗██║██║   ██║
#  ██║██║ ╚████║██║   ██║
#  ╚═╝╚═╝  ╚═══╝╚═╝   ╚═╝
# ============================================================
#  Project : Rotkeeper (Jules Compat Prototype)
#  Script  : rc-init.sh
#  Purpose : Minimal, non-destructive environment initialization
# ============================================================

show_help() {
  cat << EOF2
rc-init.sh — Initialize environment

Usage: rc-init.sh [options]

Options:
  --version, -v    Show script version and quit
  --help, -h       Show this help message and exit
  --dry-run        Preview actions
  --verbose        Show detailed logs

Initialization Flags:
  --with-sample    Generate starter test-file.md
  --with-assets    Run assets generation
  --with-render    Run the render ritual
  --full           Perform full reseed, sample, assets, render, and scan
EOF2
  return 0
}

# Source shared Rotkeeper helpers
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
rk_init_script "rc-init" "$@"

set -euo pipefail
IFS=$'\n\t'

# shellcheck disable=SC2034
VERSION="0.3.1.4"

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESEED_CMD="$SCRIPTDIR/rc-reseed.sh"
PROJECT_ROOT="$SCRIPTDIR/../.."

# Flags
WITH_SAMPLE=false
WITH_ASSETS=false
WITH_RENDER=false
FULL=false

# Parse custom flags
for arg in "$@"; do
    case "$arg" in
        --with-sample) WITH_SAMPLE=true ;;
        --with-assets) WITH_ASSETS=true ;;
        --with-render) WITH_RENDER=true ;;
        --full)        FULL=true ;;
    esac
done

if [[ "$FULL" == true ]]; then
    WITH_SAMPLE=true
    WITH_ASSETS=true
    WITH_RENDER=true
fi

# Make all rc-*.sh and rc-utils.bats scripts executable
log "INFO" "🔐 Blessing scripts with +x permissions..."
find "$SCRIPTDIR" -type f \( -name "rc-*.sh" -o -name "rc-*.bats" \) -exec chmod +x {} \;

main() {
    # Verify required tools
    check_dependencies
    $VERBOSE && log "INFO" "Dependencies verified."

    if [[ ! -d "$PROJECT_ROOT/bones/templates" ]]; then
        # This check might fail in pure sandbox without templates, but keeping the logic
        log "WARN" "bones/templates directory is missing (ignored in prototype if not rendering)."
    fi

    log "INFO" "🔄 Starting initialization (Minimal mode by default)..."

    if [[ "$FULL" == true ]]; then
        if [[ -f "$RESEED_CMD" ]]; then
            run "$RESEED_CMD" --force
        else
            log "WARN" "rc-reseed.sh not found in prototype, skipping reseed."
        fi
    fi

    # Create core directories non-destructively
    mkdir -p "$PROJECT_ROOT/home/content"
    mkdir -p "$PROJECT_ROOT/output"
    mkdir -p "$PROJECT_ROOT/bones/config"
    log "INFO" "✅ Verified core directories exist."

    if [[ "$WITH_SAMPLE" == true ]]; then
        cat << 'EOF_HELLO' > "$PROJECT_ROOT/home/content/test-file.md"
---
title: "Test File"
slug: test-file
template: rotkeeper-blog.html
description: "A simple starter page to demonstrate YAML frontmatter in Rotkeeper."
---

# Test File!

This is a demonstration page created during initialization.
EOF_HELLO
        log "INFO" "📄 Generated starter content at home/content/test-file.md"
    fi

    if [[ "$WITH_ASSETS" == true ]]; then
        if [[ -f "$SCRIPTDIR/rc-assets.sh" ]]; then
            run "$SCRIPTDIR/rc-assets.sh"
        else
            log "WARN" "rc-assets.sh not found in prototype, skipping."
        fi
    fi

    if [[ "$WITH_RENDER" == true ]]; then
        if [[ -f "$SCRIPTDIR/rc-render.sh" ]]; then
            run "$SCRIPTDIR/rc-render.sh" --verbose
        else
            log "WARN" "rc-render.sh not found in prototype, skipping."
        fi
    fi

    if [[ "$FULL" == true ]]; then
        if [[ -f "$SCRIPTDIR/rc-scan.sh" ]]; then
            run "$SCRIPTDIR/rc-scan.sh"
        else
            log "WARN" "rc-scan.sh not found in prototype, skipping scan."
        fi
    fi

    log "INFO" "✅ Initialization complete."
}

# Only run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
