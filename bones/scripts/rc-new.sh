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
#  Script  : rc-new.sh
#  Purpose : Scaffold a new markdown file with YAML frontmatter
#  Version : 0.3.0.19
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
rk_init_script "rc-new" "$@"

set -euo pipefail
IFS=$'\n\t'

show_help() {
  cat << EOF
rc-new.sh — Scaffold a new markdown file with required YAML frontmatter

Usage: rotkeeper.sh new <file>

Options:
  --help, -h       Show this help message and exit
  --dry-run        Preview actions without writing files
  --verbose        Enable detailed debug logging
EOF
  exit 0
}


# --- Flag parsing ---
FILE=""
for arg in "$@"; do
  case "$arg" in
    --dry-run|--verbose|--help|-h) ;; # handled by rk_init_script
    -*) log "ERROR" "Unknown flag: $arg"; exit 1 ;;
    *) 
      if [[ -z "$FILE" ]]; then
        FILE="$arg"
      else
        log "ERROR" "Multiple files specified. Usage: rotkeeper.sh new <file>"
        exit 1
      fi
      ;;
  esac
done

main() {
    if [[ -z "$FILE" ]]; then
      log "ERROR" "No file specified. Usage: rotkeeper.sh new <file>"
      exit 1
    fi

    if [[ ! "$FILE" == *.md ]]; then
        FILE="${FILE}.md"
    fi

    # Ensure it's in home/content
    if [[ "$FILE" != *"home/content/"* ]]; then
        if [[ "$FILE" == /* ]]; then
            # absolute path provided, check if it's within home/content
            if [[ "$FILE" != *"/home/content/"* ]]; then
                 log "ERROR" "File must be created within home/content/"
                 exit 1
            fi
        else
            FILE="home/content/$FILE"
        fi
    fi

    mkdir -p "$(dirname "$FILE")"

    if [[ -f "$FILE" ]]; then
        log "ERROR" "File already exists: $FILE"
        exit 1
    fi

    TITLE=$(basename "$FILE" .md)
    # slugify title
    SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9]/-/g' -e 's/-\+/-/g' -e 's/^-//' -e 's/-$//')

    if [[ "$DRY_RUN" == false ]]; then
        cat << EOF > "$FILE"
---
title: "$TITLE"
slug: $SLUG
template: rotkeeper-blog.html
description: "A brief description of this page."
---

# $TITLE

Write your markdown content here.
EOF
        log "INFO" "📄 Scaffolded new file at $FILE"
    else
        log "DRYRUN" "Would scaffold $FILE with title '$TITLE'"
    fi
}

main "$@"
