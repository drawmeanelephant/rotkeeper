#!/usr/bin/env bash
# ============================================================
#  ██╗███╗   ██╗██╗████████╗
#  ██║████╗  ██║██║╚══██╔══╝
#  ██║██╔██╗ ██║██║   ██║
#  ██║██║╚██╗██║██║   ██║
#  ██║██║ ╚████║██║   ██║
#  ╚═╝╚═╝  ╚═══╝╚═╝   ╚═╝
# ============================================================
# ============================================================
#  Project : Rotkeeper
#  Script  : rc-init.sh
#  Purpose : Minimal, non-destructive environment initialization
#  Version : 0.4.0.3
# ============================================================

show_help() {
  cat << EOF
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
  --full           Full initialization (sample, assets, render, and scan)
EOF
  exit 0
}

source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
VERSION="${ROTKEEPER_VERSION:-0.4.0.3}"

rk_init_script "rc-init" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR CONTENT_DIR DOCS_DIR

set -euo pipefail
IFS=$'\n\t'

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPTDIR/../.."

WITH_SAMPLE=false
WITH_ASSETS=false
WITH_RENDER=false
FULL=false

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

log "INFO" "🔐 Blessing scripts with +x permissions..."
find "$SCRIPTDIR" -type f \( -name "rc-*.sh" -o -name "rc-*.bats" \) -exec chmod +x {} \;

main() {
    check_dependencies
    $VERBOSE && log "INFO" "Dependencies verified."

    if [[ ! -d "$PROJECT_ROOT/bones/templates" ]]; then
        log "WARN" "bones/templates directory is missing."
    fi

    log "INFO" "🔄 Starting initialization..."

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
            log "WARN" "rc-assets.sh not found, skipping."
        fi
    fi

    if [[ "$WITH_RENDER" == true ]]; then
        if [[ -f "$SCRIPTDIR/rc-render.sh" ]]; then
            run "$SCRIPTDIR/rc-render.sh" --verbose
        else
            log "WARN" "rc-render.sh not found, skipping."
        fi
    fi

    if [[ "$FULL" == true ]]; then
        if [[ -f "$SCRIPTDIR/rc-scan.sh" ]]; then
            run "$SCRIPTDIR/rc-scan.sh"
        else
            log "WARN" "rc-scan.sh not found, skipping scan."
        fi
    fi

    log "INFO" "✅ Initialization complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi