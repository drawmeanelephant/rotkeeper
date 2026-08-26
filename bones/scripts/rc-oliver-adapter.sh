#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# ============================================================
#  Project : Rotkeeper
#  Script  : bones/scripts/rc-oliver-adapter.sh
#  Purpose : Pure Bash batch adapter for Oliver renderer.
#            Zero Python requirement. Enforces path boundaries and
#            orchestrates Oliver `meta`/`render`/`wrap` for frontmatter,
#            link rewriting, and template interpolation.
#  Version : 0.7.0
#  Updated : 2026-08-21
#  Phase 6 complete: frontmatter `oliver meta`, template `oliver wrap`, link rewriting `oliver render`, output planning `oliver plan`, manifest `oliver manifest` — direct on pin 9ad86a3, no GAWK/YQ fallback.
# ============================================================
# Env assumptions: reads INPUT_FORMAT, RENDER_PROFILE, SCRIPT_DIR, TEMPLATE_DIR, TMP_DIR (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.
# CWD assumptions: No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.
# Input/Output contracts: CLI args and env vars in; files and stdout/stderr out; respects --dry-run (no writes) and --verbose.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
rk_init_script "rc-oliver-adapter" "$@"

if [[ $# -lt 1 ]]; then
  log "ERROR" "Usage: rc-oliver-adapter.sh <batch_manifest.tsv>"
  echo "Usage: rc-oliver-adapter.sh <batch_manifest.tsv>" >&2
  exit 1
fi

MANIFEST_TSV="$1"
if [[ ! -f "$MANIFEST_TSV" ]]; then
  log "ERROR" "Batch manifest file not found: $MANIFEST_TSV"
  echo "ERROR: Batch manifest file not found: $MANIFEST_TSV" >&2
  exit 1
fi

# ---
# get_canonical_path: Resolve a path leniently for boundary checks.
# Inputs: $1 (path; may not exist)
# Outputs: Prints canonical or raw path via rk_canonical_or_raw
# Env: Reads BONES_DIR, DRY_RUN, INPUT_FORMAT, QUIET, ROOT_DIR, TMP_DIR ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
get_canonical_path() {
  rk_canonical_or_raw "$1"
}

# ---
# is_within_boundary: Check that a target path stays inside a boundary.
# Inputs: $1 (target), $2 (boundary directory)
# Outputs: Returns 0 if target == boundary or is strictly under it, 1 otherwise
# Env: Reads INPUT_FORMAT, TMP_DIR (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
is_within_boundary() {
  local target="$1"
  local boundary="$2"
  local c_target
  local c_boundary
  c_target=$(get_canonical_path "$target")
  c_boundary=$(get_canonical_path "$boundary")
  if [[ "$c_target" == "$c_boundary" || "$c_target" == "$c_boundary"/* ]]; then
    return 0
  fi
  return 1
}

# Process each item in the TSV batch manifest
while IFS=$'\t' read -r src_path dst_path template_path assets_root soul_path oliver_bin root_dir content_dir output_dir template_dir meta_dir dry_run verbose || [[ -n "$src_path" ]]; do
  [[ -z "$src_path" || "$src_path" =~ ^[[:space:]]*# ]] && continue

  # Boundary safety assertions
  if ! is_within_boundary "$src_path" "$content_dir"; then
    log "ERROR" "Boundary violation: Source path '$src_path' escapes '$content_dir'"
    echo "ERROR: Boundary violation: Source path '$src_path' escapes '$content_dir'" >&2
    exit 1
  fi

  if ! is_within_boundary "$dst_path" "$output_dir"; then
    log "ERROR" "Boundary violation: Target path '$dst_path' escapes '$output_dir'"
    echo "ERROR: Boundary violation: Target path '$dst_path' escapes '$output_dir'" >&2
    exit 1
  fi

  if [[ ! -x "$oliver_bin" ]]; then
    log "ERROR" "Oliver binary is missing or not executable: '$oliver_bin'"
    echo "ERROR: Oliver binary is missing or not executable: '$oliver_bin'" >&2
    exit 1
  fi

  # 1. Extract metadata — Phase 6 S1: Oliver meta (no fallback, pin 9ad86a3)
  #    Input format is derived from extension (overrides config) so --from matches render.
  meta_input_format="${INPUT_FORMAT:-markdown}"
  if [[ "$src_path" == *.textile ]]; then
    meta_input_format="textile"
  elif [[ "$src_path" == *.cook ]]; then
    meta_input_format="cooklang"
  fi
  meta_json="$TMP_DIR/doc-meta-$$.json"
  if ! "$oliver_bin" meta --from "$meta_input_format" --format json < "$src_path" > "$meta_json" 2>/dev/null; then
    log "ERROR" "Oliver meta failed for '$src_path' (from=$meta_input_format)"
    echo "ERROR: Oliver meta failed for '$src_path'" >&2
    exit 1
  fi
  if ! yq eval '.' "$meta_json" >/dev/null 2>&1; then
    log "ERROR" "Oliver meta returned invalid JSON for '$src_path'"
    echo "ERROR: Oliver meta returned invalid JSON for '$src_path'" >&2
    exit 1
  fi

  doc_title=$(yq -r '.title // ""' "$meta_json" 2>/dev/null || echo "")
  doc_desc=$(yq -r '.description // ""' "$meta_json" 2>/dev/null || echo "")
  doc_author=$(yq -r '.author // ""' "$meta_json" 2>/dev/null || echo "")
  doc_date=$(yq -r '.date // ""' "$meta_json" 2>/dev/null || echo "")
  doc_tmpl=$(yq -r '.template // ""' "$meta_json" 2>/dev/null || echo "")
  doc_palette=$(yq -r '.palette // ""' "$meta_json" 2>/dev/null || echo "")
  doc_render_profile=$(yq -r '.render_profile // ""' "$meta_json" 2>/dev/null || echo "")
  rm -f "$meta_json"

  [[ "$doc_title" == "null" ]] && doc_title=""
  [[ "$doc_desc" == "null" ]] && doc_desc=""
  [[ "$doc_author" == "null" ]] && doc_author=""
  [[ "$doc_date" == "null" ]] && doc_date=""
  [[ "$doc_tmpl" == "null" ]] && doc_tmpl=""
  [[ "$doc_palette" == "null" ]] && doc_palette=""
  [[ "$doc_render_profile" == "null" ]] && doc_render_profile=""

  title="$doc_title"
  desc="$doc_desc"
  author="$doc_author"
  date="$doc_date"
  tmpl="$doc_tmpl"
  palette="$doc_palette"
  render_profile="$doc_render_profile"

  [[ "$soul_path" == "NONE" ]] && soul_path=""

  # 2. Sidecar metadata overrides (sidecar dominance in 1 yq call)
  if [[ -n "$soul_path" && -f "$soul_path" ]]; then
    if ! is_within_boundary "$soul_path" "$meta_dir"; then
      log "ERROR" "Boundary violation: Sidecar path '$soul_path' escapes '$meta_dir'"
      echo "ERROR: Boundary violation: Sidecar path '$soul_path' escapes '$meta_dir'" >&2
      exit 1
    fi

    soul_json="$TMP_DIR/soul-meta-$$.json"
    if ! "$oliver_bin" meta --from "$meta_input_format" --format json < "$soul_path" > "$soul_json" 2>/dev/null; then
      log "ERROR" "Oliver meta failed for sidecar '$soul_path'"
      echo "ERROR: Oliver meta failed for sidecar '$soul_path'" >&2
      exit 1
    fi
    if ! yq eval '.' "$soul_json" >/dev/null 2>&1; then
      log "ERROR" "Oliver meta returned invalid JSON for sidecar '$soul_path'"
      echo "ERROR: Oliver meta returned invalid JSON for sidecar '$soul_path'" >&2
      exit 1
    fi

    s_title=$(yq -r '.title // ""' "$soul_json" 2>/dev/null || echo "")
    s_desc=$(yq -r '.description // ""' "$soul_json" 2>/dev/null || echo "")
    s_author=$(yq -r '.author // ""' "$soul_json" 2>/dev/null || echo "")
    s_date=$(yq -r '.date // ""' "$soul_json" 2>/dev/null || echo "")
    s_tmpl=$(yq -r '.template // ""' "$soul_json" 2>/dev/null || echo "")
    s_palette=$(yq -r '.palette // ""' "$soul_json" 2>/dev/null || echo "")
    rm -f "$soul_json"

    [[ -n "$s_title" && "$s_title" != "null" ]] && title="$s_title"
    [[ -n "$s_desc" && "$s_desc" != "null" ]] && desc="$s_desc"
    [[ -n "$s_author" && "$s_author" != "null" ]] && author="$s_author"
    [[ -n "$s_date" && "$s_date" != "null" ]] && date="$s_date"
    [[ -n "$s_tmpl" && "$s_tmpl" != "null" ]] && tmpl="$s_tmpl"
    [[ -n "$s_palette" && "$s_palette" != "null" ]] && palette="$s_palette"
  fi

  # 3. Resolve template file
  if [[ -n "$tmpl" ]]; then
    candidate_tmpl="$template_dir/$tmpl"
    if [[ -f "$candidate_tmpl" ]] && is_within_boundary "$candidate_tmpl" "$template_dir"; then
      template_path="$candidate_tmpl"
    fi
  fi

  if [[ ! -f "$template_path" ]] || ! is_within_boundary "$template_path" "$template_dir"; then
    log "ERROR" "Invalid or missing template path '$template_path' for page '$src_path'"
    echo "ERROR: Invalid or missing template path '$template_path' for page '$src_path'" >&2
    exit 1
  fi

  # 4. Invoke Oliver to convert the source (Markdown, Textile, or Cooklang per
  #    input_format in rotkeeper.yaml, default markdown; a source with a
  #    .textile extension always renders as textile and one with a .cook
  #    extension always renders as cooklang, overriding the config default
  #    for that file) to body HTML snippet. S1: frontmatter stripping still
  #    via awk here; when `oliver meta` succeeds the file is known to be
  #    handled, and a future bump will make `oliver render` auto-strip
  #    (then awk becomes no-op/redundant and can be removed).
  #    The output profile mirrors the input-format pattern: render_profile in
  #    rotkeeper.yaml (html default, xhtml opt-in) arrives via RENDER_PROFILE,
  #    and a per-page render_profile in the source frontmatter overrides it
  #    for that file. Only an xhtml profile appends `--to xhtml`, so the
  #    default invocation is byte-identical to the html-only contract.
  mkdir -p "$TMP_DIR"
  body_tmp="$TMP_DIR/oliver-body-$$.html"
  body_rewritten="$TMP_DIR/oliver-body-rewritten-$$.html"
  oliver_err="$TMP_DIR/oliver-err-$$.log"
  rm -f "$body_tmp" "$body_rewritten" "$oliver_err"

  # Reuse meta_input_format if already computed for extraction; otherwise derive.
  if [[ -n "${meta_input_format:-}" ]]; then
    input_format="$meta_input_format"
  else
    input_format="${INPUT_FORMAT:-markdown}"
    if [[ "$src_path" == *.textile ]]; then
      input_format="textile"
    elif [[ "$src_path" == *.cook ]]; then
      input_format="cooklang"
    fi
  fi

  profile="${render_profile:-${RENDER_PROFILE:-html}}"
  case "${profile,,}" in
    xhtml)
      profile="xhtml"
      ;;
    html)
      profile="html"
      ;;
    *)
      log "WARN" "Unsupported render_profile '$profile' for '$src_path'; falling back to '${RENDER_PROFILE:-html}'."
      profile="${RENDER_PROFILE:-html}"
      ;;
  esac

  oliver_cmd=("$oliver_bin" render --from "$input_format" --frontmatter yaml)
  if [[ "$profile" == "xhtml" ]]; then
    oliver_cmd+=(--to xhtml)
  fi

  oliver_status=0
  "${oliver_cmd[@]}" < "$src_path" > "$body_tmp" 2> "$oliver_err" || oliver_status=$?
  if [[ "$oliver_status" -ne 0 ]]; then
    first_err_line="$(head -n1 "$oliver_err" 2>/dev/null || echo "no details")"
    log "ERROR" "Oliver rendering failed for page '$src_path' using template '$template_path' (exit $oliver_status): $first_err_line"
    log "MARKER" "✗ Oliver failed for '$(basename "$src_path")' (exit $oliver_status): $first_err_line"
    echo "ERROR: Oliver rendering failed for page '$src_path' using template '$template_path' (exit $oliver_status): $first_err_line" >&2
    if [[ -f "$oliver_err" && -s "$oliver_err" ]]; then
      cat "$oliver_err" >&2
    fi
    # Surface hint for XHTML fail-closed specifically
    if grep -q "RawHtmlNotXmlWellFormed" "$oliver_err" 2>/dev/null; then
      log "MARKER" "  hint: raw HTML is not allowed under --to xhtml — remove <b>/<i> etc. or switch page to render_profile: html"
    fi
    rm -f "$body_tmp" "$body_rewritten" "$oliver_err"
    exit 1
  fi

  if [[ -f "$oliver_err" && -s "$oliver_err" ]]; then
    warn_count=0
    while IFS= read -r line || [[ -n "$line" ]]; do
      log "WARN" "Oliver warning for '$src_path': $line"
      # Keep MARKER for log file even though it won't reach terminal via fd 3 (adapter's fd3 is not the user's tty); render will re-surface the first 2 from the shared list
      if [[ $warn_count -lt 2 ]]; then
        log "MARKER" "⚠️  Oliver warning for '$(basename "$src_path")': $line"
      fi
      echo "Oliver warning for '$(basename "$src_path")': $line" >> "$TMP_DIR/oliver-warnings-list-${RK_RENDER_ID:-$$}.log"
      warn_count=$((warn_count + 1))
    done < "$oliver_err"
    # Accumulate total warnings for render summary (shared across batch)
    if [[ $warn_count -gt 0 ]]; then
      echo "$warn_count" >> "$TMP_DIR/oliver-warnings-batch-${RK_RENDER_ID:-$$}.log"
    fi
  fi
  rm -f "$oliver_err"

  # 5. Link Rewriting — Phase 6 S3: Oliver render AST rewrites (no GAWK, pin 9ad86a3)
  cp "$body_tmp" "$body_rewritten"


  # 6. Template Interpolation Pass — Phase 6 S2: Oliver wrap (direct, pin 9ad86a3)
  #    Seven tokens, html_escape for 5 fields, $assets_root$/$body$ literal,
  #    $if$/$endif$ gating. Bash keeps TEMPLATE_DIR boundary; Oliver handles interpolation.
  if [[ "$dry_run" == "true" ]]; then
    if [[ "$verbose" == "true" ]]; then
      log "DRY-RUN" "Would write rendered HTML for '$src_path' -> '$dst_path'"
    fi
  else
    mkdir -p "$(dirname "$dst_path")"
    wrap_meta="$TMP_DIR/wrap-meta-$$.json"
    jq -n --arg title "$title" --arg desc "$desc" --arg author "$author" --arg date "$date" --arg palette "$palette" \
      '{title:$title, description:$desc, author:$author, date:$date, palette:$palette}' > "$wrap_meta" 2>/dev/null || echo "{\"title\":\"\",\"description\":\"\",\"author\":\"\",\"date\":\"\",\"palette\":\"\"}" > "$wrap_meta"

    if ! "$oliver_bin" wrap --template "$template_path" --meta-json "$wrap_meta" --assets-root "$assets_root" --body "$body_rewritten" > "$dst_path" 2> "$TMP_DIR/oliver-wrap-$$.log"; then
      log "ERROR" "Oliver wrap failed for '$src_path'"
      cat "$TMP_DIR/oliver-wrap-$$.log" >&2
      rm -f "$wrap_meta" "$TMP_DIR/oliver-wrap-$$.log" "$dst_path"
      exit 1
    fi
    rm -f "$wrap_meta" "$TMP_DIR/oliver-wrap-$$.log"
    log "INFO" "Oliver wrap succeeded for '$src_path'"
    if [[ "$verbose" == "true" ]]; then
      # shellcheck disable=SC2295
      rel_src="${src_path#$content_dir/}"
      [[ "$rel_src" == "$src_path" ]] && rel_src="$(basename "$src_path")"
      # shellcheck disable=SC2295
      rel_dst="${dst_path#$output_dir/}"
      log "MARKER" "  reanimated $rel_src → $rel_dst ($input_format${profile:+/$profile})"
    fi
  fi

  rm -f "$body_tmp" "$body_rewritten"
done < "$MANIFEST_TSV"

exit 0
