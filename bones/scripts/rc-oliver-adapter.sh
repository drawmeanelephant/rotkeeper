#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# ============================================================
#  Project : Rotkeeper
#  Script  : bones/scripts/rc-oliver-adapter.sh
#  Purpose : Pure Bash + GAWK + YQ batch adapter for Oliver renderer.
#            Zero Python requirement. Evaluates Rotkeeper HTML templates,
#            enforces path boundaries, applies sidecar metadata precedence,
#            evaluates template conditionals, and rewrites internal
#            .md/.textile links to .html.
#  Version : 0.7.0
#  Updated : 2026-08-21
#  Phase 6 complete: frontmatter `oliver meta`, template `oliver wrap`, link rewriting `oliver render`, output planning `oliver plan`, manifest `oliver manifest` — all with yq/gawk/gfind fallback on pin 6edb520c.
# ============================================================

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

get_canonical_path() {
  local path="$1"
  local canonical
  canonical=$(rk_canonical_path "$path" 2>/dev/null || echo "$path")
  echo "$canonical"
}

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

# Probe once per batch whether Oliver natively rewrites internal links (S3)
# Used to decide GAWK fallback; cached in OLIVER_REWRITES (unknown→true/false)
if [[ "${OLIVER_REWRITES:-unknown}" == unknown ]]; then
  _probe_out=$(mktemp)
  if printf '[x](foo.md)\n' | "$oliver_bin" render --from markdown > "$_probe_out" 2>/dev/null && grep -q 'foo.html' "$_probe_out" 2>/dev/null; then
    OLIVER_REWRITES=true
    log "INFO" "Oliver natively rewrites links (.md/.textile/.cook → .html) — GAWK link pass will be skipped"
  else
    OLIVER_REWRITES=false
    log "INFO" "Oliver does not natively rewrite links — using GAWK link pass"
  fi
  rm -f "$_probe_out"
fi

  # 1. Extract metadata — Phase 6 S1: Oliver meta with yq fallback
  #    Input format is derived from extension (overrides config) so --from matches render.
  meta_input_format="${INPUT_FORMAT:-markdown}"
  if [[ "$src_path" == *.textile ]]; then
    meta_input_format="textile"
  elif [[ "$src_path" == *.cook ]]; then
    meta_input_format="cooklang"
  fi
  meta_json="$TMP_DIR/doc-meta-$$.json"
  oliver_meta_ok=false
  if "$oliver_bin" meta --help >/dev/null 2>&1; then
    if "$oliver_bin" meta --from "$meta_input_format" --format json < "$src_path" > "$meta_json" 2>/dev/null; then
      if yq eval '.' "$meta_json" >/dev/null 2>&1; then
        oliver_meta_ok=true
        log "INFO" "Oliver meta extraction succeeded for '$src_path' (from=$meta_input_format)"
      fi
    fi
  fi
  if [[ "$oliver_meta_ok" == false ]]; then
    yq --front-matter extract -o json '{"title": .title, "description": .description, "author": .author, "date": .date, "template": .template, "palette": .palette, "render_profile": .render_profile}' "$src_path" > "$meta_json" 2>/dev/null || echo "{}" > "$meta_json"
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
    soul_meta_ok=false
    if "$oliver_bin" meta --help >/dev/null 2>&1; then
      if "$oliver_bin" meta --from "$meta_input_format" --format json < "$soul_path" > "$soul_json" 2>/dev/null; then
        if yq eval '.' "$soul_json" >/dev/null 2>&1; then
          soul_meta_ok=true
          log "INFO" "Oliver meta extraction succeeded for sidecar '$soul_path'"
        fi
      fi
    fi
    if [[ "$soul_meta_ok" == false ]]; then
      yq --front-matter extract -o json '{"title": .title, "description": .description, "author": .author, "date": .date, "template": .template, "palette": .palette}' "$soul_path" > "$soul_json" 2>/dev/null || echo "{}" > "$soul_json"
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

  oliver_cmd=("$oliver_bin" render --from "$input_format")
  if [[ "$profile" == "xhtml" ]]; then
    oliver_cmd+=(--to xhtml)
  fi

  if ! awk '
      BEGIN { skip = 0 }
      NR == 1 && $0 == "---" { skip = 1; next }
      skip == 1 && $0 == "---" { skip = 0; next }
      skip == 0 { print }
    ' "$src_path" | "${oliver_cmd[@]}" > "$body_tmp" 2> "$oliver_err"; then
    # ERR trap is suppressed inside `if !` (bash manual), so we can safely
    # read PIPESTATUS for the pipeline's exit codes.
    oliver_status=${PIPESTATUS[1]:-1}
    if [[ $oliver_status -eq 0 ]]; then
      oliver_status=${PIPESTATUS[0]:-1}
      [[ $oliver_status -eq 0 ]] && oliver_status=1
    fi
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
      echo "Oliver warning for '$(basename "$src_path")': $line" >> "$TMP_DIR/oliver-warnings-list.log"
      warn_count=$((warn_count + 1))
    done < "$oliver_err"
    # Accumulate total warnings for render summary (shared across batch)
    if [[ $warn_count -gt 0 ]]; then
      echo "$warn_count" >> "$TMP_DIR/oliver-warnings-batch.log"
    fi
  fi
  rm -f "$oliver_err"

  # 5. Link Rewriting Pass — Phase 6 S3: Oliver-owned with GAWK fallback
  # NOTE: inner match() calls must not clobber the outer RSTART/RLENGTH used to
  # advance `line`. Save outer_rstart and outer_rlen before any inner match() call.
  # Probe result OLIVER_REWRITES decides: true → Oliver already rewrote (AST), skip GAWK.
  if [[ "${OLIVER_REWRITES:-false}" == true ]]; then
    cp "$body_tmp" "$body_rewritten"
    log "INFO" "Skipped GAWK link rewriting for '$src_path' (Oliver native)"
  else
    gawk '
  {
    line = $0
    out_line = ""

    while (match(line, /(href|src)=("|\x27)([^"\x27]+)("|\x27)/, arr)) {
      outer_rstart = RSTART
      outer_rlen   = RLENGTH
      prefix = substr(line, 1, outer_rstart - 1)
      attr   = arr[1]
      quote  = arr[2]
      target = arr[3]

      if (target ~ /^(%3C|<|&lt;).*(%3E|>|&gt;)$/) {
        if (substr(target, 1, 3) == "%3C") {
          target = substr(target, 4)
        } else if (substr(target, 1, 4) == "&lt;") {
          target = substr(target, 5)
        } else if (substr(target, 1, 1) == "<") {
          target = substr(target, 2)
        }

        t_len = length(target)
        if (t_len >= 3 && substr(target, t_len - 2) == "%3E") {
          target = substr(target, 1, t_len - 3)
        } else if (t_len >= 4 && substr(target, t_len - 3) == "&gt;") {
          target = substr(target, 1, t_len - 4)
        } else if (t_len >= 1 && substr(target, t_len) == ">") {
          target = substr(target, 1, t_len - 1)
        }
      }

      if (target ~ /^[a-zA-Z][a-zA-Z0-9+.-]*:\/\// || target ~ /^mailto:/) {
        new_target = target
      } else if (match(target, /\.md(\?|#|$)/)) {
        t_base = substr(target, 1, RSTART - 1)
        t_tail = substr(target, RSTART + 3)
        new_target = t_base ".html" t_tail
      } else if (match(target, /\.textile(\?|#|$)/)) {
        t_base = substr(target, 1, RSTART - 1)
        t_tail = substr(target, RSTART + 8)
        new_target = t_base ".html" t_tail
      } else if (match(target, /\.cook(\?|#|$)/)) {
        t_base = substr(target, 1, RSTART - 1)
        t_tail = substr(target, RSTART + 5)
        new_target = t_base ".html" t_tail
      } else {
        new_target = target
      }

      out_line = out_line prefix attr "=" quote new_target quote
      line = substr(line, outer_rstart + outer_rlen)
    }

    out_line = out_line line
    print out_line
  }' "$body_tmp" > "$body_rewritten"
  fi


  # 6. Template Interpolation Pass — Phase 6 S2: Oliver wrap with GAWK fallback
  #    Seven tokens, html_escape for 5 fields, $assets_root$/$body$ literal,
  #    $if$/$endif$ gating. Bash keeps TEMPLATE_DIR boundary; Oliver handles interpolation when available.
  if [[ "$dry_run" == "true" ]]; then
    if [[ "$verbose" == "true" ]]; then
      log "DRY-RUN" "Would write rendered HTML for '$src_path' -> '$dst_path'"
    fi
  else
    mkdir -p "$(dirname "$dst_path")"
    # Build meta JSON for Oliver wrap (jq handles escaping). Fallback to manual if jq missing.
    wrap_meta="$TMP_DIR/wrap-meta-$$.json"
    if command -v jq >/dev/null 2>&1; then
      jq -n --arg title "$title" --arg desc "$desc" --arg author "$author" --arg date "$date" --arg palette "$palette" \
        '{title:$title, description:$desc, author:$author, date:$date, palette:$palette}' > "$wrap_meta" 2>/dev/null || echo "{\"title\":\"\",\"description\":\"\",\"author\":\"\",\"date\":\"\",\"palette\":\"\"}" > "$wrap_meta"
    else
      # Minimal fallback: use yq to build JSON (yq can emit json from env)
      printf '{"title":%s,"description":%s,"author":%s,"date":%s,"palette":%s}' \
        "$(printf '%s' "$title" | jq -Rs . 2>/dev/null || printf '"%s"' "$title")" \
        "$(printf '%s' "$desc" | jq -Rs . 2>/dev/null || printf '"%s"' "$desc")" \
        "$(printf '%s' "$author" | jq -Rs . 2>/dev/null || printf '"%s"' "$author")" \
        "$(printf '%s' "$date" | jq -Rs . 2>/dev/null || printf '"%s"' "$date")" \
        "$(printf '%s' "$palette" | jq -Rs . 2>/dev/null || printf '"%s"' "$palette")" > "$wrap_meta" 2>/dev/null || echo '{"title":"","description":"","author":"","date":"","palette":""}' > "$wrap_meta"
    fi

    oliver_wrap_ok=false
    if "$oliver_bin" wrap --help >/dev/null 2>&1; then
      if "$oliver_bin" wrap --template "$template_path" --meta-json "$wrap_meta" --assets-root "$assets_root" --body "$body_rewritten" > "$dst_path" 2>/dev/null; then
        oliver_wrap_ok=true
        log "INFO" "Oliver wrap succeeded for '$src_path'"
      else
        log "INFO" "Oliver wrap failed for '$src_path' — falling back to GAWK"
        rm -f "$dst_path"
      fi
    fi
    rm -f "$wrap_meta"

    if [[ "$oliver_wrap_ok" == false ]]; then
      gawk \
        -v title="$title" \
        -v desc="$desc" \
        -v author="$author" \
        -v date="$date" \
        -v palette="$palette" \
        -v assets_root="$assets_root" \
        -v body_file="$body_rewritten" \
        -v template_file="$template_path" \
      '
      function html_escape(str,   s) {
        s = str
        gsub(/&/, "\\&amp;", s)
        gsub(/</, "\\&lt;", s)
        gsub(/>/, "\\&gt;", s)
        gsub(/"/, "\\&quot;", s)
        gsub(/\x27/, "\\&#39;", s)
        return s
      }
      function literal_replace(str, search, replace,   pos, len, result, tail) {
        len = length(search)
        result = ""
        tail = str
        while ((pos = index(tail, search)) > 0) {
          result = result substr(tail, 1, pos - 1) replace
          tail = substr(tail, pos + len)
        }
        return result tail
      }
      function evaluate_if(tmpl, var_name, var_val,   start_tag, end_tag, sp, ep, before, after, inner) {
        start_tag = "$if(" var_name ")$"
        end_tag = "$endif$"
        
        while ((sp = index(tmpl, start_tag)) > 0) {
          ep = index(substr(tmpl, sp), end_tag)
          if (ep == 0) break
          ep = sp + ep - 1 + length(end_tag) - 1
          
          before = substr(tmpl, 1, sp - 1)
          after = substr(tmpl, ep + 1)
          
          if (var_val == "" || var_val == "null") {
            tmpl = before after
          } else {
            inner = substr(tmpl, sp + length(start_tag), ep - sp - length(start_tag) - length(end_tag) + 1)
            tmpl = before inner after
          }
        }
        return tmpl
      }
      BEGIN {
        title_esc = html_escape(title)
        desc_esc  = html_escape(desc)
        author_esc = html_escape(author)
        date_esc  = html_escape(date)
        palette_esc = html_escape(palette)

        body = ""
        while ((getline line < body_file) > 0) {
          body = body line "\n"
        }
        close(body_file)
        if (length(body) > 0 && substr(body, length(body)) == "\n") {
          body = substr(body, 1, length(body)-1)
        }

        tmpl = ""
        while ((getline line < template_file) > 0) {
          tmpl = tmpl line "\n"
        }
        close(template_file)

        tmpl = evaluate_if(tmpl, "title", title)
        tmpl = evaluate_if(tmpl, "description", desc)
        tmpl = evaluate_if(tmpl, "author", author)
        tmpl = evaluate_if(tmpl, "date", date)
        tmpl = evaluate_if(tmpl, "palette", palette)

        tmpl = literal_replace(tmpl, "$title$", title_esc)
        tmpl = literal_replace(tmpl, "$description$", desc_esc)
        tmpl = literal_replace(tmpl, "$author$", author_esc)
        tmpl = literal_replace(tmpl, "$date$", date_esc)
        tmpl = literal_replace(tmpl, "$palette$", palette_esc)
        tmpl = literal_replace(tmpl, "$assets_root$", assets_root)
        tmpl = literal_replace(tmpl, "$body$", body)

        printf "%s", tmpl
        exit
      }' > "$dst_path"
    fi
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
