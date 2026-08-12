#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# ============================================================
#  Project : Rotkeeper
#  Script  : bones/scripts/rc-apex-adapter.sh
#  Purpose : Pure Bash + GAWK + YQ batch adapter for Apex renderer.
#            Zero Python requirement. Evaluates Rotkeeper HTML templates,
#            enforces path boundaries, applies sidecar metadata precedence,
#            evaluates template conditionals, and rewrites internal .md links.
#  Version : 0.5.1
#  Updated : 2026-03-23
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
rk_init_script "rc-apex-adapter" "$@"

if [[ $# -lt 1 ]]; then
  log "ERROR" "Usage: rc-apex-adapter.sh <batch_manifest.tsv>"
  echo "Usage: rc-apex-adapter.sh <batch_manifest.tsv>" >&2
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
  canonical=$(realpath -m "$path" 2>/dev/null || readlink -f "$path" 2>/dev/null || echo "$path")
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
while IFS=$'\t' read -r src_path dst_path template_path assets_root soul_path apex_bin root_dir content_dir output_dir template_dir meta_dir dry_run verbose || [[ -n "$src_path" ]]; do
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

  if [[ ! -x "$apex_bin" ]]; then
    log "ERROR" "Apex binary is missing or not executable: '$apex_bin'"
    echo "ERROR: Apex binary is missing or not executable: '$apex_bin'" >&2
    exit 1
  fi

  # 1. Extract metadata from Markdown source in 1 single yq call
  meta_json="$TMP_DIR/doc-meta-$$.json"
  yq --front-matter extract -o json '{"title": .title, "description": .description, "author": .author, "date": .date, "template": .template, "palette": .palette}' "$src_path" > "$meta_json" 2>/dev/null || echo "{}" > "$meta_json"

  doc_title=$(yq -r '.title // ""' "$meta_json" 2>/dev/null || echo "")
  doc_desc=$(yq -r '.description // ""' "$meta_json" 2>/dev/null || echo "")
  doc_author=$(yq -r '.author // ""' "$meta_json" 2>/dev/null || echo "")
  doc_date=$(yq -r '.date // ""' "$meta_json" 2>/dev/null || echo "")
  doc_tmpl=$(yq -r '.template // ""' "$meta_json" 2>/dev/null || echo "")
  doc_palette=$(yq -r '.palette // ""' "$meta_json" 2>/dev/null || echo "")
  rm -f "$meta_json"

  [[ "$doc_title" == "null" ]] && doc_title=""
  [[ "$doc_desc" == "null" ]] && doc_desc=""
  [[ "$doc_author" == "null" ]] && doc_author=""
  [[ "$doc_date" == "null" ]] && doc_date=""
  [[ "$doc_tmpl" == "null" ]] && doc_tmpl=""
  [[ "$doc_palette" == "null" ]] && doc_palette=""

  title="$doc_title"
  desc="$doc_desc"
  author="$doc_author"
  date="$doc_date"
  tmpl="$doc_tmpl"
  palette="$doc_palette"

  [[ "$soul_path" == "NONE" ]] && soul_path=""

  # 2. Sidecar metadata overrides (sidecar dominance in 1 yq call)
  if [[ -n "$soul_path" && -f "$soul_path" ]]; then
    if ! is_within_boundary "$soul_path" "$meta_dir"; then
      log "ERROR" "Boundary violation: Sidecar path '$soul_path' escapes '$meta_dir'"
      echo "ERROR: Boundary violation: Sidecar path '$soul_path' escapes '$meta_dir'" >&2
      exit 1
    fi

    soul_json="$TMP_DIR/soul-meta-$$.json"
    yq --front-matter extract -o json '{"title": .title, "description": .description, "author": .author, "date": .date, "template": .template, "palette": .palette}' "$soul_path" > "$soul_json" 2>/dev/null || echo "{}" > "$soul_json"

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

  # 4. Invoke Apex to convert Markdown to body HTML snippet
  mkdir -p "$TMP_DIR"
  body_tmp="$TMP_DIR/apex-body-$$.html"
  body_rewritten="$TMP_DIR/apex-body-rewritten-$$.html"
  apex_err="$TMP_DIR/apex-err-$$.log"
  rm -f "$body_tmp" "$body_rewritten" "$apex_err"

  if ! "$apex_bin" "$src_path" > "$body_tmp" 2>"$apex_err"; then
    log "ERROR" "Apex rendering failed for page '$src_path' using template '$template_path'"
    echo "ERROR: Apex rendering failed for page '$src_path' using template '$template_path'" >&2
    if [[ -f "$apex_err" && -s "$apex_err" ]]; then
      cat "$apex_err" >&2
    fi
    rm -f "$body_tmp" "$body_rewritten" "$apex_err"
    exit 1
  fi

  if [[ -f "$apex_err" && -s "$apex_err" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      log "WARN" "Apex warning for '$src_path': $line"
    done < "$apex_err"
  fi
  rm -f "$apex_err"

  # 5. Link Rewriting Pass via GAWK (Linear scan, string slicing for robust replacement)
  # NOTE: inner match() calls must not clobber the outer RSTART/RLENGTH used to
  # advance `line`. Save outer_rstart and outer_rlen before any inner match() call.
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
      } else {
        new_target = target
      }

      out_line = out_line prefix attr "=" quote new_target quote
      line = substr(line, outer_rstart + outer_rlen)
    }

    out_line = out_line line
    print out_line
  }' "$body_tmp" > "$body_rewritten"


  # 6. Template Interpolation Pass via GAWK (Linear string searching for multiline $if$)
  if [[ "$dry_run" == "true" ]]; then
    if [[ "$verbose" == "true" ]]; then
      log "DRY-RUN" "Would write rendered HTML for '$src_path' -> '$dst_path'"
    fi
  else
    mkdir -p "$(dirname "$dst_path")"
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

  rm -f "$body_tmp" "$body_rewritten"
done < "$MANIFEST_TSV"

exit 0
