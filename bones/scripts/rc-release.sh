#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# ============================================================
#  ██████╗ ███████╗██████╗ ███████╗███████╗███████╗
#  ██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝██╔════╝
#  ██████╔╝█████╗  ██████╔╝█████╗  █████╗  █████╗
#  ██╔═══╝ ██╔══╝  ██╔═══╝ ██╔══╝  ██╔══╝  ██╔══╝
#  ██║     ███████╗██║     ███████╗███████╗███████╗
#  ╚═╝     ╚══════╝╚═╝     ╚══════╝╚══════╝╚══════╝
# ============================================================
#  Project : Rotkeeper
#  Script  : rc-release.sh
#  Purpose : Streamline multi-tier models down to a single-tier canonical framework distribution zip
#  Version : 0.4.0.4
# ============================================================

VERSION="${ROTKEEPER_VERSION:-0.4.0.4}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
source_rc_env || { echo "FATAL: cannot source rc-env.sh" >&2; exit 1; }
rk_init_script "rc-release" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR OUTPUT_DIR RELEASE_DIR
set -euo pipefail
IFS=$'\n\t'

TARGET_VERSION=""
PREV_ARG=""

for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY_RUN=true ;;
    --verbose)   VERBOSE=true ;;
    --help|-h)   show_help ;;
    -*) log "ERROR" "Unknown flag or legacy option deprecated: $arg"; exit 1 ;;
    *)
      if [[ -z "$TARGET_VERSION" ]]; then
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

PROJECT_ROOT="$ROOT_DIR"
STAGING_DIR="$TMP_DIR/release-staging"

cleanup() {
    local status=$?
    log "INFO" "Cleaning up temporary staging directories from the physical realm..."
        if [[ -d "$STAGING_DIR" ]]; then
        CANONICAL_STAGING_DIR=$(realpath -m "$STAGING_DIR")
        if [[ "${CANONICAL_STAGING_DIR}/" == "${ROOT_DIR}/"* ]]; then
            rm -rf "$CANONICAL_STAGING_DIR"
        fi
    fi
    exit "$status"
}
trap cleanup EXIT INT TERM

validate_boundary() {
  local target_path="$1"
  if [[ "$target_path" != "$STAGING_DIR"* && "$target_path" != "$RELEASE_DIR"* ]]; then
    log "ERROR" "Boundary violation: Operation attempted outside staging or release bounds."
    exit 3
  fi
}

main() {
    log "INFO" "Collapsing package model down to canonical single framework distribution: version $VERSION"

    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$RELEASE_DIR" "$STAGING_DIR"
    fi

    local CANONICAL_DIR="$STAGING_DIR/rotkeeper"
    local ZIP_PATH="$RELEASE_DIR/rotkeeper-$VERSION.zip"

    validate_boundary "$CANONICAL_DIR"
    validate_boundary "$ZIP_PATH"

    log "INFO" "Staging repository via strict exclusions..."
    if [[ "$DRY_RUN" == true ]]; then
        log "DRYRUN" "Would stage elements and filter exclusions into $CANONICAL_DIR"
        log "DRYRUN" "Would zip compiled architecture safely into $ZIP_PATH"
        return 0
    fi

    mkdir -p "$CANONICAL_DIR"

    rsync -a \
        --exclude='.git/' \
        --exclude='output/' \
        --exclude="${LOG_DIR#"$ROOT_DIR"/}/" \
        --exclude="${TMP_DIR#"$ROOT_DIR"/}/" \
        --exclude="${ARCHIVE_DIR#"$ROOT_DIR"/}/releases/" \
        --exclude="${ARCHIVE_DIR#"$ROOT_DIR"/}/" \
        --exclude="${REPORT_DIR#"$ROOT_DIR"/}/" \
        --exclude="${BOOK_REPORT_DIR#"$ROOT_DIR"/}/" \
        --exclude="${CONTENT_DIR#"$ROOT_DIR"/}/messages/" \
        --exclude='.DS_Store' \
        --exclude='*_temp.md' \
        "$PROJECT_ROOT/" "$CANONICAL_DIR/"

    local orig_dir; orig_dir="$(pwd)"
    cd "$STAGING_DIR"
    rm -f "$ZIP_PATH"

    zip -rq "$ZIP_PATH" "rotkeeper"
    cd "$orig_dir"

    log "INFO" "✅ Canonical single distribution created: $ZIP_PATH — $(du -sh "$ZIP_PATH" | cut -f1)"
    echo "✅ Release packaging complete — see ${ARCHIVE_DIR#"$ROOT_DIR"/}/releases/rotkeeper-[VERSION].zip"
}

main "$@"
