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
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-bump.sh
#  Purpose : Automated microbump logging and version bumping workflow
#  Version : 0.5.0
# ------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
rk_init_script "rc-bump" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR

MESSAGE=""
COMMIT=false

show_help() {
  cat <<EOF
rc-bump.sh — Microbump Version Logging

Usage:
  rc-bump.sh [message] [options]

Options:
  --version, -v    Show script version and quit
  --message, -m MSG  The update message to log
  --dry-run          Preview changes without saving or committing
  --commit           Stage changes and commit them to git
  --verbose          Detailed output
  --help, -h         Show help
EOF
}

# Read the dispatcher version before parsing flags so --version is authoritative.
CURRENT_VERSION=$(grep -E '^VERSION="' "$ROOT_DIR/rotkeeper.sh" | cut -d'"' -f2)
if [[ -z "$CURRENT_VERSION" ]]; then
  log "ERROR" "Could not determine current version from rotkeeper.sh"
  exit 1
fi
VERSION="${ROTKEEPER_VERSION:-$CURRENT_VERSION}"

# Parse flags manually
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version|-v) echo "$(basename "$0") v${VERSION:-unknown}"; exit 0 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --commit) COMMIT=true; shift ;;
    --verbose) # shellcheck disable=SC2034
               VERBOSE=true; shift ;;
    --help|-h) show_help ;;
    --to) NEW_VERSION_OVERRIDE="$2"; shift 2 ;;
    --message|-m) MESSAGE="${2:-}"; shift 2 ;;
    -*) log "ERROR" "Unknown flag: $1"; show_help; exit 1 ;;
    *)
      if [[ -z "$MESSAGE" ]]; then
        MESSAGE="$1"
      else
        MESSAGE="$MESSAGE $1"
      fi

if [[ -n "$(git -C "$ROOT_DIR" status --porcelain 2>/dev/null)" ]]; then
  log "WARN" "Working tree is dirty. Proceeding with version bump, but be aware uncommitted changes exist."
fi
      shift
      ;;
  esac
done

if [[ -z "$MESSAGE" ]]; then
  log "ERROR" "No update message provided."
  show_help
  exit 1
fi

if [[ -n "$(git -C "$ROOT_DIR" status --porcelain 2>/dev/null)" ]]; then
  log "WARN" "Working tree is dirty. Proceeding with version bump, but be aware uncommitted changes exist."
fi

log "INFO" "Current version is $CURRENT_VERSION"

# Step 2: Bump the micro version
# Example: 0.3.0 -> 0.3.0.1
# Example: 0.3.0.1 -> 0.3.0.2
if [[ -n "${NEW_VERSION_OVERRIDE:-}" ]]; then
  NEW_VERSION="$NEW_VERSION_OVERRIDE"
elif [[ "$CURRENT_VERSION" =~ ^([0-9]+\.[0-9]+\.[0-9]+)\.([0-9]+)$ ]]; then
  BASE_VER="${BASH_REMATCH[1]}"
  MICRO="${BASH_REMATCH[2]}"
  NEW_MICRO=$((MICRO + 1))
  NEW_VERSION="${BASE_VER}.${NEW_MICRO}"
else
  # Treat as new micro branch
  NEW_VERSION="${CURRENT_VERSION}.1"
fi

log "INFO" "Bumping version to $NEW_VERSION"

# Step 3: Global File Replacements
if [[ "$DRY_RUN" == true ]]; then
  log "DRYRUN" "Would update scripts to $NEW_VERSION"
else
  for f in "$ROOT_DIR/rotkeeper.sh" "$SCRIPT_DIR"/*.sh; do
    awk -v old_ver="$CURRENT_VERSION" -v new_ver="$NEW_VERSION" '
      BEGIN {
        gsub(/\./, "\\.", old_ver)
      }
      {
        if ($0 ~ /^VERSION="\$\{ROTKEEPER_VERSION:-[0-9.]+\}"/) {
          sub(/^VERSION="\$\{ROTKEEPER_VERSION:-[0-9.]+\}"/, "VERSION=\"${ROTKEEPER_VERSION:-" new_ver "}\"")
        } else if ($0 ~ /^VERSION="[0-9.]+"/) {
          sub(/^VERSION="[0-9.]+"/, "VERSION=\"" new_ver "\"")
        } else if ($0 ~ /^#  Version : [0-9.]+/) {
          sub(/^#  Version : [0-9.]+/, "#  Version : " new_ver)
        } else if ($0 ~ /^# Version: [0-9.]+/) {
          sub(/^# Version: [0-9.]+/, "# Version: " new_ver)
        } else if ($0 ~ /\(v[0-9.]+\)/) {
          sub(/\(v[0-9.]+\)/, "(v" new_ver ")")
        }
        print
      }
    ' "$f" > "${f}.tmp" && mv "${f}.tmp" "$f" && chmod +x "$f"
  done
  log "INFO" "Updated version tags in all scripts."
fi

# Step 4: Inject into Living Buildlog
ROADMAP_FILE="$DOCS_DIR/road-to-bones/index.md"
DATE_STR=$(date +"%Y-%m-%d %H:%M")
ENTRY="* \`v$NEW_VERSION\` - ($DATE_STR) - $MESSAGE"

if [[ -f "$ROADMAP_FILE" ]]; then
  if [[ "$DRY_RUN" == true ]]; then
    log "DRYRUN" "Would inject into roadmap: $ENTRY"
  else
    # Inject after the anchor
    awk -v entry="$ENTRY" '
      /<!-- LIVING_BUILDLOG_START -->/ {
        print $0
        print entry
        next
      }
      {print}
    ' "$ROADMAP_FILE" > "$ROADMAP_FILE.tmp" && mv "$ROADMAP_FILE.tmp" "$ROADMAP_FILE"
    log "INFO" "Injected update into Living Buildlog."
  fi
else
  log "WARN" "Roadmap file not found: $ROADMAP_FILE"
fi

# Step 5: Append to CHANGELOG.md
CHANGELOG_FILE="$ROOT_DIR/CHANGELOG.md"
if [[ -f "$CHANGELOG_FILE" ]]; then
  if [[ "$DRY_RUN" == true ]]; then
    log "DRYRUN" "Would append to CHANGELOG.md"
  else
    echo -e "\n## [$NEW_VERSION] - $(date +%Y-%m-%d)\n- $MESSAGE" >> "$CHANGELOG_FILE"
    log "INFO" "Appended to CHANGELOG.md."
  fi
fi

# Step 6: Git Commit
if [[ "$DRY_RUN" == true ]]; then
  log "DRYRUN" "Would commit changes with message: bump: $NEW_VERSION - $MESSAGE"
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
git add "rotkeeper.sh"
git add "${SCRIPT_DIR#"$ROOT_DIR"/}/*.sh"
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
