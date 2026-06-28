#!/usr/bin/env bash
# ============================================================
#  ██████╗ ███████╗███╗   ██╗██████╗ ███████╗██████╗
#  ██╔══██╗██╔════╝████╗  ██║██╔══██╗██╔════╝██╔══██╗
#  ██████╔╝█████╗  ██╔██╗ ██║██║  ██║█████╗  ██████╔╝
#  ██╔══██╗██╔══╝  ██║╚██╗██║██║  ██║██╔══╝  ██╔══██╗
#  ██║  ██║███████╗██║ ╚████║██████╔╝███████╗██║  ██║
#  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═╝  ╚═╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-render.sh
#  Purpose : Render markdown tombs into HTML using Pandoc and templates
#  Version : 0.4.0
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================
show_help() {
  cat << EOF
rc-render.sh — Render Markdown tombs into HTML (v0.3.1.4)

Usage: rc-render.sh [options]

Options:
  --version, -v    Show script version and quit
  --help, -h       Show this help message and exit
  --dry-run        Preview actions without invoking pandoc or archiving
  --verbose        Show detailed logs
EOF
  exit 0
}

source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
VERSION="${ROTKEEPER_VERSION:-0.3.1.4}"

rk_init_script "rc-render" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR CONTENT_DIR DOCS_DIR OUTPUT_DIR
set -euo pipefail
IFS=$'\n\t'




# ---
# main: The primary render ritual. Sweeps through home/content, applies pandoc templates,
# and outputs the final resting HTML forms into output/.
# ---
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
    CONFIG_FILE="$CONFIG_DIR/rotkeeper.yaml"
    MANIFEST="$BONES_DIR/manifest.txt"
    TEMPLATE_DIR="$TEMPLATE_DIR"

    log "INFO" "CONFIG_FILE=$CONFIG_FILE"
    log "INFO" "MANIFEST=$MANIFEST"
    log "INFO" "TEMPLATE_DIR=$TEMPLATE_DIR"

    # Debug available templates and default
    log "INFO" "Available templates: $(find "$TEMPLATE_DIR" -maxdepth 1 -type f -exec basename {} \; 2>/dev/null | tr '\n' ' ')"

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
    DEFAULT_TEMPLATE=$(yq e '.default_template' "$CONFIG_FILE" 2>/dev/null || echo "")
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
    log "INFO" "Available templates: $(find "$TEMPLATE_DIR" -maxdepth 1 -type f -exec basename {} \; 2>/dev/null | tr '\n' ' ')"

    # Verify templates directory exists
    if [[ ! -d "$TEMPLATE_DIR" ]]; then
      log "ERROR" "Templates directory not found: $TEMPLATE_DIR"
      exit 1
    fi

    [[ "$VERBOSE" == true ]] && echo "🖋 Rendering tombs..." >&2

    # Iterate over all markdown files in CONTENT_DIR, explicitly ignoring output/, bones/, and docs/
    while IFS= read -r mdfile; do
      [ -f "$mdfile" ] || continue

      [[ "$VERBOSE" == true ]] && log "DEBUG" "Found markdown file: $mdfile"
      base=$(basename "$mdfile" .md)
      mdpath=$(realpath "$mdfile")
      srcpath=$(realpath "$CONTENT_DIR")

      # Debug logging for path resolution
      [[ "$VERBOSE" == true ]] && {
        log "DEBUG" "mdfile=$mdfile"
        log "DEBUG" "mdpath=$mdpath"
        log "DEBUG" "srcpath=$srcpath"
      }

      # Harden relpath: ensure srcpath is a prefix of mdpath, and trim only if so
      if [[ "$mdpath" == "$srcpath"* ]]; then
        relpath="${mdpath#"$srcpath"/}"
      else
        log "ERROR" "mdpath $mdpath is not under srcpath $srcpath; skipping."
        continue
      fi

      # Debug relpath
      [[ "$VERBOSE" == true ]] && log "DEBUG" "relpath=$relpath"

      reldir=$(dirname "$relpath")
      outdir="$OUTPUT_DIR/$reldir"
      if [[ -z "$outdir" || "$outdir" =~ ^[[:space:]]*$ ]]; then
        log "WARN" "Invalid or empty output path for $mdfile — skipping."
        continue
      fi
      log "DEBUG" "Resolved outdir='$outdir'"
      run mkdir -p "$outdir"
      outfile="$outdir/${base}.html"
      rel_md="${mdpath#"$PROJ_ROOT"/}"
      rel_out="${outfile#"$PROJ_ROOT"/}"
      [[ "$VERBOSE" == true ]] && echo "📄 Rendering $rel_md → $rel_out"
      TEMPLATE=""
      TEMPLATE=$(yq --front-matter extract '.template' "$mdfile" 2>/dev/null | grep -v "^null$" || echo "")
      [[ -z "$TEMPLATE" ]] && TEMPLATE="$DEFAULT_TEMPLATE"

      log "INFO" "Rendering $rel_md with template: $TEMPLATE"

      if [ ! -f "$TEMPLATE_DIR/$TEMPLATE" ]; then
        echo "❌ ERROR: Template not found: $TEMPLATE_DIR/$TEMPLATE"
        continue
      fi
      run pandoc "$mdfile" --from markdown --to html --template="$TEMPLATE_DIR/$TEMPLATE" --lua-filter="$PROJ_ROOT/bones/scripts/rewrite-links.lua" -o "$outfile"
      pages_rendered=$((pages_rendered + 1))
      log_manifest "$outfile"
    done < <(find "$CONTENT_DIR" -type f -name "*.md" -print)
    [[ "$VERBOSE" == true ]] && echo "✅ Render complete." >&2

    # 📦 Archive the rendered output into a timestamped tar.gz tomb
    ARCHIVE_DIR="$ARCHIVE_DIR"
    mkdir -p "$ARCHIVE_DIR"
    TOMB="tomb-$(date +%Y-%m-%d_%H%M).tar.gz"
    run tar -czf "$ARCHIVE_DIR/$TOMB" -C "$PROJ_ROOT" "output"
    [[ "$VERBOSE" == true ]] && echo "📦 Archived rendered output to bones/archive/$TOMB" >&2
    log "INFO" "Archived output as bones/archive/$TOMB"

    # Compute and log summary
    end_ts=$(date +%s)
    duration=$((end_ts - start_ts))
    log "INFO" "Rendered $pages_rendered pages in ${duration}s"

    log "INFO" "rc-render.sh completed successfully."
}

main "$@"
