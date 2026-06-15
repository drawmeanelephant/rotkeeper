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
#  Script  : rc-render.sh
#  Purpose : Render markdown tombs into HTML using Pandoc and templates
#  Version : 0.3.0.9
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
set -euo pipefail
IFS=$'\n\t'

: "${DRY_RUN:=${RK_DRY:-false}}"
: "${VERBOSE:=${RK_VERBOSE:-false}}"
HELP=false

# --- Flag Parsing & Helpers ---
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
    "$@"
  fi
}

init_log "rc-render"

cleanup() {
    log "INFO" "Cleaning up after rc-render.sh."
    # Add cleanup commands here
}
trap cleanup EXIT INT TERM
trap 'trap_err $LINENO' ERR

main() {
    check_dependencies
    log "INFO" "Running rc-render.sh."

    if [[ ! -d "$ROOT_DIR/output" ]] || [[ ! -f "$ROOT_DIR/bones/asset-manifest.yaml" ]]; then
      log "WARN" "Workspace may not be initialized. Run ./rotkeeper.sh init first if assets are missing."
      echo -e "\n⚠️  Warning: Workspace not initialized or missing core assets. Run './rotkeeper.sh init' first to avoid rendering issues.\n" >&2
    fi

    # Initialize page counter and start time
    pages_rendered=0
    start_ts=$(date +%s)

    # Use ROOT_DIR from environment instead of recomputing
    PROJ_ROOT="$ROOT_DIR"

    # --- Paths ---
    CONFIG_FILE="$CONFIG_DIR/render-flags.yaml"
    MANIFEST="$BONES_DIR/manifest.txt"
    TEMPLATE_DIR="$TEMPLATE_DIR"

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

    [[ "$VERBOSE" == true ]] && echo "🖋 Rendering tombs..." >&2

    # Iterate over all markdown files in content_dirs and convert to HTML
    for SRC in "${CONTENT_DIRS[@]}"; do
      [[ -d "$SRC" ]] || continue
      while IFS= read -r mdfile; do
        [ -f "$mdfile" ] || continue
        # Skip recursive mirrorverse created by prior misrenders
        if [[ "$mdfile" == *"/docs/home/content/"* ]]; then
          log "WARN" "Skipping recursive mirrorverse: $mdfile"
          continue
        fi
        [[ "$VERBOSE" == true ]] && log "DEBUG" "Found markdown file: $mdfile"
        base=$(basename "$mdfile" .md)
        mdpath=$(realpath "$mdfile")
        srcpath=$(realpath "$SRC")
        # Debug logging for path resolution
        [[ "$VERBOSE" == true ]] && {
          log "DEBUG" "mdfile=$mdfile"
          log "DEBUG" "mdpath=$mdpath"
          log "DEBUG" "srcpath=$srcpath"
        }
        # Harden relpath: ensure srcpath is a prefix of mdpath, and trim only if so
        if [[ "$mdpath" == "$srcpath"* ]]; then
          relpath="${mdpath#$srcpath/}"
        else
          log "ERROR" "mdpath $mdpath is not under srcpath $srcpath; skipping."
          continue
        fi
        # Debug relpath
        [[ "$VERBOSE" == true ]] && log "DEBUG" "relpath=$relpath"
        # Sanity guard: detect recursive or malformed relpaths
        if [[ "$relpath" == *"content/"* && "$relpath" != *.md ]]; then
          log "ERROR" "Recursive relpath detected: $relpath"
          continue
        fi
        reldir=$(dirname "$relpath")
        outdir="$OUTPUT_DIR/$reldir"
        if [[ -z "$outdir" || "$outdir" =~ ^[[:space:]]*$ ]]; then
          log "WARN" "Invalid or empty output path for $rel_md — skipping."
          continue
        fi
        log "DEBUG" "Resolved outdir='$outdir'"
        run mkdir -p "$outdir"
        outfile="$outdir/${base}.html"
        rel_md="${mdpath#$PROJ_ROOT/}"
        rel_out="${outfile#$PROJ_ROOT/}"
        [[ "$VERBOSE" == true ]] && echo "📄 Rendering $rel_md → $rel_out"
        TEMPLATE=""
        if grep -q '^template:' "$mdfile"; then
          TEMPLATE=$(awk '/^template:/ { print $2 }' "$mdfile")
        fi
        [[ -z "$TEMPLATE" ]] && TEMPLATE="$DEFAULT_TEMPLATE"

        log "INFO" "Rendering $rel_md with template: $TEMPLATE"

        if [ ! -f "$TEMPLATE_DIR/$TEMPLATE" ]; then
          echo "❌ ERROR: Template not found: $TEMPLATE_DIR/$TEMPLATE"
          continue
        fi

        run pandoc "$mdfile" --from markdown --to html --template="$TEMPLATE_DIR/$TEMPLATE" -o "$outfile"
        pages_rendered=$((pages_rendered + 1))
        log_manifest "$outfile"
      done < <(find "$SRC" -type f -name "*.md")
    done
    [[ "$VERBOSE" == true ]] && echo "✅ Render complete." >&2

    # 📦 Archive the rendered output into a timestamped tar.gz tomb
    ARCHIVE_DIR="$ARCHIVE_DIR"
    mkdir -p "$ARCHIVE_DIR"
    TOMB="tomb-$(date +%Y-%m-%d_%H%M).tar.gz"
    run tar -czf "$ARCHIVE_DIR/$TOMB" -C "$PROJ_ROOT" "$OUTPUT_DIR_REL"
    [[ "$VERBOSE" == true ]] && echo "📦 Archived rendered output to bones/archive/$TOMB" >&2
    log "INFO" "Archived output as bones/archive/$TOMB"

    # Compute and log summary
    end_ts=$(date +%s)
    duration=$((end_ts - start_ts))
    log "INFO" "Rendered $pages_rendered pages in ${duration}s"

    log "INFO" "rc-render.sh completed successfully."
}

main "$@"
