#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# ============================================================
#  ██████╗ ██╗   ██╗███╗   ███╗██████╗
#  ██╔══██╗██║   ██║████╗ ████║██╔══██╗
#  ██████╔╝██║   ██║██╔████╔██║██████╔╝
#  ██╔══██╗██║   ██║██║╚██╔╝██║██╔═══╝
#  ██████╔╝╚██████╔╝██║ ╚═╝ ██║██║
#  ╚═════╝  ╚═════╝ ╚═╝     ╚═╝╚═╝
# ============================================================
# Env assumptions: reads BONES_DIR, CONFIG_DIR, DOCS_DIR, DRY_RUN, LOG_DIR, QUIET, ROOT_DIR, SCRIPT_DIR, TMP_DIR, VERBOSE, VERSION (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.
# CWD assumptions: No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.
# Input/Output contracts: reads the validated semver in `bones/config/version`; the bump calculation does not use `ROTKEEPER_VERSION`. Exactly one of major/minor/patch or `--to` is required; major/minor selectors reset lower segments.
#   Stages the timestamped message after the first `LIVING_BUILDLOG_START` in `DOCS_DIR/road-to-bones/index.md`, a dated CHANGELOG release, and the canonical version as scratch files beside their targets, then moves them into place with the version file last. A missing anchor or `## [` header, or any staging failure, exits 1 with no file changed.
#   `--commit` stages the version, changelog, and roadmap and commits from `ROOT_DIR`; it never pushes. A dirty worktree is warned about rather than rejected. Dry-run previews all updates and Git actions without writes and fails on the same missing anchors.
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-bump.sh
#  Purpose : Explicit semver version bump against the single canonical version file
#  Version : 0.5.1
# ------------------------------------------------------------


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }

# @HELP
# rc-bump.sh — Explicit semver version bump (v{VERSION})
#
# Usage:
#   rotkeeper.sh bump [--major|--minor|--patch|--to X.Y.Z] -m MESSAGE [options]
#
# Description:
#   Records a microrelease update: writes the version marker and
#   synchronizes CHANGELOG.md and the roadmap. Exactly one of --major,
#   --minor, --patch, or --to is required.
#
# Options:
#   --major            Bump major segment: 0.5.1 -> 1.0.0
#   --minor            Bump minor segment: 0.5.1 -> 0.6.0
#   --patch            Bump patch segment: 0.5.1 -> 0.5.2
#   --to VERSION       Set an explicit semver-style version (X.Y.Z)
#   --message, -m MSG  Update message recorded in CHANGELOG.md and the roadmap
#   --commit           Stage changes and commit them to git
#   --dry-run          Preview changes without saving or committing
#   --verbose          Detailed output
#   --help, -h         Show help
#   --version, -v      Show version and quit
#
# Examples:
#   bash rotkeeper.sh bump --patch -m "Fix wrap bug"                 # Patch bump
#   bash rotkeeper.sh bump --to 0.8.0 -m "UX pass" --commit          # Explicit version + commit
#   bash rotkeeper.sh bump --minor -m "..." --dry-run                # Preview only
#
# Exit codes:
#   0    Success
#   1    Invalid input or bump failure
# @END-HELP

rk_init_script "rc-bump" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR

VERSION_FILE="$ROOT_DIR/bones/config/version"
MESSAGE=""
COMMIT=false
BUMP_MAJOR=false
BUMP_MINOR=false
BUMP_PATCH=false
BUMP_TO=""

CURRENT_VERSION="$(tr -d '[:space:]' < "$VERSION_FILE" 2>/dev/null || true)"
CURRENT_VERSION="${CURRENT_VERSION#v}"
if [[ -z "$CURRENT_VERSION" || ! "$CURRENT_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  log "ERROR" "Canonical version file ($VERSION_FILE) is missing or not semver-style (X.Y.Z)."
  exit 1
fi

# Parse flags manually; the shared parser already handled leading common flags.
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version|-v) echo "$(basename "$0") v${VERSION:-unknown}"; exit 0 ;;
    --major) BUMP_MAJOR=true; shift ;;
    --minor) BUMP_MINOR=true; shift ;;
    --patch) BUMP_PATCH=true; shift ;;
    --to) BUMP_TO="${2:-}"; shift 2 ;;
    --message|-m) MESSAGE="${2:-}"; shift 2 ;;
    --commit) COMMIT=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --verbose) # shellcheck disable=SC2034
               VERBOSE=true; shift ;;
    --help|-h) show_help; exit 0 ;;
    -*) log "ERROR" "Unknown flag: $1"; show_help; exit 1 ;;
    *)
      if [[ -z "$MESSAGE" ]]; then
        MESSAGE="$1"
      else
        MESSAGE="$MESSAGE $1"
      fi
      shift
      ;;
  esac
done

if [[ -z "$MESSAGE" ]]; then
  log "ERROR" "No update message provided (-m MESSAGE)."
  show_help
  exit 1
fi

# Shared parsing may have returned before seeing --dry-run; surface preview
# output even when QUIET defaulted to true.
if [[ "$DRY_RUN" == true ]]; then
  QUIET=false
fi

SELECTORS=0
[[ "$BUMP_MAJOR" == true ]] && SELECTORS=$((SELECTORS + 1))
[[ "$BUMP_MINOR" == true ]] && SELECTORS=$((SELECTORS + 1))
[[ "$BUMP_PATCH" == true ]] && SELECTORS=$((SELECTORS + 1))
[[ -n "$BUMP_TO" ]] && SELECTORS=$((SELECTORS + 1))
if [[ "$SELECTORS" -ne 1 ]]; then
  log "ERROR" "Specify exactly one of --major, --minor, --patch, or --to VERSION."
  show_help
  exit 1
fi

# Gate git before any file is touched when --commit was requested, so a
# missing dependency never leaves a half-applied bump behind.
if [[ "$COMMIT" == true ]]; then
  require_bins git
fi

IFS='.' read -r MAJ_VER MIN_VER PATCH_VER <<< "$CURRENT_VERSION"

if [[ -n "$BUMP_TO" ]]; then
  if [[ ! "$BUMP_TO" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log "ERROR" "--to requires a semver-style version (X.Y.Z), got: $BUMP_TO"
    exit 1
  fi
  NEW_VERSION="$BUMP_TO"
elif [[ "$BUMP_MAJOR" == true ]]; then
  NEW_VERSION="$((MAJ_VER + 1)).0.0"
elif [[ "$BUMP_MINOR" == true ]]; then
  NEW_VERSION="$MAJ_VER.$((MIN_VER + 1)).0"
else
  NEW_VERSION="$MAJ_VER.$MIN_VER.$((PATCH_VER + 1))"
fi

if [[ "$NEW_VERSION" == "$CURRENT_VERSION" ]]; then
  log "ERROR" "Target version $NEW_VERSION equals current version; nothing to bump."
  exit 1
fi

if [[ -n "$(git -C "$ROOT_DIR" status --porcelain 2>/dev/null)" ]]; then
  log "WARN" "Working tree is dirty. Proceeding with version bump, but be aware uncommitted changes exist."
fi

log "INFO" "Current version: $CURRENT_VERSION (from $VERSION_FILE)"
log "INFO" "New version: $NEW_VERSION"

ROADMAP_FILE="$DOCS_DIR/road-to-bones/index.md"
CHANGELOG_FILE="$ROOT_DIR/CHANGELOG.md"
DATE_STR=$(date +"%Y-%m-%d %H:%M")
ENTRY="* \`v$NEW_VERSION\` - ($DATE_STR) - $MESSAGE"
CHANGELOG_DATE=$(date +%Y-%m-%d)

# Renderers print a target's replacement on stdout. The document renderers
# exit 2 when their insertion point is absent, so a missing anchor fails the
# bump instead of rewriting the file unchanged and reporting success.
render_version() {
  printf '%s\n' "$NEW_VERSION"
}

render_roadmap() {
  # awk: inject the entry after the first LIVING_BUILDLOG_START marker, pass through rest
  awk -v entry="$ENTRY" '
    !inserted && /<!-- LIVING_BUILDLOG_START -->/ {
      print $0
      print entry
      inserted = 1
      next
    }
    { print }
    END { if (!inserted) exit 2 }
  ' "$ROADMAP_FILE"
}

render_changelog() {
  # awk: prepend the new section before the first ## [ header (newest-first), pass through rest
  awk -v new_version="$NEW_VERSION" -v date_str="$CHANGELOG_DATE" -v msg="$MESSAGE" '
    !inserted && /^## \[/ {
      printf "## [%s] - %s\n\n- %s\n\n", new_version, date_str, msg
      inserted = 1
    }
    { print }
    END { if (!inserted) exit 2 }
  ' "$CHANGELOG_FILE"
}

# Targets staged for replacement, in replacement order, with the message
# logged once each one lands.
STAGED_TARGETS=()
STAGED_NOTES=()

cleanup() {
  if [[ "${cleanup_ran:-false}" == true ]]; then return 0; fi
  cleanup_ran=true
  local target
  for target in ${STAGED_TARGETS[@]+"${STAGED_TARGETS[@]}"}; do
    # SIDE EFFECT (delete): removes any <target>.tmp.$$ scratch file a failed run left behind
    rm -f "$target.tmp.$$" || true
  done
}

# ---
# stage_update: Render one target's replacement into a per-process scratch
# file beside it (#231) without touching the target. Dry-run renders to
# /dev/null, so a missing insertion point fails the preview too.
# Inputs: $1 (target), $2 (renderer), $3 (insertion point named in errors),
#         $4 (dry-run preview), $5 (message logged after replacement)
# Outputs: Appends to STAGED_TARGETS/STAGED_NOTES; exits 1 on any failure
# ---
stage_update() {
  local target="$1" renderer="$2" anchor="$3" preview="$4" note="$5"
  local out="/dev/null" status=0
  if [[ "$DRY_RUN" != true ]]; then
    out="$target.tmp.$$"
    STAGED_TARGETS+=("$target")
    STAGED_NOTES+=("$note")
  fi
  # SIDE EFFECT (write): creates <target>.tmp.$$ beside the target (dry-run writes nothing)
  "$renderer" > "$out" || status=$?
  if [[ "$status" -eq 2 ]]; then
    log "ERROR" "$anchor not found in $target; nothing was changed."
    exit 1
  elif [[ "$status" -ne 0 ]]; then
    log "ERROR" "Failed to stage the update for $target; nothing was changed."
    exit 1
  fi
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "$preview"
  fi
}

# Step 1: Stage every update before replacing anything, so a failed render,
# missing anchor, or unwritable directory leaves all version markers as they were.
if [[ -f "$ROADMAP_FILE" ]]; then
  stage_update "$ROADMAP_FILE" render_roadmap "Living Buildlog anchor <!-- LIVING_BUILDLOG_START -->" \
    "Would inject into roadmap: $ENTRY" "Injected update into Living Buildlog."
else
  log "WARN" "Roadmap file not found: $ROADMAP_FILE"
fi

if [[ -f "$CHANGELOG_FILE" ]]; then
  stage_update "$CHANGELOG_FILE" render_changelog "CHANGELOG release header (## [)" \
    "Would prepend to CHANGELOG.md" "Prepended to CHANGELOG.md."
else
  log "WARN" "CHANGELOG.md not found at $CHANGELOG_FILE"
fi

stage_update "$VERSION_FILE" render_version "Version" \
  "Would write $NEW_VERSION to $VERSION_FILE" "Updated $VERSION_FILE to $NEW_VERSION."

# Step 2: Move staged files into place in staging order. The version file is
# staged last, so it never runs ahead of the roadmap and CHANGELOG it describes.
if [[ "$DRY_RUN" != true ]]; then
  for i in "${!STAGED_TARGETS[@]}"; do
    # SIDE EFFECT (write): replaces the roadmap, CHANGELOG.md, then bones/config/version with their scratch files via mv
    mv -f "${STAGED_TARGETS[$i]}.tmp.$$" "${STAGED_TARGETS[$i]}"
    log "INFO" "${STAGED_NOTES[$i]}"
  done
fi

# Step 3: Git Commit
if [[ "$DRY_RUN" == true ]]; then
  log "DRY-RUN" "Would commit changes with message: bump: $NEW_VERSION - $MESSAGE"
  log "INFO" "Bump ritual complete."
  exit 0
fi

if [[ "${COMMIT:-false}" != true ]]; then
  log "INFO" "Changes applied locally. Run with --commit to stage and commit them."
  log "INFO" "Bump ritual complete."
  exit 0
fi

cd "$ROOT_DIR"
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  log "ERROR" "Not inside a git work tree. Cannot commit."
  exit 1
fi

log "INFO" "Staging touched files..."
# SIDE EFFECT (git): stages the version file, CHANGELOG.md, and roadmap index
git add "bones/config/version"
if [[ -f "CHANGELOG.md" ]]; then
  git add "CHANGELOG.md"
fi
if [[ -f "${DOCS_DIR#"$ROOT_DIR"/}/road-to-bones/index.md" ]]; then
  git add "${DOCS_DIR#"$ROOT_DIR"/}/road-to-bones/index.md"
fi

if git diff --quiet --cached; then
  log "WARN" "No changes to commit. Staged diff is empty."
else
  # SIDE EFFECT (git): creates a commit "bump: <version> - <message>" (no push)
  git commit -m "bump: $NEW_VERSION - $MESSAGE"
  log "INFO" "Committed to git repository."
fi

log "INFO" "Bump ritual complete."
