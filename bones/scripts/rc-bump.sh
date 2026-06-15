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
#  Script  : rc-bump.sh
#  Purpose : Automated microbump logging and version bumping workflow
#  Version : 0.3.0.12
# ------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/rc-utils.sh"

DRY_RUN=false
VERBOSE=false
HELP=false
MESSAGE=""

show_help() {
  cat <<EOF
rc-bump.sh — Microbump Version Logging

Usage:
  rc-bump.sh [message] [options]

Options:
  --message, -m MSG  The update message to log
  --dry-run          Preview changes without saving or committing
  --verbose          Detailed output
  --help, -h         Show help
EOF
}

# Parse flags manually
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --verbose) VERBOSE=true; shift ;;
    --help|-h) HELP=true; shift ;;
    --message|-m) MESSAGE="${2:-}"; shift 2 ;;
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

if [[ "$HELP" == true ]]; then
  show_help
  exit 0
fi

if [[ -z "$MESSAGE" ]]; then
  log "ERROR" "No update message provided."
  show_help
  exit 1
fi

init_log rc-bump
trap 'trap_err ${LINENO}' ERR

# Step 1: Read current version from rotkeeper.sh
CURRENT_VERSION=$(grep -E '^VERSION=' "$ROOT_DIR/rotkeeper.sh" | cut -d'"' -f2)

if [[ -z "$CURRENT_VERSION" ]]; then
  log "ERROR" "Could not determine current version from rotkeeper.sh"
  exit 1
fi

log "INFO" "Current version is $CURRENT_VERSION"

# Step 2: Bump the micro version
# Example: 0.3.0 -> 0.3.0.1
# Example: 0.3.0.1 -> 0.3.0.2
if [[ "$CURRENT_VERSION" =~ ^([0-9]+\.[0-9]+\.[0-9]+)\.([0-9]+)$ ]]; then
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
  # Using Python for a safe, reliable, cross-platform global replace
  python3 -c "
import os, glob

new_ver = '$NEW_VERSION'
old_ver = '$CURRENT_VERSION'
script_dir = '$SCRIPT_DIR'
root_dir = '$ROOT_DIR'

files = glob.glob(f'{script_dir}/*.sh') + [f'{root_dir}/rotkeeper.sh']

for f in files:
    with open(f, 'r') as file:
        content = file.read()
    
    # Replace VERSION string in rotkeeper.sh
    if f.endswith('rotkeeper.sh'):
        content = content.replace(f'VERSION=\"{old_ver}\"', f'VERSION=\"{new_ver}\"')
    
    # Replace # Version : string in headers
    content = content.replace(f'#  Version : {old_ver}', f'#  Version : {new_ver}')
    content = content.replace(f'# Version: {old_ver}', f'# Version: {new_ver}')
    
    # Replace in help text and debug prints
    content = content.replace(f'(v{old_ver})', f'(v{new_ver})')
    content = content.replace(f'v{old_ver}', f'v{new_ver}')

    with open(f, 'w') as file:
        file.write(content)
"
  log "INFO" "Updated version tags in all scripts."
fi

# Step 4: Inject into Living Buildlog
ROADMAP_FILE="$ROOT_DIR/home/content/docs/road-to-bones/index.md"
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
else
  cd "$ROOT_DIR"
  git add .
  git commit -m "bump: $NEW_VERSION - $MESSAGE"
  log "INFO" "Committed to git repository."
fi

log "INFO" "Bump ritual complete."
