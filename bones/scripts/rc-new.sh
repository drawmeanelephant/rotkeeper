#!/usr/bin/env bash
# ============================================================
#  ███╗   ██╗███████╗██╗    ██╗
#  ████╗  ██║██╔════╝██║    ██║
#  ██╔██╗ ██║█████╗  ██║ █╗ ██║
#  ██║╚██╗██║██╔══╝  ██║███╗██║
#  ██║ ╚████║███████╗╚███╔███╔╝
#  ╚═╝  ╚═══╝╚══════╝ ╚══╝╚══╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-new.sh
#  Purpose : Scaffold a new markdown file with YAML frontmatter
#  Version : 0.4.0
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

show_help() {
  cat << EOF
rc-new.sh — Scaffold a new markdown file with required YAML frontmatter

Usage: rotkeeper.sh new <file>

Options:
  --title "Title"        Override auto-derived title; skip slug-from-filename
  --author "Name"        Override config-derived author
  --tags "tag1,tag2"     Comma-separated tags; rendered as YAML list
  --template "file.html" Override default rotkeeper-blog.html
  --description "text"   Frontmatter description field
  --body "text"          Starting body content
  --url "https://..."    A URL to embed in the document (creates source skeleton)
  --subdir "path"        Subdirectory under home/content/ to place the file
  --version, -v          Show script version and quit
  --help, -h             Show this help message and exit
  --dry-run              Preview actions without writing files
  --verbose              Enable detailed debug logging
EOF
  exit 0
}

source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
VERSION="${ROTKEEPER_VERSION:-0.3.1.4}"

rk_init_script "rc-new" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR CONTENT_DIR DOCS_DIR

set -euo pipefail
IFS=$'\n\t'




# --- Flag parsing ---
FILE=""
TITLE_OVERRIDE=""
AUTHOR_OVERRIDE=""
TAGS=""
TEMPLATE_OVERRIDE="rotkeeper-blog.html"
DESCRIPTION=""
BODY_TEXT=""
SOURCE_URL=""
SUBDIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run|--verbose|--help|-h)
      shift
      ;;
    --title)
      TITLE_OVERRIDE="$2"
      shift 2
      ;;
    --author)
      AUTHOR_OVERRIDE="$2"
      shift 2
      ;;
    --tags)
      TAGS="$2"
      shift 2
      ;;
    --template)
      TEMPLATE_OVERRIDE="$2"
      shift 2
      ;;
    --description)
      DESCRIPTION="$2"
      shift 2
      ;;
    --body)
      BODY_TEXT="$2"
      shift 2
      ;;
    --url)
      SOURCE_URL="$2"
      shift 2
      ;;
    --subdir)
      SUBDIR="$2"
      shift 2
      ;;
    -*)
      log "ERROR" "Unknown flag: $1"
      exit 1
      ;;
    *)
      if [[ -z "$FILE" ]]; then
        FILE="$1"
        shift
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

    if [[ -n "$SUBDIR" ]]; then
        if [[ "$FILE" == */* ]]; then
            log "WARN" "--subdir is ignored because a path was provided in the filename ($FILE)"
        else
            FILE="$SUBDIR/$FILE"
        fi
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

    TITLE="${TITLE_OVERRIDE:-$(basename "$FILE" .md)}"
    # slugify title
    SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9]/-/g' -e 's/-\+/-/g' -e 's/^-//' -e 's/-$//')

    AUTHOR="$AUTHOR_OVERRIDE"
    if [[ -z "$AUTHOR" ]]; then
        AUTHOR=$(yq e '.author // ""' "$CONFIG_DIR/rotkeeper.yaml" 2>/dev/null || echo "")
    fi

    TAGS_YAML=""
    if [[ -n "$TAGS" ]]; then
        TAGS_YAML="[${TAGS//,/, }]"
    fi

    if [[ "$DRY_RUN" == false ]]; then
        cat << EOF > "$FILE"
---
title: "$TITLE"
slug: $SLUG
template: $TEMPLATE_OVERRIDE
description: "${DESCRIPTION}"
EOF

        if [[ -n "$AUTHOR" ]]; then
            echo "author: \"$AUTHOR\"" >> "$FILE"
        fi

        if [[ -n "$TAGS_YAML" ]]; then
            echo "tags: $TAGS_YAML" >> "$FILE"
        fi

        if [[ -n "$SOURCE_URL" ]]; then
            echo "source_url: \"$SOURCE_URL\"" >> "$FILE"
        fi

        {
            echo "---"
            echo ""
            echo "# $TITLE"
            echo ""

            if [[ -n "$SOURCE_URL" ]]; then
                echo "## Source"
                echo ""
                echo "- **URL:** <$SOURCE_URL>"
                echo ""
                echo "## Notes"
                echo ""
                if [[ -n "$BODY_TEXT" ]]; then
                    echo "$BODY_TEXT"
                else
                    echo "<!-- Add your notes, observations, or excerpts here -->"
                fi
                echo ""
                echo "## Summary"
                echo ""
                echo "<!-- Add a summary, key points, or LLM-generated content here -->"
            else
                if [[ -n "$BODY_TEXT" ]]; then
                    echo "$BODY_TEXT"
                fi
            fi
        } >> "$FILE"

        log "INFO" "📄 Scaffolded new file at $FILE"
    else
        log "DRYRUN" "Would scaffold $FILE with title '$TITLE'"
    fi
}

main "$@"
