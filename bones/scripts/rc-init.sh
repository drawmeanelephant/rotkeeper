#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# ============================================================
#  ██╗███╗   ██╗██╗████████╗
#  ██║████╗  ██║██║╚══██╔══╝
#  ██║██╔██╗ ██║██║   ██║
#  ██║██║╚██╗██║██║   ██║
#  ██║██║ ╚████║██║   ██║
#  ╚═╝╚═╝  ╚═══╝╚═╝   ╚═╝
# ============================================================
#  Project : Rotkeeper
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
  --full           Perform full sample, assets, render, and scan
EOF2
  return 0
}


set -euo pipefail
IFS=$'
	'

# Source shared Rotkeeper helpers

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
declare -F rk_init_script >/dev/null || { printf 'FATAL: rc-utils.sh loaded without rk_init_script
' >&2; exit 1; }

# Parse profile first
PROFILE=""
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
        --profile=*)   PROFILE="${arg#*=}" ;;
    esac
done

if [[ "$FULL" == true ]]; then
    WITH_SAMPLE=true
    WITH_ASSETS=true
    WITH_RENDER=true
fi

if [[ -n "$PROFILE" && "$PROFILE" != "default" ]]; then
    export LAYOUT_STYLE="$PROFILE"
fi

rk_load_env bootstrap
rk_init_script "rc-init" "$@"

require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR CONTENT_DIR DOCS_DIR OUTPUT_DIR RELEASE_DIR



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
if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "Would bless scripts with +x permissions in $SCRIPT_DIR"
else
    log "INFO" "🔐 Blessing scripts with +x permissions..."
    find "$SCRIPT_DIR" -type f \( -name "rc-*.sh" -o -name "rc-*.bats" \) -exec chmod +x {} \;
fi

main() {
    # Verify required tools (config serialization is yq-driven)
    require_bins bash
    require_yq_version
    $VERBOSE && log "INFO" "Dependencies verified."

    if [[ ! -d "$TEMPLATE_DIR" ]]; then
        # This check might fail in pure sandbox without templates, but keeping the logic
        log "WARN" "bones/templates directory is missing (ignored in prototype if not rendering)."
    fi

    log "INFO" "🔄 Starting initialization (Minimal mode by default)..."

    # Create core directories non-destructively
    mkdir -p "$CONTENT_DIR"
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$CONFIG_DIR"
    log "INFO" "✅ Verified core directories exist."


    if [[ "$DRY_RUN" == false ]]; then
        log "INFO" "📦 Serializing environment directory configurations to rotkeeper.yaml..."

        if [[ ! -f "$CONFIG_TARGET" || ! -s "$CONFIG_TARGET" ]]; then
           echo "title: \"Rotkeeper Config\"" > "$CONFIG_TARGET"
        fi

        if [[ -n "$PROFILE" && "$PROFILE" != "default" ]]; then
           yq eval ".layout_style = \"$PROFILE\"" -i "$CONFIG_TARGET"
        fi

        # Explicitly map the active folder locations straight into the target yaml config.
        # Single yq transaction: a crash mid-write can no longer leave a partially
        # populated paths block (which strict validation treats as fatal corruption).
        yq eval ".paths.ROOT_DIR = \"$ROOT_DIR\" | .paths.BONES_DIR = \"$BONES_DIR\" | .paths.SCRIPT_DIR = \"$SCRIPT_DIR\" | .paths.CONFIG_DIR = \"$CONFIG_DIR\" | .paths.LOG_DIR = \"$LOG_DIR\" | .paths.TMP_DIR = \"$TMP_DIR\" | .paths.ARCHIVE_DIR = \"$ARCHIVE_DIR\" | .paths.RELEASE_DIR = \"$RELEASE_DIR\" | .paths.REPORT_DIR = \"$REPORT_DIR\" | .paths.BOOK_REPORT_DIR = \"$BOOK_REPORT_DIR\" | .paths.META_DIR = \"$META_DIR\" | .paths.TEMPLATE_DIR = \"$TEMPLATE_DIR\" | .paths.ASSETS_DIR = \"$ASSETS_DIR\" | .paths.CONTENT_DIR = \"$CONTENT_DIR\" | .paths.OUTPUT_DIR = \"$OUTPUT_DIR\" | .paths.DOCS_DIR = \"$DOCS_DIR\" | .paths.HELP_DIR = \"$HELP_DIR\" | .paths.WEB_DIR = \"$WEB_DIR\"" -i "$CONFIG_TARGET"

        FORCE_ENV_RELOAD=true rk_load_env strict

        log "INFO" "✅ Path mappings successfully written to configuration profile."
    fi

    if [[ "$WITH_SAMPLE" == true ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            log "DRY-RUN" "Would generate starter content at $CONTENT_DIR/test-file.md"
        elif [[ -f "$CONTENT_DIR/test-file.md" ]]; then
            log "WARN" "Starter content already exists, leaving untouched: $CONTENT_DIR/test-file.md"
        else
            cat << 'EOF_HELLO' > "$CONTENT_DIR/test-file.md"
---
title: "Test File"
slug: test-file
template: rotkeeper-blog.html
description: "A simple starter page to demonstrate YAML frontmatter in Rotkeeper."
---

# Test File!

This is a demonstration page created during initialization.
EOF_HELLO
            log "INFO" "📄 Generated starter content at $CONTENT_DIR/test-file.md"
        fi
    fi

    if [[ "$WITH_ASSETS" == true ]]; then
        if [[ -f "$SCRIPT_DIR/rc-assets.sh" ]]; then
            run "$SCRIPT_DIR/rc-assets.sh"
        else
            log "WARN" "rc-assets.sh not found in prototype, skipping."
        fi
    fi

    if [[ "$WITH_RENDER" == true ]]; then
        if [[ -f "$SCRIPT_DIR/rc-render.sh" ]]; then
            run "$SCRIPT_DIR/rc-render.sh" --verbose
        else
            log "WARN" "rc-render.sh not found in prototype, skipping."
        fi
    fi

    if [[ "$FULL" == true ]]; then
        if [[ -f "$SCRIPT_DIR/rc-scan.sh" ]]; then
            run "$SCRIPT_DIR/rc-scan.sh"
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
