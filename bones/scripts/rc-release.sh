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
#  Version : 0.5.1
# ============================================================

VERSION="${ROTKEEPER_VERSION:-0.5.1}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
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
require_bins rsync zip zipinfo

PROJECT_ROOT="$ROOT_DIR"
STAGING_DIR="$TMP_DIR/release-staging"
ZIP_TMP=""

canonicalize_release_path() {
    local path="$1"
    local parent
    local base
    local canonical

    if canonical=$(realpath -m "$path" 2>/dev/null); then
        printf '%s\n' "$canonical"
        return 0
    fi

    parent=$(dirname "$path")
    base=$(basename "$path")
    if parent=$(cd "$parent" 2>/dev/null && pwd -P); then
        printf '%s/%s\n' "$parent" "$base"
    else
        printf '%s\n' "$path"
    fi
}

cleanup() {
    local status=$?
    log "INFO" "Cleaning up temporary staging directories from the physical realm..."
    if [[ -d "$STAGING_DIR" ]]; then
        CANONICAL_STAGING_DIR=$(canonicalize_release_path "$STAGING_DIR")
        if [[ "${CANONICAL_STAGING_DIR}/" == "${ROOT_DIR}/"* ]]; then
            rm -rf "$CANONICAL_STAGING_DIR"
        fi
    fi
    if [[ -n "${ZIP_TMP:-}" && -f "$ZIP_TMP" ]]; then
        rm -f "$ZIP_TMP" || true
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

verify_archive_contents() {
    local archive_path="$1"
    local entry
    local forbidden_prefix
    local -a forbidden_prefixes=(
        "rotkeeper/.git/"
        "rotkeeper/output/"
        "rotkeeper/${LOG_DIR#"$ROOT_DIR"/}/"
        "rotkeeper/${TMP_DIR#"$ROOT_DIR"/}/"
        "rotkeeper/${ARCHIVE_DIR#"$ROOT_DIR"/}/"
        "rotkeeper/${REPORT_DIR#"$ROOT_DIR"/}/"
        "rotkeeper/${BOOK_REPORT_DIR#"$ROOT_DIR"/}/"
        "rotkeeper/${CONTENT_DIR#"$ROOT_DIR"/}/messages/"
        "rotkeeper/apex-spike/"
    )

    while IFS= read -r entry; do
        for forbidden_prefix in ${forbidden_prefixes[@]+"${forbidden_prefixes[@]}"}; do
            if [[ "$entry" == "$forbidden_prefix"* ]]; then
                log "ERROR" "Forbidden path included in release archive: $entry"
                return 1
            fi
        done
        if [[ "$entry" == */.DS_Store || "$entry" == *_temp.md ]]; then
            log "ERROR" "Forbidden artifact included in release archive: $entry"
            return 1
        fi
    done < <(zipinfo -1 "$archive_path")
}

main() {
    log "INFO" "Collapsing package model down to canonical single framework distribution: version $VERSION"

    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$RELEASE_DIR" "$STAGING_DIR"
    fi

    local CANONICAL_DIR="$STAGING_DIR/rotkeeper"
    local ZIP_PATH="$RELEASE_DIR/rotkeeper-$VERSION.zip"
    ZIP_TMP="$RELEASE_DIR/.rotkeeper-$VERSION.zip.tmp.$$"

    validate_boundary "$CANONICAL_DIR"
    validate_boundary "$ZIP_PATH"
    validate_boundary "$ZIP_TMP"

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
        --exclude='apex-spike/' \
        --exclude='.DS_Store' \
        --exclude='*_temp.md' \
        "$PROJECT_ROOT/" "$CANONICAL_DIR/"

    local orig_dir; orig_dir="$(pwd)"
    cd "$STAGING_DIR"
    zip -rq "$ZIP_TMP" "rotkeeper"
    cd "$orig_dir"

    zip -T "$ZIP_TMP" >/dev/null
    verify_archive_contents "$ZIP_TMP"
    mv "$ZIP_TMP" "$ZIP_PATH"
    ZIP_TMP=""

    log "INFO" "✅ Canonical single distribution created: $ZIP_PATH — $(du -sh "$ZIP_PATH" | cut -f1)"
    echo "✅ Release packaging complete — see ${ARCHIVE_DIR#"$ROOT_DIR"/}/releases/rotkeeper-[VERSION].zip"
}

main "$@"
