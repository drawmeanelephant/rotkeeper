#!/usr/bin/env bash
# Source shared Rotkeeper helpers
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-render.sh
# Purpose: Renders markdown into HTML tombs using templates and config
# Version: 0.2.1
# Updated: 2025-05-29
# -----------------------------------------
# =============================================================================
# rc-render.sh — Pandoc-based renderer for Rotkeeper tombs
#
#   Markdown bones from content rise,
#   Styled by glyphs that archivists prize.
#   Pandoc breathes life into each ghostly frame,
#   HTML tombs now bear their name.
#
#   This script:
#   - Renders markdown into HTML using a configured template
#   - Uses render-flags.yaml to guide which content_dirs to process
#   - Automatically archives the rendered output into bones/archive/
# =============================================================================
set -euo pipefail
IFS=$'\n\t'

# --- Flag Parsing & Helpers ---
DRY_RUN=false
VERBOSE=false
HELP=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)   DRY_RUN=true; shift ;;
    --verbose)   VERBOSE=true; shift ;;
    --help|-h)   HELP=true; shift ;;
    *) break ;;
  esac
done

show_help() {
  cat << EOF
rc-render.sh — Render Markdown tombs into HTML (v0.2.1)

Usage: rc-render.sh [options]

Options:
  --help, -h       Show this help message and exit
  --dry-run        Preview actions without invoking pandoc or archiving
  --verbose        Show detailed logs
EOF
  exit 0
}

if [[ "$HELP" == true ]]; then
  show_help
fi

run() {
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "$*"
  else
    [[ "$VERBOSE" == true ]] && log "INFO" "$*"
    eval "$*"
  fi
}

# --- Log File Setup ---
SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPTDIR/../logs/rc-render-$(date '+%Y-%m-%d_%H%M%S').log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
  local level="$1"; shift
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  printf '[%s] [%s] %s\n' "$ts" "$level" "$*" | tee -a "$LOG_FILE"
}

cleanup() {
    log "INFO" "Cleaning up after rc-render.sh."
    # Add cleanup commands here
}
trap cleanup EXIT INT TERM

check_deps() {
    local deps=(git rsync ssh pandoc date awk grep find tar)
    for cmd in "${deps[@]}"; do
        command -v "$cmd" >/dev/null 2>&1 || {
            log "ERROR" "$cmd required but not installed."
            exit 1
        }
    done
}

main() {
    check_deps
    log "INFO" "Running rc-render.sh."

    # Initialize page counter and start time
    pages_rendered=0
    start_ts=$(date +%s)

    # Resolve project root (two levels up from script directory)
    PROJ_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

    # --- Paths ---
    CONFIG_FILE="$SCRIPTDIR/../config/render-flags.yaml"
    MANIFEST="$SCRIPTDIR/../manifest.txt"
    TEMPLATE_DIR="$PROJ_ROOT/bones/templates"

    log "INFO" "SCRIPTDIR=$SCRIPTDIR"
    log "INFO" "CONFIG_FILE=$CONFIG_FILE"
    log "INFO" "MANIFEST=$MANIFEST"
    log "INFO" "TEMPLATE_DIR=$TEMPLATE_DIR"

    # Debug available templates and default
    log "INFO" "Available templates: $(ls "$TEMPLATE_DIR" 2>/dev/null | tr '\n' ' ')"

    log_manifest() {
      local entry="$1"
      if [[ -n "$MANIFEST" && -f "$MANIFEST" ]]; then
        if ! grep -Fxq "$entry" "$MANIFEST"; then
          echo "$entry" >> "$MANIFEST"
        fi
      fi
    }

    # Parse config
    if [[ ! -f "$CONFIG_FILE" ]]; then
      echo "❌ Missing config: $CONFIG_FILE"
      exit 1
    fi

     # If no template is set in config, fallback to the first found in the templates directory
    DEFAULT_TEMPLATE=$(awk '/^default_template:/ { print $2 }' "$CONFIG_FILE")
    if [[ -z "${DEFAULT_TEMPLATE:-}" ]]; then
      # No default_template set; fallback to first template in TEMPLATE_DIR
      choices=()
      for tmpl in "$TEMPLATE_DIR"/*; do
        if [[ -f "$tmpl" ]]; then
          choices+=("$(basename "$tmpl")")
        fi
      done
      if [[ ${#choices[@]} -gt 0 ]]; then
        DEFAULT_TEMPLATE="${choices[0]}"
        log "WARN" "No default_template in config; falling back to first available template: $DEFAULT_TEMPLATE"
      else
        log "ERROR" "No templates found in $TEMPLATE_DIR; cannot proceed"
        exit 1
      fi
    fi
    log "INFO" "DEFAULT_TEMPLATE=$DEFAULT_TEMPLATE"
    log "INFO" "Available templates: $(ls "$TEMPLATE_DIR" 2>/dev/null | tr '\n' ' ')"

    # Parse render-flags.yaml to extract list of content_dirs
    CONTENT_DIRS=()
    in_content=0
    while read -r line; do
      [[ $in_content -eq 1 && "$line" =~ ^[[:space:]]*-[[:space:]]*(.+)$ ]] && CONTENT_DIRS+=("${BASH_REMATCH[1]}")
      [[ "$line" =~ ^content_dirs: ]] && in_content=1
      [[ $in_content -eq 1 && ! "$line" =~ ^[[:space:]]*-[[:space:]] ]] && [[ ! "$line" =~ ^content_dirs: ]] && in_content=0
    done < "$CONFIG_FILE"
    [[ ${#CONTENT_DIRS[@]} -eq 0 ]] && CONTENT_DIRS=("home/content")
    # Prefix content dirs with project root
    for idx in "${!CONTENT_DIRS[@]}"; do
      CONTENT_DIRS[$idx]="$PROJ_ROOT/${CONTENT_DIRS[$idx]}"
    done

    OUTPUT_DIR_REL=$(awk '/^output_dir:/ { print $2 }' "$CONFIG_FILE")
    [[ -z "$OUTPUT_DIR_REL" ]] && OUTPUT_DIR_REL="output"
    OUTPUT_DIR="$PROJ_ROOT/$OUTPUT_DIR_REL"

    mkdir -p "$OUTPUT_DIR"

    # Verify templates directory exists
    if [[ ! -d "$TEMPLATE_DIR" ]]; then
      log "ERROR" "Templates directory not found: $TEMPLATE_DIR"
      exit 1
    fi

    echo "🖋 Rendering tombs..." >&2

    # Iterate over all markdown files in content_dirs and convert to HTML
    for SRC in "${CONTENT_DIRS[@]}"; do
      [[ -d "$SRC" ]] || continue
      while IFS= read -r mdfile; do
        [ -f "$mdfile" ] || continue
        base=$(basename "$mdfile" .md)
        mdpath=$(realpath "$mdfile")
        srcpath=$(realpath "$SRC")
        relpath="${mdpath#$srcpath/}"
        reldir=$(dirname "$relpath")
        outdir="$OUTPUT_DIR/$reldir"
        mkdir -p "$outdir"
        outfile="$outdir/${base}.html"
        rel_md="${mdpath#$PROJ_ROOT/}"
        rel_out="${outfile#$PROJ_ROOT/}"
        echo "📄 Rendering $rel_md → $rel_out"
        if grep -q '^template:' "$mdfile"; then
          TEMPLATE=$(awk '/^template:/ { print $2 }' "$mdfile")
        fi
        [[ -z "$TEMPLATE" ]] && TEMPLATE="$DEFAULT_TEMPLATE"

        log "INFO" "Using template: $TEMPLATE"

        if [ ! -f "$TEMPLATE_DIR/$TEMPLATE" ]; then
          echo "❌ ERROR: Template not found: $TEMPLATE_DIR/$TEMPLATE"
          continue
        fi

        run "pandoc \"$mdfile\" --from markdown --to html --template=\"$TEMPLATE_DIR/$TEMPLATE\" -o \"$outfile\""
        pages_rendered=$((pages_rendered + 1))
        log_manifest "$outfile"
      done < <(find "$SRC" -type f -name "*.md")
    done
    echo "✅ Render complete." >&2

    # 📦 Archive the rendered output into a timestamped tar.gz tomb
    ARCHIVE_DIR="$PROJ_ROOT/bones/archive"
    mkdir -p "$ARCHIVE_DIR"
    TOMB="tomb-$(date +%Y-%m-%d_%H%M).tar.gz"
    run "tar -czf \"$ARCHIVE_DIR/$TOMB\" -C \"$PROJ_ROOT\" \"$OUTPUT_DIR_REL\""
    echo "📦 Archived rendered output to bones/archive/$TOMB" >&2
    log "INFO" "Archived output as bones/archive/$TOMB"

    # Compute and log summary
    end_ts=$(date +%s)
    duration=$((end_ts - start_ts))
    log "INFO" "Rendered $pages_rendered pages in ${duration}s"

    log "INFO" "rc-render.sh completed successfully."
}

main "$@"
