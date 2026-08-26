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
# Env assumptions: reads ARCHIVE_DIR, BONES_DIR, BOOK_REPORT_DIR, CONFIG_DIR, CONTENT_DIR, DRY_RUN, LOG_DIR, OUTPUT_DIR, RELEASE_DIR, REPORT_DIR, ROOT_DIR, SCRIPT_DIR, TMP_DIR, VERBOSE, VERSION (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.
# CWD assumptions: No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.
# Input/Output contracts: CLI args and env vars in; files and stdout/stderr out; respects --dry-run (no writes) and --verbose.
#  Project : Rotkeeper
#  Script  : rc-release.sh
#  Purpose : Streamline multi-tier models down to a single-tier canonical framework distribution zip
#  Version : 0.5.1
# ------------------------------------------------------------
#  Distribution model (Phase 5): a release is a FRAMEWORK DISTRIBUTION
#  (dispatcher, bones system, templates, configuration, project docs), not a
#  site-source archive and not a complete backup. Author content trees that
#  are not part of the framework spine are outside the release contract;
#  caches, logs, temp trees, output, archives, reports, and credentials are
#  forbidden. The staged tree must match an explicit root-entry allowlist,
#  must contain the framework spine, and must carry a generated manifest.
# ============================================================


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }

# ---
# show_help: Print release usage and exit.
# Inputs: none
# Outputs: Prints help to stdout
# Env: Reads BONES_DIR, CONFIG_DIR, DRY_RUN, LOG_DIR, OUTPUT_DIR, QUIET ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
show_help() {
  cat <<'HELP_EOF'
rc-release.sh — Package the canonical single-tier framework distribution

Usage:
  rotkeeper.sh release <VERSION> [options]

Arguments:
  VERSION        Semver-style version for the distribution name (.e.g 0.5.2)

Options:
  --dry-run      Preview the release without writing archives
  --verbose      Detailed output
  --help, -h     Show help
  --version, -v  Show version and quit
HELP_EOF
}

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

require_bins bash rsync zip zipinfo

PROJECT_ROOT="$ROOT_DIR"
STAGING_DIR="$TMP_DIR/release-staging-$$"
ZIP_TMP=""

# ---
# cleanup: Remove staging dir and temp zip on exit.
# Inputs: none (reads STAGING_DIR, ZIP_TMP, TMP_DIR)
# Outputs: Deletes temp files; preserves exit status
# Env: Reads ARCHIVE_DIR, BONES_DIR, BOOK_REPORT_DIR, CONTENT_DIR, DRY_RUN, LOG_DIR ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
cleanup() {
    local status=$?
    log "INFO" "Cleaning up temporary staging directories from the physical realm..."
    # SIDE EFFECT (delete): removes bones/tmp/release-staging-<pid> on any exit path
    if [[ -d "$STAGING_DIR" ]]; then
        if CANONICAL_STAGING_DIR=$(rk_guard_delete "$STAGING_DIR" "$TMP_DIR"); then
            rm -rf "$CANONICAL_STAGING_DIR"
        else
            log "ERROR" "Skipped staging cleanup; '$STAGING_DIR' failed the deletion guard."
        fi
    fi
    # SIDE EFFECT (delete): removes the in-flight zip temp file (no-op after successful mv)
    if [[ -n "${ZIP_TMP:-}" && -f "$ZIP_TMP" ]]; then
        rm -f "$ZIP_TMP" || true
    fi
    exit "$status"
}
trap cleanup EXIT INT TERM

# ---
# validate_boundary: Ensure path is inside staging or release dir.
# Inputs: $1 (target path)
# Outputs: Exits 3 on violation
# Env: Reads ARCHIVE_DIR, BONES_DIR, BOOK_REPORT_DIR, CONTENT_DIR, DRY_RUN, LOG_DIR ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
validate_boundary() {
  local target_path="$1"
  if [[ "$target_path" != "$STAGING_DIR"* && "$target_path" != "$RELEASE_DIR"* ]]; then
    log "ERROR" "Boundary violation: Operation attempted outside staging or release bounds."
    exit 3
  fi
}

# ---
# verify_archive_contents: Validate archive against allowlist/forbidden prefixes.
# Inputs: $1 (archive path)
# Outputs: Returns 0 if valid, 1 on forbidden/missing entries
# Env: Reads ARCHIVE_DIR, BOOK_REPORT_DIR, CONTENT_DIR, LOG_DIR, OUTPUT_DIR, REPORT_DIR ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
verify_archive_contents() {
    local archive_path="$1"
    local entry
    local forbidden_prefix
    local -a forbidden_prefixes=(
        "rotkeeper/.git/"
        "rotkeeper/${OUTPUT_DIR#"$ROOT_DIR"/}/"
        "rotkeeper/${LOG_DIR#"$ROOT_DIR"/}/"
        "rotkeeper/${TMP_DIR#"$ROOT_DIR"/}/"
        "rotkeeper/${ARCHIVE_DIR#"$ROOT_DIR"/}/"
        "rotkeeper/${REPORT_DIR#"$ROOT_DIR"/}/"
        "rotkeeper/${BOOK_REPORT_DIR#"$ROOT_DIR"/}/"
        "rotkeeper/${CONTENT_DIR#"$ROOT_DIR"/}/messages/"
    )
    local -a allowed_root=(
        "rotkeeper.sh"
        "bones/"
        "home/"
        "docs/"
        "scripts/"
        "templates/"
        "assets/"
        "src/"
        "config/"
        "AGENTS.md"
        "CHANGELOG.md"
        "CONTRIBUTING.md"
        "CREDITS.md"
        "GEMINI.md"
        "README.md"
        ".agentignore"
        ".blessed"
        ".editorconfig"
        ".gitignore"
        ".shellcheckrc"
    )
    local -a required_entries=(
        "rotkeeper/rotkeeper.sh"
        "rotkeeper/bones/config/rotkeeper.yaml"
        "rotkeeper/bones/config/version"
        "rotkeeper/bones/config/release-manifest.txt"
        "rotkeeper/bones/scripts/rc-utils.sh"
    )

    local archive_entries
    # zipinfo: list archive entries one per line for allowlist/forbidden checks
    archive_entries="$(zipinfo -1 "$archive_path")"

    local requirement
    for requirement in ${required_entries[@]+"${required_entries[@]}"}; do
        if ! grep -Fxq "$requirement" <<< "$archive_entries"; then
            log "ERROR" "Required framework entry missing from release archive: $requirement"
            return 1
        fi
    done

    local root_entry allowed
    local entry_first
    local entry_top
    while IFS= read -r entry; do
        if [[ -n "$entry" ]]; then
            entry_first="${entry%%/*}"
            entry_top="${entry#*/}"
            entry_top="${entry_top%%/*}"
            if [[ "$entry_first" != "rotkeeper" ]]; then
                log "ERROR" "Unexpected archive entry outside the framework root: $entry"
                return 1
            fi
            if [[ -z "$entry_top" ]]; then
                continue
            fi
            allowed=false
            for root_entry in ${allowed_root[@]+"${allowed_root[@]}"}; do
                if [[ "${entry_top%/}" == "${root_entry%/}" ]]; then
                    allowed=true
                    break
                fi
            done
            if [[ "$allowed" == false ]]; then
                log "ERROR" "Unexpected root-level entry in release archive: $entry"
                return 1
            fi
        fi
        for forbidden_prefix in ${forbidden_prefixes[@]+"${forbidden_prefixes[@]}"}; do
            if [[ "$entry" == "$forbidden_prefix"* ]]; then
                log "ERROR" "Forbidden path included in release archive: $entry"
                return 1
            fi
        done
        if [[ "$entry" == */.DS_Store || "$entry" == *_temp.md || "$entry" == *.pem || "$entry" == *.key || "$entry" == *.p12 || "$entry" == *.pyc || "$entry" == */.env || "$entry" == */.env.* || "$entry" == */id_rsa || "$entry" == */.npmrc || "$entry" == *~ ]]; then
            log "ERROR" "Forbidden artifact included in release archive: $entry"
            return 1
        fi
    done <<< "$archive_entries"
}

# ---
# main: Stage framework files, generate manifest, zip and verify distribution.
# Inputs: $1 (optional version overrides $VERSION)
# Outputs: Writes RELEASE_DIR/rotkeeper-<version>.zip
# Env: Reads ARCHIVE_DIR, BOOK_REPORT_DIR, CONTENT_DIR, DRY_RUN, LOG_DIR, OUTPUT_DIR ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
main() {
    log "INFO" "Collapsing package model down to canonical single framework distribution: version $VERSION"

    if [[ "$DRY_RUN" == false ]]; then
        # SIDE EFFECT (write): creates bones/archives/releases and bones/tmp/release-staging-<pid>
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

    # SIDE EFFECT (write): copies the repo (minus exclusions) into the staging tree
    rsync -a \
        --exclude='.git/' \
        --exclude='.github/' \
        --exclude='.vscode/' \
        --exclude='.freebuff/' \
        --exclude="${OUTPUT_DIR#"$ROOT_DIR"/}/" \
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

    local manifest_file="$CANONICAL_DIR/bones/config/release-manifest.txt"
    local entry_list="$TMP_DIR/release-entries-$$.txt"
    # find+sort: enumerate staged files deterministically for manifest
    # SIDE EFFECT (write): writes the entry list scratch file under bones/tmp
    (cd "$STAGING_DIR" && find rotkeeper -type f | sort) > "$entry_list"
    # SIDE EFFECT (write): generates release-manifest.txt inside the staged tree
    {
        echo "Rotkeeper framework distribution manifest"
        echo "version: $VERSION"
        echo "model: framework distribution (dispatcher, bones system, templates, configuration, project docs)"
        echo "ruleset: release allowlist v1 (explicit root entries, required spine, forbidden prefixes and artifacts)"
        echo "listed_entries: $(wc -l < "$entry_list" | tr -d ' ')"
        echo "entries:"
        cat "$entry_list"
    } > "$manifest_file"
    # SIDE EFFECT (delete): removes the entry list scratch file
    rm -f "$entry_list"

    local orig_dir; orig_dir="$(pwd)"
    cd "$STAGING_DIR"
    # SIDE EFFECT (archive): zips the staged tree to <release>.zip.tmp.$$ (temp name)
    zip -rq "$ZIP_TMP" "rotkeeper"
    cd "$orig_dir"

    zip -T "$ZIP_TMP" >/dev/null
    verify_archive_contents "$ZIP_TMP"
    # SIDE EFFECT (write): promotes the verified temp zip to bones/archives/releases/rotkeeper-<version>.zip
    mv "$ZIP_TMP" "$ZIP_PATH"
    ZIP_TMP=""

    log "INFO" "✅ Canonical single distribution created: $ZIP_PATH — $(du -sh "$ZIP_PATH" | cut -f1)"
    echo "✅ Release packaging complete — see ${ARCHIVE_DIR#"$ROOT_DIR"/}/releases/rotkeeper-[VERSION].zip"
}

main "$@"
