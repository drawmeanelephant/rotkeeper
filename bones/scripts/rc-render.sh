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
#  Purpose : Render markdown tombs into HTML using Oliver
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
  --renderer NAME  Select renderer: oliver (the only supported renderer; pandoc was removed)

Examples:
  bash rotkeeper.sh render
  RK_OLIVER_BIN=/path/to/oliver bash rotkeeper.sh render --renderer oliver
EOF
  exit 0
}


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }

RENDERER="${RK_RENDERER:-oliver}"

# Parse position-independent --renderer arguments
parse_render_args() {
  local args=("$@")
  local i=0
  while [[ $i -lt ${#args[@]} ]]; do
    local arg="${args[$i]}"
    case "$arg" in
      --renderer)
        if [[ $((i + 1)) -ge ${#args[@]} ]]; then
          log "ERROR" "--renderer requires an argument (oliver)"
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
        log "ERROR" "The Pandoc renderer has been removed. Rotkeeper renders exclusively with Oliver."
        echo "ERROR: The Pandoc renderer has been removed. Use --renderer oliver (the default)." >&2
        exit 1
        ;;
      oliver)
        if ! rk_oliver_preflight; then
          # rk_oliver_preflight already printed Tried: ... + Fix: ... to fd 3 (visible even in QUIET)
          # Surface a concise, copy-pasteable hint also via MARKER for the render context
          tried_rk="${RK_OLIVER_BIN:-unset}"
          tried_path="$(command -v oliver 2>/dev/null || echo none)"
          log "MARKER" "✗ Render aborted: Oliver preflight failed — Tried: RK_OLIVER_BIN=$tried_rk, PATH oliver=$tried_path"
          log "ERROR" "Render aborted: Oliver preflight failed — Tried: RK_OLIVER_BIN=$tried_rk, PATH oliver=$tried_path — try: export RK_OLIVER_BIN=/usr/local/bin/oliver or ensure 'oliver' is on PATH"
          echo "ERROR: Render aborted: Oliver preflight failed. Tried: RK_OLIVER_BIN=$tried_rk, PATH oliver=$tried_path — try: export RK_OLIVER_BIN=/usr/local/bin/oliver" >&2
          echo "Run 'bash rotkeeper.sh preflight' for full diagnosis (see home/content/docs/oliver-contract.md)." >&2
          exit 1
        fi
        require_bins bash
        require_sha256
        require_yq_version
        require_gawk_version
        ;;
      *)
        log "ERROR" "Invalid renderer selected: '$RENDERER'. Supported options: oliver"
        echo "ERROR: Invalid renderer '$RENDERER'. Supported renderers: oliver" >&2
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
    log "INFO" "INPUT_FORMAT=$INPUT_FORMAT"

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
        done < <(find "$CONTENT_DIR" \( -type d -a \( -name "docs" -o -name "messages" -o -name "help" \) -prune \) -o \( -type f \( -name "*.md" -o -name "*.textile" -o -name "*.cook" \) -print0 \))
    else
        while IFS= read -r -d '' corpse; do
            md_corpses+=("$corpse")
        done < <(find "$CONTENT_DIR" -type f \( -name "*.md" -o -name "*.textile" -o -name "*.cook" \) -print0)
    fi

    log "INFO" "Discovered ${#md_corpses[@]} source files for compilation."

    get_canonical_path() {
      local path="$1"
      local canonical_path
      canonical_path=$(realpath -m "$path" 2>/dev/null || readlink -f "$path" 2>/dev/null || echo "$path")
      echo "$canonical_path"
    }

    strip_source_ext() {
      # Source extensions are .md, .textile, and .cook; anything else passes
      # through untouched so a misnamed source fails loudly rather than silently.
      case "$1" in
        *.md) printf '%s' "${1%.md}" ;;
        *.textile) printf '%s' "${1%.textile}" ;;
        *.cook) printf '%s' "${1%.cook}" ;;
        *) printf '%s' "$1" ;;
      esac
    }

    CANONICAL_CONTENT_DIR=$(get_canonical_path "$CONTENT_DIR")
    CANONICAL_META_DIR=$(get_canonical_path "$META_DIR")
    CANONICAL_TEMPLATE_DIR=$(get_canonical_path "$TEMPLATE_DIR")

    declare -A EXPECTED_OUTPUTS=()
    declare -A OUTPUT_SOURCES=()
    for mdfile in ${md_corpses[@]+"${md_corpses[@]}"}; do
      [ -f "$mdfile" ] || continue
      canonical_mdpath=$(get_canonical_path "$mdfile")
      [[ "$canonical_mdpath" == "$CANONICAL_CONTENT_DIR"* ]] || continue
      relpath="${canonical_mdpath#"$CANONICAL_CONTENT_DIR"/}"
      base=$(strip_source_ext "$(basename "$relpath")")
      reldir=$(dirname "$relpath")
      if [[ "$reldir" == "." ]]; then
        outkey="$OUTPUT_DIR/$base.html"
      else
        outkey="$OUTPUT_DIR/$reldir/$base.html"
      fi
      if [[ -n "${OUTPUT_SOURCES[$outkey]:-}" && "${OUTPUT_SOURCES[$outkey]}" != "$relpath" ]]; then
        log "ERROR" "Source basename collision in '$reldir': '${OUTPUT_SOURCES[$outkey]}' and '$relpath' both map to page '$base.html'. Only one source file may exist per page basename (foo.md vs foo.textile vs foo.cook)."
        echo "ERROR: Source basename collision: '${OUTPUT_SOURCES[$outkey]}' and '$relpath' both map to page '$base.html'. Rename or remove one." >&2
        exit 1
      fi
      EXPECTED_OUTPUTS[$outkey]=1
      OUTPUT_SOURCES[$outkey]="$relpath"
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

    if [[ "${RENDERER,,}" == "oliver" ]]; then
      # --- OLIVER RENDERER PASS (PURE BASH / GAWK / YQ) ---
      mkdir -p "$TMP_DIR"
      local batch_tsv="$TMP_DIR/oliver-batch-$$.tsv"
      rm -f "$batch_tsv"

      for mdfile in ${md_corpses[@]+"${md_corpses[@]}"}; do
        [ -f "$mdfile" ] || continue
        canonical_mdpath=$(get_canonical_path "$mdfile")
        [[ -n "$canonical_mdpath" && "$canonical_mdpath" == "$CANONICAL_CONTENT_DIR"* ]] || continue
        relpath="${canonical_mdpath#"$CANONICAL_CONTENT_DIR"/}"
        base=$(strip_source_ext "$(basename "$relpath")")
        reldir=$(dirname "$relpath")
        if [[ "$reldir" == "." ]]; then
          outdir="$OUTPUT_DIR"
        else
          outdir="$OUTPUT_DIR/$reldir"
        fi
        outfile="$outdir/${base}.html"
        soul_file="$META_DIR/$(strip_source_ext "$relpath").soul.md"
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
          "$OLIVER_BIN" "$ROOT_DIR" "$CANONICAL_CONTENT_DIR" "$OUTPUT_DIR" "$CANONICAL_TEMPLATE_DIR" \
          "$CANONICAL_META_DIR" "$DRY_RUN" "$VERBOSE" >> "$batch_tsv"
      done

      log "INFO" "Executing Oliver batch adapter pass..."
      if [[ "$DRY_RUN" == true ]]; then
        log "DRY-RUN" "Would invoke bash $SCRIPT_DIR/rc-oliver-adapter.sh $batch_tsv"
      else
        set +e
        bash "$SCRIPT_DIR/rc-oliver-adapter.sh" "$batch_tsv"
        adapter_status=$?
        set -e
        if [[ $adapter_status -ne 0 ]]; then
          log "MARKER" "✗ Render failed — Oliver adapter exited $adapter_status"
          # Surface first error line for copy-paste (prefer ✗ MARKER from either log)
          # Adapter's MARKER via >&3 lands in render's LOG_FILE, not adapter's; check both.
          # shellcheck disable=SC2012
          latest_adapter_log=$(ls -t "$LOG_DIR"/rc-oliver-adapter-*.log 2>/dev/null | head -n1 || true)
          first_err=""
          # Prefer render's own log (contains adapter's >&3 MARKER) then adapter's log
          # Use ASCII pattern "Oliver failed" to avoid UTF-8 ✗ matching issues in C locale
          if [[ -f "${LOG_FILE:-}" ]]; then
            first_err=$(grep -a -m1 "Oliver failed" "$LOG_FILE" 2>/dev/null | head -n1 || true)
          fi
          if [[ -z "$first_err" && -n "$latest_adapter_log" && -f "$latest_adapter_log" ]]; then
            first_err=$(grep -a -m1 "Oliver failed" "$latest_adapter_log" 2>/dev/null | head -n1 || true)
          fi
          if [[ -z "$first_err" && -f "${LOG_FILE:-}" ]]; then
            first_err=$(grep -a -m1 -E "Oliver rendering failed|RawHtmlNotXmlWellFormed" "$LOG_FILE" 2>/dev/null | head -n1 || true)
          fi
          if [[ -z "$first_err" && -n "$latest_adapter_log" && -f "$latest_adapter_log" ]]; then
            first_err=$(grep -a -m1 -E "Oliver rendering failed|RawHtmlNotXmlWellFormed" "$latest_adapter_log" 2>/dev/null | head -n1 || true)
          fi
          if [[ -z "$first_err" && -f "${LOG_FILE:-}" ]]; then
            first_err=$(grep -a -m1 "ERROR" "$LOG_FILE" 2>/dev/null | head -n1 || true)
          fi
          if [[ -z "$first_err" && -n "$latest_adapter_log" && -f "$latest_adapter_log" ]]; then
            first_err=$(grep -a -m1 "ERROR" "$latest_adapter_log" 2>/dev/null | head -n1 || true)
          fi
          if [[ -n "$first_err" ]]; then
            # Strip timestamp prefix for cleaner MARKER
            clean_err=$(echo "$first_err" | sed -E 's/^\[[^]]+\] \[[^]]+\] //; s/^ERROR: //; s/^.*\[MARKER\] //')
            # Ensure we show the ✗ prefix if stripped
            if [[ "$clean_err" != "✗"* && "$clean_err" == *"Oliver failed"* ]]; then
              clean_err="✗ $clean_err"
            elif [[ "$clean_err" == *"Oliver rendering failed"* ]]; then
              clean_err="✗ $clean_err"
            fi
            log "MARKER" "  $clean_err"
            # Also try to surface the raw oliver stderr first line if available (prefer render log)
            oliver_hint=""
            if [[ -f "${LOG_FILE:-}" ]]; then
              oliver_hint=$(grep -m1 "oliver:" "$LOG_FILE" 2>/dev/null | head -n1 || true)
            fi
            if [[ -z "$oliver_hint" && -n "$latest_adapter_log" && -f "$latest_adapter_log" ]]; then
              oliver_hint=$(grep -m1 "oliver:" "$latest_adapter_log" 2>/dev/null | head -n1 || true)
            fi
            if [[ -n "$oliver_hint" && "$oliver_hint" != "$first_err" ]]; then
              clean_hint=$(echo "$oliver_hint" | sed -E 's/^\[[^]]+\] \[[^]]+\] //')
              # Avoid duplicating the same oliver line already in clean_err
              if [[ "$clean_hint" != "$clean_err" && "$clean_hint" != *"$clean_err"* ]]; then
                log "MARKER" "  $clean_hint"
              fi
            fi
            # Also surface hint for XHTML if present
            hint_line=""
            if [[ -f "${LOG_FILE:-}" ]]; then
              hint_line=$(grep -m1 "hint: raw HTML" "$LOG_FILE" 2>/dev/null | head -n1 || true)
            fi
            if [[ -z "$hint_line" && -n "$latest_adapter_log" && -f "$latest_adapter_log" ]]; then
              hint_line=$(grep -m1 "hint: raw HTML" "$latest_adapter_log" 2>/dev/null | head -n1 || true)
            fi
            if [[ -n "$hint_line" ]]; then
              clean_hint2=$(echo "$hint_line" | sed -E 's/^\[[^]]+\] \[[^]]+\] //')
              log "MARKER" "  $clean_hint2"
            fi
          fi
          if [[ -n "$latest_adapter_log" && -f "$latest_adapter_log" ]]; then
            log "ERROR" "Render failed: Oliver adapter error — see $latest_adapter_log"
            echo "ERROR: Render failed — Oliver adapter error — see $latest_adapter_log" >&2
          else
            log "ERROR" "Render failed: Oliver adapter error (no log found)"
            echo "ERROR: Render failed: Oliver adapter error" >&2
          fi
          exit 1
        fi
      fi

      for mdfile in ${md_corpses[@]+"${md_corpses[@]}"}; do
        [ -f "$mdfile" ] || continue
        canonical_mdpath=$(get_canonical_path "$mdfile")
        [[ -n "$canonical_mdpath" && "$canonical_mdpath" == "$CANONICAL_CONTENT_DIR"* ]] || continue
        relpath="${canonical_mdpath#"$CANONICAL_CONTENT_DIR"/}"
        base=$(strip_source_ext "$(basename "$relpath")")
        reldir=$(dirname "$relpath")
        if [[ "$reldir" == "." ]]; then
          outdir="$OUTPUT_DIR"
        else
          outdir="$OUTPUT_DIR/$reldir"
        fi
        outfile="$outdir/${base}.html"
        pages_rendered=$((pages_rendered + 1))
        log_manifest "$outfile"
        if [[ "$VERBOSE" == true ]]; then
          rel_out="${outfile#"$OUTPUT_DIR"/}"
          log "MARKER" "  reanimated $relpath → $rel_out"
        fi
      done

      rm -f "$batch_tsv"
    fi

    end_ts=$(date +%s)
    duration=$((end_ts - start_ts))

    # Gather Oliver warning total from adapter batch (if any)
    warning_total=0
    warnings_file="$TMP_DIR/oliver-warnings-batch.log"
    if [[ -f "$warnings_file" ]]; then
      warning_total=$(awk '{ s+=$1 } END { print s+0 }' "$warnings_file" 2>/dev/null || echo 0)
      rm -f "$warnings_file"
    fi

    # Surface first 2 Oliver warnings inline (adapter wrote them to shared list; its fd3 is not the user's tty)
    warnings_list="$TMP_DIR/oliver-warnings-list.log"
    if [[ -f "$warnings_list" ]]; then
      head -n 2 "$warnings_list" | while IFS= read -r wline || [[ -n "$wline" ]]; do
        log "MARKER" "⚠️  $wline"
      done
      rm -f "$warnings_list"
    fi

    mark_output_generated

    if [[ "${DRY_RUN:-false}" == true ]]; then
      log "MARKER" "DRY-RUN: would reanimate $pages_rendered tombs in ${duration}s"
    else
      if [[ "$warning_total" -gt 0 ]]; then
        # shellcheck disable=SC2012
        latest_adapter_log=$(ls -t "$LOG_DIR"/rc-oliver-adapter-*.log 2>/dev/null | head -n1 || true)
        hint=""
        if [[ -n "$latest_adapter_log" ]]; then
          rel_hint="${latest_adapter_log#"$ROOT_DIR"/}"
          hint=" — see $rel_hint"
        fi
        log "MARKER" "✓ Exorcism complete — $pages_rendered tombs in ${duration}s — $warning_total warnings$hint"
      else
        log "MARKER" "✓ Exorcism complete — $pages_rendered tombs in ${duration}s — output current"
      fi
    fi

    log "INFO" "Rendered $pages_rendered pages in ${duration}s ($RENDERER) warnings=$warning_total"

    log "INFO" "rc-render.sh completed successfully."
}

main "$@"
