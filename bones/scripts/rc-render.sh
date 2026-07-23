#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
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
#  Purpose : Render markdown tombs into HTML using Apex (default) or Pandoc
#  Version : 0.5.0
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================
show_help() {
  cat << EOF
rc-render.sh — Render Markdown tombs into HTML (v0.5.0)

Usage: rc-render.sh [options]

Options:
  --version, -v    Show script version and quit
  --help, -h       Show this help message and exit
  --dry-run        Preview actions without invoking renderer
  --verbose        Show detailed logs
  --renderer NAME  Select renderer: apex (default) or pandoc

Examples:
  bash rotkeeper.sh render
  RK_APEX_BIN=/path/to/apex bash rotkeeper.sh render --renderer apex
EOF
  exit 0
}

VERSION="${ROTKEEPER_VERSION:-0.5.0}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }

RENDERER="${RK_RENDERER:-apex}"

# Parse position-independent --renderer arguments
parse_render_args() {
  local args=("$@")
  local i=0
  while [[ $i -lt ${#args[@]} ]]; do
    local arg="${args[$i]}"
    case "$arg" in
      --renderer)
        if [[ $((i + 1)) -ge ${#args[@]} ]]; then
          log "ERROR" "--renderer requires an argument (pandoc or apex)"
          echo "ERROR: --renderer requires an argument." >&2
          exit 1
        fi
        RENDERER="${args[$((i + 1))]}"
        i=$((i + 2))
        ;;
      --renderer=*)
        RENDERER="${arg#*=}"
        i=$((i + 1))
        ;;
      *)
        i=$((i + 1))
        ;;
    esac
  done
}

parse_render_args "$@"
rk_init_script "rc-render" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR CONTENT_DIR DOCS_DIR OUTPUT_DIR
set -euo pipefail
IFS=$'\n\t'


# ---
# main: The primary render ritual. Sweeps through home/content, applies templates,
# and outputs the final resting HTML forms into output/.
# ---
main() {
    # Renderer-aware dependency validation
    case "${RENDERER,,}" in
      pandoc)
        check_dependencies
        require_bins pandoc
        ;;
      apex)
        APEX_BIN="${RK_APEX_BIN:-$(command -v apex || true)}"
        if [[ -z "$APEX_BIN" || ! -x "$APEX_BIN" ]]; then
          log "ERROR" "Apex renderer selected (--renderer apex), but RK_APEX_BIN is unset or not executable ($APEX_BIN)."
          echo "ERROR: Apex renderer selected, but RK_APEX_BIN is unset or not executable." >&2
          exit 1
        fi
        require_bins bash sha256sum
        require_yq_version
        require_gawk_version
        ;;
      *)
        log "ERROR" "Invalid renderer selected: '$RENDERER'. Supported options: pandoc, apex"
        echo "ERROR: Invalid renderer '$RENDERER'. Supported renderers: pandoc, apex" >&2
        exit 1
        ;;
    esac

    log "INFO" "Running rc-render.sh (Renderer: $RENDERER)."

    if [[ ! -d "$OUTPUT_DIR" ]] || [[ ! -f "$META_DIR/asset-manifest.yaml" ]]; then
      log "WARN" "Workspace may not be initialized. Run ./rotkeeper.sh init first if assets are missing."
      echo -e "\n⚠️  Warning: Workspace not initialized or missing core assets. Run './rotkeeper.sh init' first to avoid rendering issues.\n" >&2
    fi

    pages_rendered=0
    start_ts=$(date +%s)
    PROJ_ROOT="$ROOT_DIR"

    CONFIG_FILE="$CONFIG_DIR/rotkeeper.yaml"
    MANIFEST="$BONES_DIR/manifest.txt"
    TEMPLATE_DIR="$TEMPLATE_DIR"

    log "INFO" "CONFIG_FILE=$CONFIG_FILE"
    log "INFO" "MANIFEST=$MANIFEST"
    log "INFO" "TEMPLATE_DIR=$TEMPLATE_DIR"

    log_manifest() {
      local entry="$1"
      if [[ -n "$MANIFEST" && -f "$MANIFEST" ]]; then
        if ! grep -Fxq "$entry" "$MANIFEST"; then
          echo "$entry" >> "$MANIFEST"
        fi
      fi
    }

    if [[ ! -f "$CONFIG_FILE" ]]; then
      echo "❌ Missing config: $CONFIG_FILE"
      exit 1
    fi

    DEFAULT_TEMPLATE=$(yq e '.default_template' "$CONFIG_FILE" 2>/dev/null || echo "")
    if [[ -z "${DEFAULT_TEMPLATE:-}" ]]; then
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

    if [[ ! -d "$TEMPLATE_DIR" ]]; then
      log "ERROR" "Templates directory not found: $TEMPLATE_DIR"
      exit 1
    fi

    log "MARKER" "📄 Reanimating..."

    local render_sys_docs
    render_sys_docs=$(yq eval '.render_system_docs // true' "$CONFIG_FILE" 2>/dev/null || echo "true")

    log "INFO" "Evaluating layout scope (render_system_docs: $render_sys_docs)"

    local md_corpses=()

    if [[ "$render_sys_docs" == "false" ]]; then
        log "INFO" "Surgically pruning internal system docs and platform messages from user space."
        while IFS= read -r -d '' corpse; do
            md_corpses+=("$corpse")
        done < <(find "$CONTENT_DIR" \( -type d -a \( -name "docs" -o -name "messages" -o -name "help" \) -prune \) -o \( -type f -name "*.md" -print0 \))
    else
        while IFS= read -r -d '' corpse; do
            md_corpses+=("$corpse")
        done < <(find "$CONTENT_DIR" -type f -name "*.md" -print0)
    fi

    log "INFO" "Discovered ${#md_corpses[@]} markdown files for compilation."

    get_canonical_path() {
      local path="$1"
      local canonical_path
      canonical_path=$(realpath -m "$path" 2>/dev/null || readlink -f "$path" 2>/dev/null || echo "$path")
      echo "$canonical_path"
    }

    CANONICAL_CONTENT_DIR=$(get_canonical_path "$CONTENT_DIR")
    CANONICAL_META_DIR=$(get_canonical_path "$META_DIR")
    CANONICAL_TEMPLATE_DIR=$(get_canonical_path "$TEMPLATE_DIR")

    declare -A EXPECTED_OUTPUTS=()
    for mdfile in ${md_corpses[@]+"${md_corpses[@]}"}; do
      [ -f "$mdfile" ] || continue
      canonical_mdpath=$(get_canonical_path "$mdfile")
      [[ "$canonical_mdpath" == "$CANONICAL_CONTENT_DIR"* ]] || continue
      relpath="${canonical_mdpath#"$CANONICAL_CONTENT_DIR"/}"
      base=$(basename "$relpath" .md)
      reldir=$(dirname "$relpath")
      if [[ "$reldir" == "." ]]; then
        EXPECTED_OUTPUTS["$OUTPUT_DIR/$base.html"]=1
      else
        EXPECTED_OUTPUTS["$OUTPUT_DIR/$reldir/$base.html"]=1
      fi
    done

    while IFS= read -r -d '' stale_html; do
      if [[ -z "${EXPECTED_OUTPUTS[$stale_html]:-}" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
          log "DRY-RUN" "Would prune stale rendered page: $stale_html"
        else
          rm -f "$stale_html"
          log "INFO" "Pruned stale rendered page: $stale_html"
        fi
      fi
    done < <(find "$OUTPUT_DIR" -type f -name "*.html" -print0 2>/dev/null || true)

    if [[ "${RENDERER,,}" == "apex" ]]; then
      # --- APEX RENDERER PASS (PURE BASH / GAWK / YQ) ---
      local batch_tsv="$TMP_DIR/apex-batch-$$.tsv"
      rm -f "$batch_tsv"

      for mdfile in ${md_corpses[@]+"${md_corpses[@]}"}; do
        [ -f "$mdfile" ] || continue
        canonical_mdpath=$(get_canonical_path "$mdfile")
        [[ -n "$canonical_mdpath" && "$canonical_mdpath" == "$CANONICAL_CONTENT_DIR"* ]] || continue
        relpath="${canonical_mdpath#"$CANONICAL_CONTENT_DIR"/}"
        base=$(basename "$relpath" .md)
        reldir=$(dirname "$relpath")
        outdir="$OUTPUT_DIR/$reldir"
        outfile="$outdir/${base}.html"
        soul_file="$META_DIR/${relpath%.md}.soul.md"
        canonical_soul=$(get_canonical_path "$soul_file")
        if [[ "$canonical_soul" != "$CANONICAL_META_DIR"* ]]; then
          canonical_soul=""
        fi

        if [[ "$reldir" == "." ]]; then
          ASSETS_ROOT="./assets/"
        else
          depth=$(echo "$reldir" | tr -cd '/' | wc -c)
          ASSETS_ROOT=$(printf '../%.0s' $(seq 1 $((depth + 1))))"assets/"
        fi

        local soul_param="${canonical_soul:-NONE}"
        template_file="$TEMPLATE_DIR/$DEFAULT_TEMPLATE"
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
          "$canonical_mdpath" "$outfile" "$template_file" "$ASSETS_ROOT" "$soul_param" \
          "$APEX_BIN" "$ROOT_DIR" "$CANONICAL_CONTENT_DIR" "$OUTPUT_DIR" "$CANONICAL_TEMPLATE_DIR" \
          "$CANONICAL_META_DIR" "$DRY_RUN" "$VERBOSE" >> "$batch_tsv"
      done

      log "INFO" "Executing Apex batch adapter pass..."
      if [[ "$DRY_RUN" == true ]]; then
        log "DRY-RUN" "Would invoke bash $SCRIPT_DIR/rc-apex-adapter.sh $batch_tsv"
      else
        bash "$SCRIPT_DIR/rc-apex-adapter.sh" "$batch_tsv"
      fi

      for mdfile in ${md_corpses[@]+"${md_corpses[@]}"}; do
        [ -f "$mdfile" ] || continue
        canonical_mdpath=$(get_canonical_path "$mdfile")
        [[ -n "$canonical_mdpath" && "$canonical_mdpath" == "$CANONICAL_CONTENT_DIR"* ]] || continue
        relpath="${canonical_mdpath#"$CANONICAL_CONTENT_DIR"/}"
        base=$(basename "$relpath" .md)
        reldir=$(dirname "$relpath")
        outdir="$OUTPUT_DIR/$reldir"
        outfile="$outdir/${base}.html"
        pages_rendered=$((pages_rendered + 1))
        log_manifest "$outfile"
      done

      rm -f "$batch_tsv"
    else
      # --- PANDOC RENDERER PASS (DEFAULT) ---
      for mdfile in ${md_corpses[@]+"${md_corpses[@]}"}; do
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

        if [[ -f "$soul_file" ]]; then
          log "INFO" "💀 Found spiritual shadow sidecar: $soul_file"
          if ! yq eval '.' "$soul_file" >/dev/null 2>&1; then
            log "WARN" "Malformed YAML frontmatter in sidecar $soul_file. Dropping back to isolated pass."
            pandoc_inputs+=("$mdfile")
            TEMPLATE=$(yq --front-matter extract '.template' "$mdfile" 2>/dev/null | grep -v "^null$" || echo "")
          else
            pandoc_inputs+=("$mdfile" "$soul_file")
            TEMPLATE=$(yq --front-matter extract '.template' "$soul_file" 2>/dev/null | grep -v "^null$" || echo "")
            [[ -z "$TEMPLATE" ]] && TEMPLATE=$(yq --front-matter extract '.template' "$mdfile" 2>/dev/null | grep -v "^null$" || echo "")
          fi
        else
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

        # shellcheck disable=SC2086
        run pandoc ${pandoc_inputs[@]+"${pandoc_inputs[@]}"} --from markdown --to html --template="$canonical_template" --variable=assets_root="$ASSETS_ROOT" --lua-filter="$SCRIPT_DIR/rewrite-links.lua" -o "$outfile" $PANDOC_ARGS

        pages_rendered=$((pages_rendered + 1))
        log_manifest "$outfile"
      done
    fi

    log "MARKER" "✓ Exorcism complete."

    end_ts=$(date +%s)
    duration=$((end_ts - start_ts))
    log "INFO" "Rendered $pages_rendered pages in ${duration}s ($RENDERER)"

    log "INFO" "rc-render.sh completed successfully."
}

main "$@"
