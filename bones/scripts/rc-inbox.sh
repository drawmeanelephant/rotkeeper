#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-inbox.sh
# Purpose: Sort markdown debris by ritual destiny
# Version: 0.2.7-dev
# Updated: 2025-06-06
# -----------------------------------------------------------------------------

# Load environment paths and shared utilities
source "$(dirname "${BASH_SOURCE[0]}")/rc-env.sh"
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"

# Default inbox directory and dry-run toggle
INBOX_DIR="home/inbox"
DRY_RUN=false

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)
      INBOX_DIR="$2"  # Override inbox directory
      shift
      ;;
    --dry-run)
      DRY_RUN=true  # Enable dry-run mode
      ;;
    --help)
      # Show usage instructions
      echo "Usage: rc-inbox.sh [--dir path] [--dry-run]"
      echo "  --dir       Path to inbox folder (default: home/inbox)"
      echo "  --dry-run   Simulate actions without moving files"
      echo "  --help      Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
  shift
done

# Ensure inbox directory exists and prepare log
mkdir -p "$INBOX_DIR"
LOGFILE="bones/logs/rc-inbox-$(date +%Y-%m-%d_%H%M).log"
echo "# Rotkeeper Inbox Log — $(date)" > "$LOGFILE"
log "INFO" "Starting rc-inbox.sh on $INBOX_DIR"

# Abort if no markdown files found
if ! find "$INBOX_DIR" -type f -name "*.md" -print -quit | grep -q .; then
  log "INFO" "No markdown files found in inbox. Ritual postponed."
  exit 0
fi

# Begin processing each markdown file
find "$INBOX_DIR" -type f -name "*.md" | while read -r file; do
  log "INFO" "Processing: $file"

  # Extract and log status
  status=$(yq e '.status // ""' "$file" 2>/dev/null)
  log "DEBUG" "  status: $status"

  if [[ "$status" == "draft" ]]; then
    log "INFO" "  ↪ Skipped draft file"
    continue
  fi

  # Extract and log destination
  destination=$(yq e '.destination // ""' "$file" 2>/dev/null)
  log "DEBUG" "  destination: $destination"

  if [[ -n "$destination" ]]; then
    target_dir="home/content/$destination"
    log "DEBUG" "  resolved target_dir from destination: $target_dir"
  else
    # Fallback to template logic
    template=$(yq e '.template // ""' "$file" 2>/dev/null)
    log "DEBUG" "  fallback template: $template"
    case "$template" in
      rotkeeper-doc.html)
        target_dir="home/content/docs"
        ;;
      rotkeeper-blog.html)
        target_dir="home/content"
        ;;
      *)
        log "WARN" "  ↪ Unknown template: $template — file not moved"
        continue
        ;;
    esac
    log "DEBUG" "  resolved target_dir from template: $target_dir"
  fi

  # Determine final filename
  slug=$(yq e '.slug // ""' "$file" 2>/dev/null | tr -d '"')
  log "DEBUG" "  slug: $slug"

  if [[ -n "$slug" ]]; then
    filename="${slug}.md"
  else
    filename=$(basename "$file")
  fi

  dest="$target_dir/$filename"
  log "DEBUG" "  final destination path: $dest"

  # Ensure destination folder exists
  mkdir -p "$target_dir"

  # Simulate or execute file move
  if [[ "$DRY_RUN" == true ]]; then
    log "INFO" "  ↪ Would move to: $dest"
  else
    mv "$file" "$dest"
    log "INFO" "  ↪ Moved to: $dest"
  fi
done

# Final log message
log "INFO" "✅ Inbox processing complete."