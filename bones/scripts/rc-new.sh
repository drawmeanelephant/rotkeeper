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
# Env assumptions: reads BONES_DIR, CONFIG_DIR, CONTENT_DIR, DOCS_DIR, DRY_RUN, LOG_DIR, META_DIR, QUIET, ROOT_DIR, SCRIPT_DIR, TEMPLATE_DIR, TMP_DIR, VERBOSE (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.
# CWD assumptions: No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.
# Input/Output contracts: CLI args and env vars in; files and stdout/stderr out; respects --dry-run (no writes) and --verbose.
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-new.sh
#  Purpose : Scaffold a new markdown file with YAML frontmatter
#  Version : 0.5.1
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

# @HELP
# rc-new.sh — Scaffold a new markdown file with required YAML frontmatter (v{VERSION})
#
# Usage:
#   rotkeeper.sh new <file> [options]
#   rotkeeper.sh new --list
#
# Description:
#   Creates a new markdown source with canonical YAML frontmatter under
#   home/content/, deriving title/slug defaults from the filename and
#   configuration.
#
# Options:
#   --title "Title"        Override auto-derived title; skip slug-from-filename
#   --author "Name"        Override config-derived author
#   --tags "tag1,tag2"     Comma-separated tags; rendered as YAML list
#   --template "file.html" Override the configured default template
#   --description "text"   Frontmatter description field
#   --body "text"          Starting body content
#   --url "https://..."    A URL to embed in the document (creates source skeleton)
#   --subdir "path"        Directory under home/content/ to place the file
#   --soul                 Also scaffold sidecar bones/meta/<path>.soul.md
#   --list                 List available templates and exit
#   --dry-run              Preview actions without writing files
#   --verbose              Enable detailed debug logging
#   --help, -h             Show this help message and exit
#   --version, -v          Show script version and quit
#
# Examples:
#   bash rotkeeper.sh new graveyard-shift                       Simple scaffold at content root
#   bash rotkeeper.sh new ember-report --subdir journal         Place under journal/
#   bash rotkeeper.sh new ember-report --title "Ember Report" --tags "news,ember" --dry-run
#
# Exit codes:
#   0    Success
#   1    Invalid usage or scaffold failure
# @END-HELP

# ---
# show_help: Print scaffold usage from the @HELP header block plus the runtime
# template completion hint — the only dynamic part of this ritual's help.
# Inputs: none (reads TEMPLATE_DIR, BONES_DIR)
# Outputs: Prints help to stdout and exits 0
# Env: Reads BONES_DIR, CONFIG_DIR, DRY_RUN, QUIET, ROOT_DIR, TEMPLATE_DIR ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
show_help() {
  # Static usage text lives in the @HELP header block (single sourced help);
  # only the runtime template completion hint is appended here.
  rk_show_help "$0"

  # List available templates for completion hint (safe for unbound vars before env load)
  local tmpl_list=""
  local palette_hint=""
  local td=""
  if [[ -n "${TEMPLATE_DIR:-}" && -d "$TEMPLATE_DIR" ]]; then
    td="$TEMPLATE_DIR"
    tmpl_list=""
    for _tmpl in "$td"/*.html; do
      [[ -e "$_tmpl" ]] || continue
      tmpl_list+="$(basename "$_tmpl") "
    done
  elif [[ -n "${BONES_DIR:-}" && -d "$BONES_DIR/templates" ]]; then
    td="$BONES_DIR/templates"
    tmpl_list=""
    for _tmpl in "$td"/*.html; do
      [[ -e "$_tmpl" ]] || continue
      tmpl_list+="$(basename "$_tmpl") "
    done
  elif [[ -n "${ROOT_DIR:-}" && -d "${ROOT_DIR}/bones/templates" ]]; then
    td="${ROOT_DIR}/bones/templates"
    tmpl_list=""
    for _tmpl in "$td"/*.html; do
      [[ -e "$_tmpl" ]] || continue
      tmpl_list+="$(basename "$_tmpl") "
    done
  fi
  # Check if any template uses $palette$ for hint
  # shellcheck disable=SC2016
  if [[ -n "${TEMPLATE_DIR:-}" && -d "${TEMPLATE_DIR:-}" ]] && grep -q '\$palette\$' "$TEMPLATE_DIR"/*.html 2>/dev/null; then
    palette_hint=" (templates with \$palette\$ support palette flag)"
  elif [[ -n "${BONES_DIR:-}" ]] && grep -q '\$palette\$' "$BONES_DIR/templates"/*.html 2>/dev/null; then
    palette_hint=" (templates with \$palette\$ support palette flag)"
  elif [[ -n "${ROOT_DIR:-}" ]] && grep -q '\$palette\$' "${ROOT_DIR}"/bones/templates/*.html 2>/dev/null; then
    palette_hint=" (templates with \$palette\$ support palette flag)"
  fi

  if [[ -n "$tmpl_list" ]]; then
    echo
    echo "Available templates: $tmpl_list$palette_hint"
  fi
  exit 0
}

# ---
# list_templates: List available templates with default marker.
# Inputs: none (reads TEMPLATE_DIR, CONFIG_DIR)
# Outputs: Prints template names to MARKER log
# Env: Reads BONES_DIR, CONFIG_DIR, CONTENT_DIR, DOCS_DIR, DRY_RUN, LOG_DIR ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
list_templates() {
  local td="${TEMPLATE_DIR:-$BONES_DIR/templates}"
  [[ -d "$td" ]] || td="$BONES_DIR/templates"
  local default_tmpl
  default_tmpl=$(yq e '.default_template // "theme-spooky-dark.html"' "$CONFIG_DIR/rotkeeper.yaml" 2>/dev/null || echo "theme-spooky-dark.html")
  local found=false
  for tmpl in "$td"/*.html; do
    [[ -f "$tmpl" ]] || continue
    found=true
    local base
    base=$(basename "$tmpl")
    local marker=""
    [[ "$base" == "$default_tmpl" ]] && marker=" (default)"
    local desc=""
    # One-line description from first HTML comment if present
    desc=$(head -n 5 "$tmpl" 2>/dev/null | grep -m1 -E "<!--.*-->" | sed -E 's/.*<!-- *//; s/ *-->.*//' | cut -c1-60 || true)
    if [[ -n "$desc" ]]; then
      log "MARKER" "$base$marker — $desc"
    else
      log "MARKER" "$base$marker"
    fi
    # Palette hint
    # shellcheck disable=SC2016
    if grep -q '\$palette\$' "$tmpl" 2>/dev/null; then
      log "MARKER" "  supports \$palette\$"
    fi
  done
  if [[ "$found" == false ]]; then
    log "MARKER" "No templates found in $td"
  fi
}


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
rk_init_script "rc-new" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR CONTENT_DIR DOCS_DIR




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
WITH_SOUL=false
LIST_MODE=false

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
    --list)
      LIST_MODE=true
      shift
      ;;
    --soul)
      WITH_SOUL=true
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

# Handle --list and no-args (UX win: list templates instead of error)
if [[ "$LIST_MODE" == true ]]; then
  list_templates
  exit 0
fi
if [[ -z "$FILE" ]]; then
  list_templates
  log "MARKER" "Usage: rotkeeper.sh new <file> [--template file.html] [--soul]"
  log "MARKER" "  e.g. rotkeeper.sh new my-page.md --template theme-spooky-dark.html"
  exit 0
fi

# ---
# main: Scaffold a new content file with frontmatter and optional sidecar.
# Inputs: none (reads FILE, TITLE_OVERRIDE, TEMPLATE_OVERRIDE, DRY_RUN, etc.)
# Outputs: Creates file under CONTENT_DIR; optionally creates META_DIR sidecar
# Env: Reads CONFIG_DIR, CONTENT_DIR, DRY_RUN, FILE, TEMPLATE_OVERRIDE, TITLE_OVERRIDE (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
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
        # SIDE EFFECT (write): creates the target directory under content/ if missing
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
        IFS=',' read -ra TAG_ITEMS <<< "$TAGS"
        for tag in ${TAG_ITEMS[@]+"${TAG_ITEMS[@]}"}; do
            tag="${tag#"${tag%%[![:space:]]*}"}"
            tag="${tag%"${tag##*[![:space:]]}"}"
            safe_tag="${tag//\\/\\\\}"
            safe_tag="${safe_tag//\"/\\\"}"
            if [[ -z "$TAGS_YAML" ]]; then
                TAGS_YAML="\"$safe_tag\""
            else
                TAGS_YAML="$TAGS_YAML, \"$safe_tag\""
            fi
        done
        TAGS_YAML="[$TAGS_YAML]"
    fi

    # Sanitize and escape double quotes for frontmatter strings
    SAFE_TITLE="${TITLE//\\/\\\\}"
    SAFE_TITLE="${SAFE_TITLE//\"/\\\"}"

    # Format-aware default heading: textile pages get h1., markdown pages get #,
    # cooklang recipes get none (Cooklang has no heading syntax — the recipe
    # body is the heading). IS_COOK is hoisted before the write block so the
    # body emission never reads $FILE while appending to it (SC2094).
    DEFAULT_HEADING="# $TITLE"
    IS_COOK=false
    if [[ "$FILE" == *.textile ]]; then
        DEFAULT_HEADING="h1. $TITLE"
    elif [[ "$FILE" == *.cook ]]; then
        DEFAULT_HEADING=""
        IS_COOK=true
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
        SAFE_DESC="${DESCRIPTION//\\/\\\\}"
        SAFE_DESC="${SAFE_DESC//\"/\\\"}"
        DESC_BLOCK="description: \"${SAFE_DESC}\""
    fi

    if [[ "$DRY_RUN" == false ]]; then
        # SIDE EFFECT (write): creates the new content page (frontmatter + body appended below);
        # earlier existence check guarantees this never overwrites an existing file
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
            SAFE_AUTHOR="${AUTHOR//\\/\\\\}"
            SAFE_AUTHOR="${SAFE_AUTHOR//\"/\\\"}"
            echo "author: \"$SAFE_AUTHOR\"" >> "$FILE"
        fi

        if [[ -n "$TAGS_YAML" ]]; then
            echo "tags: $TAGS_YAML" >> "$FILE"
        fi

        if [[ -n "$SOURCE_URL" ]]; then
            SAFE_SOURCE_URL="${SOURCE_URL//\\/\\\\}"
            SAFE_SOURCE_URL="${SAFE_SOURCE_URL//\"/\\\"}"
            echo "source_url: \"$SAFE_SOURCE_URL\"" >> "$FILE"
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
                elif [[ "$IS_COOK" == true ]]; then
                    echo "Add @ingredient#1 to the kettle. Simmer for ~5 minutes#. Serve."
                fi
            fi
        } >> "$FILE"

        # Handle --soul sidecar
        soul_msg=""
        if [[ "$WITH_SOUL" == true ]]; then
            # shellcheck disable=SC2295
            rel_path="${FILE#$CONTENT_ROOT/}"
            # Use get_sidecar_path for canonical sidecar location (handles traversal)
            soul_file=$(get_sidecar_path "$rel_path" 2>/dev/null || echo "")
            if [[ -z "$soul_file" || "$soul_file" == *"null.soul.md"* ]]; then
                # Fallback: META_DIR/rel_no_ext.soul.md
                rel_no_ext="${rel_path%.*}"
                # Handle .textile and .cook extensions which are longer than .md
                case "$rel_path" in
                    *.textile) rel_no_ext="${rel_path%.textile}" ;;
                    *.cook) rel_no_ext="${rel_path%.cook}" ;;
                    *) rel_no_ext="${rel_path%.*}" ;;
                esac
                soul_file="$META_DIR/${rel_no_ext}.soul.md"
            fi
            if [[ -f "$soul_file" ]]; then
                log "WARN" "Sidecar already exists: $soul_file"
            else
                # SIDE EFFECT (write): creates bones/meta/<rel>.soul.md sidecar scaffold
                mkdir -p "$(dirname "$soul_file")"
                soul_author="${AUTHOR:-$(yq e '.author // ""' "$CONFIG_DIR/rotkeeper.yaml" 2>/dev/null || echo "")}"
                soul_date=$(date +%Y-%m-%d)
                cat << SOUL_EOF > "$soul_file"
---
title: "${SAFE_TITLE}"
author: "${soul_author}"
date: "$soul_date"
---

Notes for \`$rel_path\` — add context, warnings, or DIP notes here.

SOUL_EOF
                # shellcheck disable=SC2295
                rel_soul="${soul_file#$ROOT_DIR/}"
                soul_msg=" + soul $rel_soul"
                log "INFO" "Scaffolded sidecar at $soul_file"
            fi
        fi

        # shellcheck disable=SC2295
        rel_file="${FILE#$ROOT_DIR/}"
        log "MARKER" "✓ scaffolded $rel_file — template $TEMPLATE_OVERRIDE$soul_msg — next: edit frontmatter, then bash rotkeeper.sh render"
    else
        # shellcheck disable=SC2295
        rel_file="${FILE#$ROOT_DIR/}"
        if [[ "$WITH_SOUL" == true ]]; then
            # shellcheck disable=SC2295
            rel_path="${FILE#$CONTENT_ROOT/}"
            rel_no_ext="${rel_path%.*}"
            case "$rel_path" in
                *.textile) rel_no_ext="${rel_path%.textile}" ;;
                *.cook) rel_no_ext="${rel_path%.cook}" ;;
                *) rel_no_ext="${rel_path%.*}" ;;
            esac
            soul_file="$META_DIR/${rel_no_ext}.soul.md"
            # shellcheck disable=SC2295
            rel_soul="${soul_file#$ROOT_DIR/}"
            log "MARKER" "Would scaffold $rel_file with title '$TITLE' and template '$TEMPLATE_OVERRIDE' + soul $rel_soul"
        else
            log "MARKER" "Would scaffold $rel_file with title '$TITLE' and template '$TEMPLATE_OVERRIDE'"
        fi
    fi
}

main "$@"
