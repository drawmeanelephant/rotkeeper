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
#  Script  : rc-release.sh
#  Purpose : Package the project into versioned 'lite' and 'full' distribution zips
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
set -euo pipefail
IFS=$'\n\t'

init_log "rc-release"
LOG_FILE="$PWD/$LOG_FILE"

trap cleanup EXIT INT TERM
trap 'trap_err $LINENO' ERR

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  log "ERROR" "No version specified. Usage: rc-release.sh <VERSION> [options]"
  exit 1
fi
shift

show_help() {
  cat << EOF
rc-release.sh — Release Packager

Usage: rc-release.sh <VERSION> [options]

Options:
  --help, -h       Show this help message and exit
  --dry-run        Preview actions without writing files
  --verbose        Enable detailed debug logging
EOF
  exit 0
}

# --- Normalize environment variable overrides ---
: "${DRY_RUN:=${RK_DRY:-false}}"
: "${VERBOSE:=${RK_VERBOSE:-false}}"
HELP=false

# --- Flag parsing ---
for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY_RUN=true ;;
    --verbose)   VERBOSE=true ;;
    --help|-h)   HELP=true ;;
  esac
done
if [[ "$HELP" == true ]]; then
  show_help
fi

# We use require_bins from rc-utils.sh. Let's make sure rsync and zip are present.
check_dependencies
require_bins rsync zip

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RELEASE_DIR="$PROJECT_ROOT/bones/archives/releases"
STAGING_DIR="$PROJECT_ROOT/tmp/release-staging"

cleanup() {
    log "INFO" "Cleaning up temporary staging directory..."
    if [[ -d "$STAGING_DIR" ]]; then
        rm -rf "$STAGING_DIR"
    fi
}

main() {
    log "INFO" "Starting release packaging for version: $VERSION"

    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$RELEASE_DIR"
        mkdir -p "$STAGING_DIR"
    fi

    local FULL_DIR="$STAGING_DIR/rotkeeper-full"
    local LITE_DIR="$STAGING_DIR/rotkeeper-lite"
    local FULL_ZIP="$RELEASE_DIR/rotkeeper-$VERSION-full.zip"
    local LITE_ZIP="$RELEASE_DIR/rotkeeper-$VERSION-lite.zip"

    log "INFO" "Staging rotkeeper-full..."
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$FULL_DIR"
        # rsync project excluding build outputs, temp files, and git
        rsync -a \
            --exclude='.git' \
            --exclude='tmp' \
            --exclude='output' \
            --exclude='bones/logs' \
            --exclude='bones/archives' \
            --exclude='.DS_Store' \
            --exclude='.vscode' \
            "$PROJECT_ROOT/" "$FULL_DIR/"
    fi

    log "INFO" "Staging rotkeeper-lite..."
    if [[ "$DRY_RUN" == false ]]; then
        # Copy full as a base
        cp -a "$FULL_DIR" "$LITE_DIR"
        
        # Strip documentation for lite
        rm -f "$LITE_DIR/README.md"
        rm -f "$LITE_DIR/CHANGELOG.md"
        rm -f "$LITE_DIR/CONTRIBUTING.md"
        rm -f "$LITE_DIR/CREDITS.md"
        
        # Strip content documentation
        rm -rf "$LITE_DIR/home/content/docs"
        rm -rf "$LITE_DIR/home/content/help"
        rm -rf "$LITE_DIR/home/content/rotkeeper"
        
        # Inject micro-README for agents/users in lite
        cat << 'EOF_README' > "$LITE_DIR/README.md"
# Welcome to Rotkeeper (Lite Distribution)

This is the lean, documentation-free distribution of Rotkeeper.

**Quickstart:**
1. Source files live in `home/content/`.
2. To see available commands, run: `./rotkeeper.sh help`

If you are an autonomous agent, please see `AGENTS.md` or `GEMINI.md`.
EOF_README
    fi

    log "INFO" "Creating distribution zip archives..."
    if [[ "$DRY_RUN" == false ]]; then
        # Change directory without subshell to avoid macOS fork/exec CoreFoundation issues
        local ORIG_DIR
        ORIG_DIR="$(pwd)"
        cd "$STAGING_DIR"
        
        log "INFO" "Compressing $FULL_ZIP..."
        rm -f "$FULL_ZIP"
        zip -rq "$FULL_ZIP" "rotkeeper-full"
        
        log "INFO" "Compressing $LITE_ZIP..."
        rm -f "$LITE_ZIP"
        zip -rq "$LITE_ZIP" "rotkeeper-lite"
        
        cd "$ORIG_DIR"
        log "INFO" "✅ Releases successfully packaged:"
        log "INFO" "   - $FULL_ZIP"
        log "INFO" "   - $LITE_ZIP"
        echo "✅ Releases successfully packaged in bones/archives/releases/"
    else
        log "DRYRUN" "Would stage and compress $FULL_ZIP and $LITE_ZIP"
    fi
}

main "$@"
