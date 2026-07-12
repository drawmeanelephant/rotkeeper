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
#  Version : 0.4.0.3
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
VERSION="${ROTKEEPER_VERSION:-0.4.0.3}"

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

    if [[ ! -d "$OUTPUT_DIR" ]] || [[ ! -f "$META_DIR/asset-manifest.yaml" ]]; then
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

    log "MARKER" "📄 Reanimating..."

    # Read layout scope isolation flags from centralized config
    local render_sys_docs
    render_sys_docs=$(yq eval '.render_system_docs // true' "$CONFIG_FILE" 2>/dev/null || echo "true")

    log "INFO" "Evaluating layout scope (render_system_docs: $render_sys_docs)"

    # Establish an array to collect markdown tombs non-destructively
    local md_corpses=()

    if [[ "$render_sys_docs" == "false" ]]; then
        log "INFO" "Surgically pruning internal system docs and platform messages from user space."
        # Use -prune to discard internal system architecture before walking files
        while IFS= read -r -d '' corpse; do
            md_corpses+=("$corpse")
        done < <(find "$CONTENT_DIR" \
            -type d \( -name "docs" -o -name "messages" -o -name "help" \) -prune \
            -o -type f -name "*.md" -print0)
    else
        while IFS= read -r -d '' corpse; do
            md_corpses+=("$corpse")
        done < <(find "$CONTENT_DIR" -type f -name "*.md" -print0)
    fi

    log "INFO" "Discovered ${#md_corpses[@]} markdown files for compilation."


    # Helper for canonicalization
    get_canonical_path() {
      local path="$1"
      local canonical_path
      canonical_path=$(realpath -m "$path" 2>/dev/null || readlink -f "$path" 2>/dev/null || python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$path" 2>/dev/null)
      if [[ -z "$canonical_path" ]]; then
        echo ""
      else
        echo "$canonical_path"
      fi
    }

    CANONICAL_CONTENT_DIR=$(get_canonical_path "$CONTENT_DIR")
    CANONICAL_META_DIR=$(get_canonical_path "$META_DIR")
    CANONICAL_TEMPLATE_DIR=$(get_canonical_path "$TEMPLATE_DIR")

    # Iterate over the safe compiled array instead of an open find subshell stream
    for mdfile in "${md_corpses[@]}"; do
      [ -f "$mdfile" ] || continue

      [[ "$VERBOSE" == true ]] && log "DEBUG" "Found markdown file: $mdfile"
      base=$(basename "$mdfile" .md)
      canonical_mdpath=$(get_canonical_path "$mdfile")
      if [[ -z "$canonical_mdpath" ]]; then
         log "ERROR" "Failed to resolve canonical path for $mdfile; skipping."
         continue
      fi
      if [[ "$canonical_mdpath" != "$CANONICAL_CONTENT_DIR"* ]]; then
         log "ERROR" "mdpath $canonical_mdpath escaped srcpath $CANONICAL_CONTENT_DIR; skipping."
         continue
      fi
      mdpath="$canonical_mdpath"
      srcpath="$CANONICAL_CONTENT_DIR"

      # Harden relpath: ensure srcpath is a prefix of mdpath
      if [[ "$mdpath" == "$srcpath"* ]]; then
        relpath="${mdpath#"$srcpath"/}"
      else
        log "ERROR" "mdpath $mdpath is not under srcpath $srcpath; skipping."
        continue
      fi

      reldir=$(dirname "$relpath")
      outdir="$OUTPUT_DIR/$reldir"
      if [[ -z "$outdir" || "$outdir" =~ ^[[:space:]]*$ ]]; then
        log "WARN" "Invalid or empty output path for $mdfile — skipping."
        continue
      fi

      run mkdir -p "$outdir"
      outfile="$outdir/${base}.html"
      rel_md="${mdpath#"$PROJ_ROOT"/}"
      rel_out="${outfile#"$PROJ_ROOT"/}"

      log "INFO" "Rendering $rel_md → $rel_out"

      # --- File-Level Sidecar Resolution ---
      # Map: home/content/path/file.md -> bones/meta/path/file.soul.md
      # Path traversal protection guard
      local soul_file="$META_DIR/${relpath%.md}.soul.md"

      local canonical_soul=$(get_canonical_path "$soul_file")
      if [[ -z "$canonical_soul" ]]; then
        log "ERROR" "Failed to resolve canonical path for soul_file $soul_file; skipping."
        continue
      fi
      if [[ "$canonical_soul" != "$CANONICAL_META_DIR"* ]]; then
        log "ERROR" "Path traversal detected in soul file path: $canonical_soul escapes $CANONICAL_META_DIR; skipping."
        continue
      fi
      soul_file="$canonical_soul"
      local pandoc_inputs=()

      # Track active inputs and extract the template target cleanly
      if [[ -f "$soul_file" ]]; then
        log "INFO" "💀 Found spiritual shadow sidecar: $soul_file"
        if ! yq eval '.' "$soul_file" >/dev/null 2>&1; then
          log "WARN" "Malformed YAML frontmatter in sidecar $soul_file. Dropping back to isolated pass."
          pandoc_inputs+=("$mdfile")
          TEMPLATE=$(yq --front-matter extract '.template' "$mdfile" 2>/dev/null | grep -v "^null$" || echo "")
        else
          # Sidecar-Dominance: pass the user document FIRST, sidecar SECOND.
          # Pandoc flattens the AST metadata in-memory, letting the sidecar stomp conflicts.
          pandoc_inputs+=("$mdfile" "$soul_file")

          # Read template from sidecar first; fall back to document if missing
          TEMPLATE=$(yq --front-matter extract '.template' "$soul_file" 2>/dev/null | grep -v "^null$" || echo "")
          [[ -z "$TEMPLATE" ]] && TEMPLATE=$(yq --front-matter extract '.template' "$mdfile" 2>/dev/null | grep -v "^null$" || echo "")
        fi
      else
        # Standard fallback pass
        pandoc_inputs+=("$mdfile")
        TEMPLATE=$(yq --front-matter extract '.template' "$mdfile" 2>/dev/null | grep -v "^null$" || echo "")
      fi

      [[ -z "$TEMPLATE" ]] && TEMPLATE="$DEFAULT_TEMPLATE"
      log "INFO" "Rendering $rel_md with template: $TEMPLATE"


      local template_file="$TEMPLATE_DIR/$TEMPLATE"
      local canonical_template=$(get_canonical_path "$template_file")
      if [[ -z "$canonical_template" ]]; then
        log "ERROR" "Failed to resolve canonical path for template $template_file; skipping."
        continue
      fi
      if [[ "$canonical_template" != "$CANONICAL_TEMPLATE_DIR"* ]]; then
        log "ERROR" "Path traversal detected in template path: $canonical_template escapes $CANONICAL_TEMPLATE_DIR; skipping."
        continue
      fi
      if [ ! -f "$canonical_template" ]; then
        log "ERROR" "Template not found: $canonical_template"
        continue
      fi

      if [[ "$reldir" == "." ]]; then
          ASSETS_ROOT="./assets/"
      else
          depth=$(echo "$reldir" | tr -cd '/' | wc -c)
          ASSETS_ROOT=$(printf '../%.0s' $(seq 1 $((depth + 1))))"assets/"
      fi

      PANDOC_ARGS=""
      if [[ "$DEBUG" == true ]]; then
        PANDOC_ARGS="--trace --dump-args --verbose"
      fi

      # Execute the zero-clutter in-memory aggregation pass
      # shellcheck disable=SC2086
      run pandoc "${pandoc_inputs[@]}"         --from markdown         --to html         --template="$canonical_template"         --variable=assets_root="$ASSETS_ROOT"         --lua-filter="$SCRIPT_DIR/rewrite-links.lua"         -o "$outfile" $PANDOC_ARGS

      pages_rendered=$((pages_rendered + 1))
      log_manifest "$outfile"
    done
    log "MARKER" "✓ Exorcism complete."


    # Compute and log summary
    end_ts=$(date +%s)
    duration=$((end_ts - start_ts))
    log "INFO" "Rendered $pages_rendered pages in ${duration}s"

    log "INFO" "rc-render.sh completed successfully."
}

main "$@"
