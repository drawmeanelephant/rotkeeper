#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-docs-fix.sh
# Purpose: Search, replace, and backup doc files based on given pattern
# Version: 0.1.9.9
# Updated: 2025-05-27
# -----------------------------------------
set -euo pipefail
IFS=$'\n\t'

# rc-docs-fix.sh — grep & fix your docs with automatic backup
# Usage: ./rc-docs-fix.sh --pattern PATTERN --replace REPLACEMENT [--dry-run]

# Defaults
DRY_RUN=false
BACKUP_ONLY=false
SEARCH_ONLY=false
PATTERN=
REPLACEMENT=

print_usage() {
  cat <<EOF
Usage: $0 --pattern PATTERN --replace REPLACEMENT [--dry-run]

Options:
  --pattern       Regex or literal string to search for
  --replace       Replacement string (must be quoted if contains spaces)
  --dry-run       Show what would change without writing files
  --backup-only   Only archive the docs without making any replacements
  --search-only   Perform search and log matches without applying replacements
EOF
}

parse_flags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --pattern)
        if [[ -n "${2:-}" ]]; then
          PATTERN="$2"
          shift 2
        else
          echo "Error: --pattern requires an argument"
          print_usage
          exit 1
        fi
        ;;
      --replace)
        if [[ -n "${2:-}" ]]; then
          REPLACEMENT="$2"
          shift 2
        else
          echo "Error: --replace requires an argument"
          print_usage
          exit 1
        fi
        ;;
      --dry-run) DRY_RUN=true; shift ;;
      --backup-only) BACKUP_ONLY=true; shift ;;
      --search-only) SEARCH_ONLY=true; shift ;;
      -h|--help) print_usage; exit ;;
      *) echo "Unknown arg: $1"; print_usage; exit 1 ;;
    esac
  done
}

init_log "rc-docs-fix"

main() {
    require_env_vars DOCS_DIR ARCHIVE_DIR LOG_DIR
    check_dependencies
    log "INFO" "Running rc-docs-fix.sh."
    parse_flags "$@"

    if [[ -z "$PATTERN" || -z "$REPLACEMENT" ]]; then
      echo "Error: --pattern and --replace are required"
      print_usage
      exit 1
    fi

    # Ensure docs/ exists, else skip or simulate for test safety
    if [[ ! -d "$DOCS_DIR" ]]; then
      log "WARN" "$DOCS_DIR folder not found. Skipping operations."
      if $DRY_RUN || $SEARCH_ONLY || $BACKUP_ONLY; then
        echo "Simulated: $DOCS_DIR folder not present; no operations performed."
        exit 0
      else
        exit 0
      fi
    fi

    TIMESTAMP=$(date +%Y%m%dT%H%M%S)
    BACKUP_NAME="docs_backup_$TIMESTAMP.tar.gz"
    BACKUP_PATH="$ARCHIVE_DIR/$BACKUP_NAME"

    echo "📦 Archiving $DOCS_DIR → $BACKUP_PATH"
    if $DRY_RUN; then
      echo "[DRY-RUN] Would archive $DOCS_DIR into $BACKUP_PATH"
    else
      tar czf "$BACKUP_PATH" "$DOCS_DIR"
    fi
    log "INFO" "Archived docs to $BACKUP_NAME"

    if $BACKUP_ONLY; then
      echo "✅ Backup-only mode: archive created at $BACKUP_PATH. Exiting."
      exit 0
    fi

    if $SEARCH_ONLY; then
      echo "🔍 Search-only mode: finding '$PATTERN'..."
      grep -RIn --exclude-dir=".git" "$PATTERN" "$DOCS_DIR" | tee -a "$LOG_FILE"
      echo "✅ Search logged to $LOG_FILE"
      exit 0
    fi

    echo "🔍 Searching for “$PATTERN”…"
    grep -RIn --exclude-dir=".git" "$PATTERN" "$DOCS_DIR" || echo "(no matches)"

    if $DRY_RUN; then
      echo "⚠️ Dry run: showing diffs only"
      MATCHES=$(grep -RIl --exclude-dir=".git" "$PATTERN" "$DOCS_DIR")
      if [[ -z "$MATCHES" ]]; then
        echo "(no matches)"
      else
        echo "$MATCHES" | xargs sed -n "s/$PATTERN/$REPLACEMENT/gp"
      fi
    else
      echo "🔧 Applying replacement: $PATTERN → $REPLACEMENT"
      if $DRY_RUN; then
        grep -RIl --exclude-dir=".git" "$PATTERN" "$DOCS_DIR" \
          | xargs -I{} echo "[DRY-RUN] Would replace in: {}"
      else
        grep -RIl --exclude-dir=".git" "$PATTERN" "$DOCS_DIR" \
          | xargs sed -i.bak "s/$PATTERN/$REPLACEMENT/g"
        echo "✅ Replacement complete. Backup of each file saved as *.bak"
      fi
    fi

    if $DRY_RUN; then
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] Dry-run replacement for pattern '$PATTERN' to '$REPLACEMENT'" >> "$LOG_FILE"
    else
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] Applied replacement: '$PATTERN' → '$REPLACEMENT'" >> "$LOG_FILE"
    fi

    echo "🎉 Done! Review $DOCS_DIR or remove *.bak files when you’re satisfied."
    log "INFO" "rc-docs-fix.sh completed successfully."
}

main "$@"
