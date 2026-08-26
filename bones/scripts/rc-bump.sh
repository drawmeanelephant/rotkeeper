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
# Input/Output contracts: CLI args and env vars in; files and stdout/stderr out; respects --dry-run (no writes) and --verbose.
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-bump.sh
#  Purpose : Explicit semver version bump against the single canonical version file
#  Version : 0.5.1
# ------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }

# ---
# show_help: Print bump usage and exit.
# Inputs: none
# Outputs: Prints help to stdout
# Env: Reads BONES_DIR, CONFIG_DIR, DRY_RUN, LOG_DIR, QUIET, ROOT_DIR ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
show_help() {
  cat <<'HELP_EOF'
rc-bump.sh — Explicit semver version bump

Usage:
  rotkeeper.sh bump [--major|--minor|--patch|--to X.Y.Z] -m MESSAGE [options]

Options:
  --major          Bump major segment: 0.5.1 -> 1.0.0
  --minor          Bump minor segment: 0.5.1 -> 0.6.0
  --patch          Bump patch segment: 0.5.1 -> 0.5.2
  --to VERSION     Set an explicit semver-style version (X.Y.Z)
  --message, -m MSG  Update message recorded in CHANGELOG.md and the roadmap
  --commit         Stage changes and commit them to git
  --dry-run        Preview changes without saving or committing
  --verbose        Detailed output
  --help, -h       Show help
  --version, -v    Show version and quit

Exactly one of --major, --minor, --patch, or --to is required.
HELP_EOF
}

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

# Step 1: Update the single canonical version source
if [[ "$DRY_RUN" == true ]]; then
  log "DRY-RUN" "Would write $NEW_VERSION to $VERSION_FILE"
else
  printf '%s\n' "$NEW_VERSION" > "$VERSION_FILE"
  log "INFO" "Updated $VERSION_FILE to $NEW_VERSION."
fi

# Step 2: Inject into Living Buildlog
ROADMAP_FILE="$DOCS_DIR/road-to-bones/index.md"
DATE_STR=$(date +"%Y-%m-%d %H:%M")
ENTRY="* \`v$NEW_VERSION\` - ($DATE_STR) - $MESSAGE"

if [[ -f "$ROADMAP_FILE" ]]; then
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "Would inject into roadmap: $ENTRY"
  else
    # Inject after the anchor through a per-process temp surface (#231)
    # awk: inject new entry immediately after LIVING_BUILDLOG_START marker, pass through rest
    roadmap_tmp="${ROADMAP_FILE}.tmp.$$"
    if ! awk -v entry="$ENTRY" '
      /<!-- LIVING_BUILDLOG_START -->/ {
        print $0
        print entry
        next
      }
      {print}
    ' "$ROADMAP_FILE" > "$roadmap_tmp"; then
      rm -f "$roadmap_tmp"
      log "ERROR" "Failed to inject update into Living Buildlog."
      exit 1
    fi
    mv "$roadmap_tmp" "$ROADMAP_FILE"
    log "INFO" "Injected update into Living Buildlog."
  fi
else
  log "WARN" "Roadmap file not found: $ROADMAP_FILE"
fi

# Step 3: Prepend to CHANGELOG.md (newest-first convention)
CHANGELOG_FILE="$ROOT_DIR/CHANGELOG.md"
if [[ -f "$CHANGELOG_FILE" ]]; then
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "Would prepend to CHANGELOG.md"
  else
    # Prepend through a per-process temp surface (#231)
    # awk: prepend new changelog section before first ## [ header, pass through rest
    changelog_tmp="${CHANGELOG_FILE}.tmp.$$"
    if ! awk -v new_version="$NEW_VERSION" -v date_str="$(date +%Y-%m-%d)" -v msg="$MESSAGE" '
      !inserted && /^## \[/ {
        printf "## [%s] - %s\n\n- %s\n\n", new_version, date_str, msg
        inserted = 1
      }
      { print }
    ' "$CHANGELOG_FILE" > "$changelog_tmp"; then
      rm -f "$changelog_tmp"
      log "ERROR" "Failed to prepend to CHANGELOG.md."
      exit 1
    fi
    mv "$changelog_tmp" "$CHANGELOG_FILE"
    log "INFO" "Prepended to CHANGELOG.md."
  fi
else
  log "WARN" "CHANGELOG.md not found at $CHANGELOG_FILE"
fi

# Step 4: Git Commit
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
  git commit -m "bump: $NEW_VERSION - $MESSAGE"
  log "INFO" "Committed to git repository."
fi

log "INFO" "Bump ritual complete."
