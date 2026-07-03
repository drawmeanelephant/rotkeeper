#!/usr/bin/env bash
# ============================================================
#  ██████╗ ███████╗██████╗ ███████╗███████╗███████╗
#  ██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝██╔════╝
#  ██████╔╝█████╗  ██████╔╝█████╗  █████╗  █████╗
#  ██╔═══╝ ██╔══╝  ██╔═══╝ ██╔══╝  ██╔══╝  ██╔══╝
#  ██║     ███████╗██║     ███████╗███████╗███████╗
#  ╚═╝     ╚══════╝╚═╝     ╚══════╝╚══════╝╚══════╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-release.sh
#  Purpose : Package the project into versioned lite, full, and dev distribution zips
# ------------------------------------------------------------
#  Three-tier model:
#    dev  — complete archive (home/ untouched, only git/outputs/tmp stripped)
#    full — standard user dist (dev scripts + book-reports + obsolete stripped, all home/ kept)
#    lite — lean runtime (full minus docs dirs and heavy splash asset)
# ============================================================
show_help() {
  cat << HELPEOF
rc-release.sh — Release Packager (Three-Tier)

Usage: rc-release.sh <VERSION> [options]

Options:
  --version, -v    Show script version and quit
  --help, -h       Show this help message and exit
  --dry-run        Preview actions without writing files
  --verbose        Enable detailed debug logging
  --tier <name>    Build only one tier: lite | full | dev (default: all three)
HELPEOF
  exit 0
}

source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
VERSION="${ROTKEEPER_VERSION:-0.4.0.3}"

rk_init_script "rc-release" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR OUTPUT_DIR
set -euo pipefail
IFS=$'\n\t'


LOG_FILE="$PWD/$LOG_FILE"

TARGET_VERSION=""
BUILD_TIER="all"
PREV_ARG=""

# --- Flag parsing ---
for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY_RUN=true ;;
    --verbose)   VERBOSE=true ;;
    --help|-h)   show_help ;;
    --tier)      : ;;
    -*) log "ERROR" "Unknown flag: $arg"; exit 1 ;;
    *)
      if [[ "$PREV_ARG" == "--tier" ]]; then
        BUILD_TIER="$arg"
      elif [[ -z "$TARGET_VERSION" ]]; then
        TARGET_VERSION="$arg"
      fi
      ;;
  esac
  PREV_ARG="$arg"
done

if [[ -n "$TARGET_VERSION" ]]; then
  VERSION="$TARGET_VERSION"
fi

if [[ -z "$VERSION" ]]; then
  log "ERROR" "No version specified. Usage: rc-release.sh <VERSION> [options]"
  exit 1
fi

check_dependencies
require_bins rsync zip

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RELEASE_DIR="$PROJECT_ROOT/bones/releases"
STAGING_DIR="$PROJECT_ROOT/bones/tmp/release-staging"

cleanup() {
    log "INFO" "Cleaning up temporary staging directory..."
    if [[ -d "$STAGING_DIR" ]]; then
        rm -rf "$STAGING_DIR"
    fi
}
trap cleanup EXIT

# ============================================================
# DEV_EXCLUDES — stripped from Full and Lite, kept in Dev.
# Dev tier: home/ is entirely untouched. Only git/outputs/tmp go.
# ============================================================
DEV_EXCLUDES=(
    "bones/scripts/rc-release.sh"
    "bones/scripts/rc-test.sh"
    "bones/scripts/rc-bump.sh"
    "bones/scripts/rc-book.sh"
    "bones/scripts/rc-dip.sh"
    "bones/scripts/rc-reseed.sh"
    "bones/book-reports"
    "home/obsolete"
    ".github"
    ".shellcheckrc"
    "AGENTS.md"
    "GEMINI.md"
)

# LITE_ADDITIONAL_EXCLUDES — applied on top of DEV_EXCLUDES for Lite only.
LITE_ADDITIONAL_EXCLUDES=(
    "home/content/docs"
    "home/content/help"
    "home/content/rotkeeper"
    "home/assets/images/rotkeeper-splash.png"
    "README.md"
    "CHANGELOG.md"
    "CONTRIBUTING.md"
    "CREDITS.md"
)

# ============================================================
# Helpers
# ============================================================
stage_base() {
    local dest="$1"
    log "INFO" "Staging base project into $(basename "$dest") ..."
    [[ "$DRY_RUN" == true ]] && return
    mkdir -p "$dest"
    rsync -a \
        --exclude='.git' \
        --exclude='output' \
        --exclude='bones/logs' \
        --exclude='bones/tmp' \
        --exclude='bones/releases' \
        --exclude='bones/archive' \
        --exclude='bones/ingested' \
        --exclude='bones/reports' \
        --exclude='messages-from-my-friends' \
        --exclude='home/content/messages' \
        --exclude='.DS_Store' \
        --exclude='.vscode' \
        --exclude='todo.md' \
        --exclude='*_temp.md' \
        "$PROJECT_ROOT/" "$dest/"
}

apply_excludes() {
    local dir="$1"; shift
    local excludes=("$@")
    [[ "$DRY_RUN" == true ]] && { log "DRYRUN" "Would strip ${#excludes[@]} items from $(basename "$dir")"; return; }
    for item in "${excludes[@]}"; do
        local target="$dir/$item"
        if [[ -e "$target" || -d "$target" ]]; then
            rm -rf "$target"
            log "INFO" "  Stripped: $item"
        fi
    done
}

make_zip() {
    local tier_dir="$1"
    local zip_path="$2"
    [[ "$DRY_RUN" == true ]] && { log "DRYRUN" "Would zip $(basename "$tier_dir") -> $(basename "$zip_path")"; return; }
    local orig_dir; orig_dir="$(pwd)"
    cd "$STAGING_DIR"
    rm -f "$zip_path"
    zip -rq "$zip_path" "$(basename "$tier_dir")"
    cd "$orig_dir"
    log "INFO" "  ✅ $(basename "$zip_path") — $(du -sh "$zip_path" | cut -f1)"
}

inject_lite_readme() {
    local lite_dir="$1"
    [[ "$DRY_RUN" == true ]] && return
    cat << 'EOF_README' > "$lite_dir/README.md"
# Welcome to Rotkeeper (Lite Distribution)

This is the lean, runtime-only distribution of Rotkeeper.
No documentation, no dev scripts, no heavy assets.

**Quickstart:**
1. Initialize the workspace: `./rotkeeper.sh init`
2. Create markdown files in `home/content/` with YAML frontmatter.
3. Render your output: `./rotkeeper.sh render`

**Frontmatter required for every content file:**
---
title: "My Page"
slug: my-page
template: rotkeeper-blog.html
---

For full documentation, use the Full or Dev distribution.
EOF_README
}

inject_lite_index() {
    local lite_dir="$1"
    [[ "$DRY_RUN" == true ]] && return
    cat << 'EOF_INDEX' > "$lite_dir/home/content/index.md"
---
title: "Welcome to Rotkeeper (Lite)"
slug: home
template: rotkeeper-blog.html
description: "Rotkeeper CLI landing page for the Lite distribution."
---

# Rotkeeper: A Ritual CLI for Flat-File Decay

Welcome to the Lite distribution of Rotkeeper.

To start rendering tombs, run:
`./rotkeeper.sh render`

*Note: Documentation and sample blogs have been stripped from this lite version.*
EOF_INDEX
}

# ============================================================
# Main
# ============================================================
main() {
    log "INFO" "Starting release packaging for version: $VERSION (tiers: $BUILD_TIER)"
    [[ "$DRY_RUN" == false ]] && mkdir -p "$RELEASE_DIR" "$STAGING_DIR"

    # ── Dev tier — home/ untouched, only git/outputs/tmp excluded ──
    if [[ "$BUILD_TIER" == "all" || "$BUILD_TIER" == "dev" ]]; then
        local DEV_DIR="$STAGING_DIR/rotkeeper-dev"
        local DEV_ZIP="$RELEASE_DIR/rotkeeper-$VERSION-dev.zip"
        log "INFO" "Building dev tier..."
        stage_base "$DEV_DIR"
        make_zip "$DEV_DIR" "$DEV_ZIP"
    fi
    
    # ── Full tier — dev scripts + book-reports + obsolete stripped, all home/ kept ──
    if [[ "$BUILD_TIER" == "all" || "$BUILD_TIER" == "full" ]]; then
        local FULL_DIR="$STAGING_DIR/rotkeeper-full"
        local FULL_ZIP="$RELEASE_DIR/rotkeeper-$VERSION-full.zip"
        log "INFO" "Building full tier..."
        stage_base "$FULL_DIR"
        apply_excludes "$FULL_DIR" "${DEV_EXCLUDES[@]}"
        make_zip "$FULL_DIR" "$FULL_ZIP"
    fi
    
    # ── Lite tier — full minus docs dirs and splash image ──
    if [[ "$BUILD_TIER" == "all" || "$BUILD_TIER" == "lite" ]]; then
        local LITE_DIR="$STAGING_DIR/rotkeeper-lite"
        local LITE_ZIP="$RELEASE_DIR/rotkeeper-$VERSION-lite.zip"
        log "INFO" "Building lite tier..."
        if [[ -d "$STAGING_DIR/rotkeeper-full" && "$BUILD_TIER" == "all" ]]; then
            [[ "$DRY_RUN" == false ]] && cp -a "$STAGING_DIR/rotkeeper-full" "$LITE_DIR"
        else
            stage_base "$LITE_DIR"
            apply_excludes "$LITE_DIR" "${DEV_EXCLUDES[@]}"
        fi
        apply_excludes "$LITE_DIR" "${LITE_ADDITIONAL_EXCLUDES[@]}"
        inject_lite_readme "$LITE_DIR"
        inject_lite_index "$LITE_DIR"
        make_zip "$LITE_DIR" "$LITE_ZIP"
    fi
    
    log "INFO" "All requested tiers packaged in $RELEASE_DIR"
    echo "✅ Release packaging complete — see bones/releases/"
}

main "$@"
