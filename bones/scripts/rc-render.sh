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
#  Purpose : Render markdown tombs into HTML using Apex
#  Version : 0.5.1
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================
show_help() {
  cat << EOF
rc-render.sh — Render Markdown tombs into HTML (v$VERSION)

Usage: rc-render.sh [options]

Options:
  --version, -v    Show script version and quit
  --help, -h       Show this help message and exit
  --dry-run        Preview actions without invoking renderer
  --verbose        Show detailed logs
  --renderer NAME  Select renderer: apex (the only supported renderer; pandoc was removed)

Examples:
  bash rotkeeper.sh render
  RK_APEX_BIN=/path/to/apex bash rotkeeper.sh render --renderer apex
EOF
  exit 0
}


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
          log "ERROR" "--renderer requires an argument (apex)"
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
        log "ERROR" "The Pandoc renderer has been removed. Rotkeeper renders exclusively with Apex."
        echo "ERROR: The Pandoc renderer has been removed. Use --renderer apex (the default)." >&2
        exit 1
        ;;
      apex)
        APEX_BIN="${RK_APEX_BIN:-$(command -v apex || true)}"
        if [[ -z "$APEX_BIN" || ! -x "$APEX_BIN" ]]; then
          log "ERROR" "Apex renderer selected (--renderer apex), but RK_APEX_BIN is unset or not executable ($APEX_BIN)."
          # Surface the setup guidance on the caller's terminal (fd 3 is the
          # pre-log stdout kept by rk_init_script; fall back to stderr).
          if ! { cat >&3 <<'SETUP_EOF'
ERROR: Apex renderer selected, but no usable Apex binary was found.
Fix: install Apex, then point RK_APEX_BIN at the executable, e.g.:

    # Linux (x86_64/arm64) or macOS:
    # download from https://github.com/ApexMarkdown/apex/releases
    # and put the `apex` binary on your PATH, then:
    export RK_APEX_BIN=/path/to/apex
    bash rotkeeper.sh render --renderer apex

    # or just ensure `apex` is resolvable via PATH:
    command -v apex
SETUP_EOF
} 2>/dev/null; then
            echo "ERROR: Apex renderer selected, but RK_APEX_BIN is unset or not executable." >&2
          fi
          exit 1
        fi
        require_bins bash
        require_sha256
        require_yq_version
        require_gawk_version
        ;;
      *)
        log "ERROR" "Invalid renderer selected: '$RENDERER'. Supported options: apex"
        echo "ERROR: Invalid renderer '$RENDERER'. Supported renderers: apex" >&2
        exit 1
        ;;
    esac

    log "INFO" "Running rc-render.sh (Renderer: $RENDERER)."

    if [[ ! -d "$OUTPUT_DIR" ]] || { [[ ! -f "$BONES_DIR/asset-manifest.yaml" ]] && [[ ! -f "$META_DIR/asset-manifest.yaml" ]]; }; then
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
      local raw_entry="$1"
      local rel_entry="${raw_entry#"$ROOT_DIR"/}"
      if [[ -n "$MANIFEST" ]]; then
        mkdir -p "$(dirname "$MANIFEST")"
        touch "$MANIFEST"
        if ! grep -Fxq "$rel_entry" "$MANIFEST"; then
          echo "$rel_entry" >> "$MANIFEST"
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

    if output_is_generated; then
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
    else
        log "WARN" "Output tree is not marked generated; refusing to prune stale pages. A real render pass first writes the ownership marker."
    fi

    # Keep the output asset tree in sync with the source assets so every
    # rendered page's relative $assets_root$ link actually resolves.
    # Deferred to the real pass so --dry-run stays non-mutating.
    if [[ "$DRY_RUN" == true ]]; then
      log "DRY-RUN" "Would synchronize assets into the output tree."
    elif [[ -f "$SCRIPT_DIR/rc-assets.sh" ]]; then
      log "INFO" "Synchronizing assets into the output tree before rendering..."
      bash "$SCRIPT_DIR/rc-assets.sh"
    else
      log "WARN" "rc-assets.sh not found; skipping asset sync."
    fi

    if [[ "${RENDERER,,}" == "apex" ]]; then
      # --- APEX RENDERER PASS (PURE BASH / GAWK / YQ) ---
      mkdir -p "$TMP_DIR"
      local batch_tsv="$TMP_DIR/apex-batch-$$.tsv"
      rm -f "$batch_tsv"

      for mdfile in ${md_corpses[@]+"${md_corpses[@]}"}; do
        [ -f "$mdfile" ] || continue
        canonical_mdpath=$(get_canonical_path "$mdfile")
        [[ -n "$canonical_mdpath" && "$canonical_mdpath" == "$CANONICAL_CONTENT_DIR"* ]] || continue
        relpath="${canonical_mdpath#"$CANONICAL_CONTENT_DIR"/}"
        base=$(basename "$relpath" .md)
        reldir=$(dirname "$relpath")
        if [[ "$reldir" == "." ]]; then
          outdir="$OUTPUT_DIR"
        else
          outdir="$OUTPUT_DIR/$reldir"
        fi
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
          ASSETS_ROOT="$(rk_up_dirs $((depth + 1)))assets/"
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
        if [[ "$reldir" == "." ]]; then
          outdir="$OUTPUT_DIR"
        else
          outdir="$OUTPUT_DIR/$reldir"
        fi
        outfile="$outdir/${base}.html"
        pages_rendered=$((pages_rendered + 1))
        log_manifest "$outfile"
      done

      rm -f "$batch_tsv"
    fi

    mark_output_generated

    log "MARKER" "✓ Exorcism complete."

    end_ts=$(date +%s)
    duration=$((end_ts - start_ts))
    log "INFO" "Rendered $pages_rendered pages in ${duration}s ($RENDERER)"

    log "INFO" "rc-render.sh completed successfully."
}

main "$@"
