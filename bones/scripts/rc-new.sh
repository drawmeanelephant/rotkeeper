#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
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
#  Version : 0.5.1
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
  --template "file.html" Override the configured default template
  --description "text"   Frontmatter description field
  --body "text"          Starting body content
  --url "https://..."    A URL to embed in the document (creates source skeleton)
  --subdir "path"        Directory under home/content/ to place the file
  --version, -v          Show script version and quit
  --help, -h             Show this help message and exit
  --dry-run              Preview actions without writing files
  --verbose              Enable detailed debug logging
EOF
  exit 0
}


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
rk_init_script "rc-new" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR CONTENT_DIR DOCS_DIR

set -euo pipefail
IFS=$'\n\t'




# --- Flag parsing ---
FILE=""
TITLE_OVERRIDE=""
AUTHOR_OVERRIDE=""
TAGS=""
TEMPLATE_OVERRIDE=""
DESCRIPTION=""
BODY_TEXT=""
SOURCE_URL=""
SUBDIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --verbose)
      VERBOSE=true
      QUIET=false
      shift
      ;;
    --help|-h)
      show_help
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

    if [[ ! "$FILE" == *.md && ! "$FILE" == *.textile && ! "$FILE" == *.cook ]]; then
        FILE="${FILE}.md"
    fi

    if [[ -n "$SUBDIR" ]]; then
        if [[ "$FILE" == /* ]]; then
            log "ERROR" "--subdir cannot be combined with an absolute filename"
            exit 1
        fi
        FILE="$SUBDIR/$FILE"
    fi

    if [[ "/$FILE/" == */../* ]]; then
        log "ERROR" "Filename and --subdir cannot contain parent-directory traversal"
        exit 1
    fi

    # Resolve the destination before creating it. This keeps nested filenames
    # under --subdir and rejects traversal instead of relying on substring checks.
    CONTENT_ROOT=$(rk_canonical_path "$CONTENT_DIR")
    if [[ "$FILE" == /* ]]; then
        FILE=$(rk_canonical_path "$FILE")
    else
        FILE=$(rk_canonical_path "$CONTENT_DIR/$FILE")
    fi
    if [[ "$FILE" != "$CONTENT_ROOT"/* ]]; then
        log "ERROR" "File must be created within $CONTENT_DIR"
        exit 1
    fi

    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$(dirname "$FILE")"
    fi

    if [[ -f "$FILE" ]]; then
        log "ERROR" "File already exists: $FILE"
        exit 1
    fi

    TITLE="${TITLE_OVERRIDE:-$(basename "$FILE" .md)}"
    if [[ "$TITLE" == *.textile ]]; then
        TITLE="${TITLE%.textile}"
    fi
    if [[ "$TITLE" == *.cook ]]; then
        TITLE="${TITLE%.cook}"
    fi
    if [[ -z "$TEMPLATE_OVERRIDE" ]]; then
        TEMPLATE_OVERRIDE=$(yq e '.default_template // "theme-spooky-dark.html"' "$CONFIG_DIR/rotkeeper.yaml" 2>/dev/null || echo "theme-spooky-dark.html")
    fi
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

    # Sanitize and escape double quotes for frontmatter strings
    SAFE_TITLE="${TITLE//\"/\\\"}"

    # Format-aware default heading: textile pages get h1., markdown pages get #,
    # cooklang recipes get none (Cooklang has no heading syntax — the recipe
    # body is the heading).
    DEFAULT_HEADING="# $TITLE"
    if [[ "$FILE" == *.textile ]]; then
        DEFAULT_HEADING="h1. $TITLE"
    elif [[ "$FILE" == *.cook ]]; then
        DEFAULT_HEADING=""
    fi

    BODY_STARTS_WITH_HEADING=false
    if [[ -n "$BODY_TEXT" && "$BODY_TEXT" =~ ^[[:space:]]*#+[[:space:]]+ ]]; then
        BODY_STARTS_WITH_HEADING=true
    fi

    # Handle multi-line and newline-containing descriptions via block scalar
    if [[ "$DESCRIPTION" == *$'\n'* ]] || [[ "$DESCRIPTION" == *'\n'* ]]; then
        # Format the description string: replace literal "\n" strings with actual newlines
        # then pad each line with two spaces for YAML block syntax
        FORMATTED_DESC="${DESCRIPTION//\\n/$'\n'}"
        DESC_BLOCK="description: |"$'\n'"$(printf '%s\n' "$FORMATTED_DESC" | sed 's/^/  /')"
    else
        SAFE_DESC="${DESCRIPTION//\"/\\\"}"
        DESC_BLOCK="description: \"${SAFE_DESC}\""
    fi

    if [[ "$DRY_RUN" == false ]]; then
        cat << EOF > "$FILE"
---
title: "${SAFE_TITLE}"
slug: $SLUG
template: $TEMPLATE_OVERRIDE
EOF

        if [[ -n "$DESCRIPTION" ]]; then
            echo "$DESC_BLOCK" >> "$FILE"
        fi

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
            if [[ "$BODY_STARTS_WITH_HEADING" == false && -n "$DEFAULT_HEADING" ]]; then
                echo "$DEFAULT_HEADING"
                echo ""
            fi

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
                elif [[ "$FILE" == *.cook ]]; then
                    echo "Add @ingredient#1 to the kettle. Simmer for ~5 minutes#. Serve."
                fi
            fi
        } >> "$FILE"

        log "INFO" "📄 Scaffolded new file at $FILE"
    else
        log "MARKER" "Would scaffold $FILE with title '$TITLE' and template '$TEMPLATE_OVERRIDE'"
    fi
}

main "$@"
