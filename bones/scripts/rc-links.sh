#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# ============================================================
#  Project : Rotkeeper
#  Script  : rc-links.sh
#  Purpose : Audit rendered HTML links and local asset references
#  Version : 0.5.1
# ============================================================
# Env assumptions: reads BONES_DIR, CONFIG_DIR, CONTENT_DIR, DRY_RUN, LOG_DIR, LOG_FILE, OUTPUT_DIR, QUIET, REPORT_DIR, ROOT_DIR, SCRIPT_DIR, TMP_DIR, VERBOSE (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.
# CWD assumptions: No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.
# Input/Output contracts: CLI args and env vars in; files and stdout/stderr out; respects --dry-run (no writes) and --verbose.

# ---
# show_help: Print links audit usage and exit.
# Inputs: none
# Outputs: Prints help to stdout and exits 0
# Env: Reads BONES_DIR, CONFIG_DIR, DRY_RUN, LOG_DIR, OUTPUT_DIR, QUIET ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
show_help() {
  cat <<'EOF'
rc-links.sh — Audit rendered HTML links and local asset references

Usage: rotkeeper.sh links [options]

Options:
  --root DIR       Rendered directory to scan; defaults to output/
  --report FILE    Report destination; defaults to bones/reports/link-report-*.md
  --dry-run        Scan without writing a report
  --verbose        Show detailed logs (line numbers + excerpts)
  --json           Emit machine-readable JSON to stdout (failures with line+excerpt)
  --fix-hint       Show suggested fixes for each failure (no auto-fix)
  --help, -h       Show this help message
EOF
  exit 0
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
rk_init_script "rc-links" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR OUTPUT_DIR REPORT_DIR

SCAN_ROOT="$OUTPUT_DIR"
REPORT_FILE=""
JSON_MODE=false
FIX_HINT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      SCAN_ROOT="$2"
      shift 2
      ;;
    --report)
      REPORT_FILE="$2"
      shift 2
      ;;
    --json)
      JSON_MODE=true
      shift
      ;;
    --fix-hint)
      FIX_HINT=true
      shift
      ;;
    --dry-run|--verbose|--help|-h)
      shift
      ;;
    *)
      log "ERROR" "Unknown option: $1"
      exit 1
      ;;
  esac
done

# ---
# cleanup: Remove temporary result file.
# Inputs: none (reads RESULT_FILE)
# Outputs: Deletes temp file if set
# Env: Reads BONES_DIR, DRY_RUN, OUTPUT_DIR, QUIET, REPORT_DIR, RESULT_FILE ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
cleanup() {
  if [[ -n "${RESULT_FILE:-}" ]]; then
    # SIDE EFFECT (delete): removes the bones/tmp scan-result scratch file on exit
    rm -f "$RESULT_FILE" || true
  fi
}

# ---
# main: Audit rendered HTML links/assets, emit reports in md/json.
# Inputs: $@ (flags: --root, --report, --json, --fix-hint)
# Outputs: Writes report file, prints MARKER summary; exits 1 on failures
# Env: Reads OUTPUT_DIR, REPORT_DIR, ROOT_DIR, TMP_DIR (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
main() {
  require_bins python3
  mkdir -p "$TMP_DIR"

  if [[ "$SCAN_ROOT" == /* ]]; then
    SCAN_ROOT=$(rk_canonical_path "$SCAN_ROOT" 2>/dev/null || true)
  else
    SCAN_ROOT=$(rk_canonical_path "$ROOT_DIR/$SCAN_ROOT" 2>/dev/null || true)
  fi
  if [[ -z "$SCAN_ROOT" || ( "$SCAN_ROOT" != "$OUTPUT_DIR" && "$SCAN_ROOT" != "$OUTPUT_DIR/"* ) ]]; then
    log "ERROR" "--root must resolve under OUTPUT_DIR: $SCAN_ROOT"
    exit 1
  fi
  if [[ ! -d "$SCAN_ROOT" ]]; then
    log "ERROR" "Rendered scan directory does not exist: $SCAN_ROOT"
    exit 1
  fi

  if [[ -z "$REPORT_FILE" ]]; then
    REPORT_FILE="$REPORT_DIR/link-report-$(date +%Y%m%d_%H%M%S).md"
  elif [[ "$REPORT_FILE" != /* ]]; then
    REPORT_FILE="$ROOT_DIR/$REPORT_FILE"
  fi

  # SIDE EFFECT (write): mktemp creates a bones/tmp scratch file that captures the Python scan TSV (cleaned up on exit)
  RESULT_FILE=$(mktemp "$TMP_DIR/links.XXXXXX")
  python3 - "$SCAN_ROOT" >"$RESULT_FILE" <<'PY'
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit
import sys

root = Path(sys.argv[1]).resolve()

class Page(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []  # (tag, raw, lineno, excerpt)
        self.ids = set()
        self._lines = []

    def feed_with_lines(self, text):
        self._lines = text.splitlines()
        super().feed(text)

    def handle_starttag(self, tag, attrs):
        d = dict(attrs)
        # collect ids
        for k in ("id", "name"):
            v = d.get(k)
            if v:
                self.ids.add(v)
        attr = "href" if tag == "a" else "src" if tag in {"script", "img", "source", "video", "audio"} else None
        raw = d.get(attr) if attr else None
        if raw:
            lineno, _ = self.getpos()
            excerpt = ""
            if 1 <= lineno <= len(self._lines):
                excerpt = self._lines[lineno-1].strip()[:120]
                # sanitize tabs
                excerpt = excerpt.replace("\t", " ").replace("\r", "")
            # sanitize raw for TSV (tabs -> space)
            raw_s = raw.replace("\t", " ").replace("\n", " ").strip()
            excerpt_s = excerpt.replace("\t", " ")
            self.links.append((tag, raw_s, lineno, excerpt_s))

pages = sorted(root.rglob("*.html"))
checked = 0
failures = []  # (page, raw, reason, lineno, excerpt)

for page in pages:
    parser = Page()
    try:
        text = page.read_text(errors="replace")
    except Exception:
        continue
    parser.feed_with_lines(text)
    for tag, raw, lineno, excerpt in parser.links:
        value = unquote(raw.strip())
        parsed = urlsplit(value)
        if not value or value.startswith(("mailto:", "tel:", "javascript:")) or parsed.scheme or parsed.netloc:
            continue
        # count checked for every local link (even anchor-only)
        is_anchor_only = (parsed.path == "")
        if is_anchor_only:
            if parsed.fragment and parsed.fragment not in parser.ids:
                failures.append((page.relative_to(root), raw, "missing anchor", lineno, excerpt))
            # anchor-only still counts as checked if it has a fragment
            if parsed.fragment:
                checked += 1
            continue
        candidate = (root / parsed.path.lstrip("/")) if parsed.path.startswith("/") else (page.parent / parsed.path)
        try:
            candidate = candidate.resolve()
        except Exception:
            failures.append((page.relative_to(root), raw, "missing file", lineno, excerpt))
            checked += 1
            continue
        if candidate != root and root not in candidate.parents:
            failures.append((page.relative_to(root), raw, "outside rendered root", lineno, excerpt))
        else:
            if candidate.is_dir():
                candidate /= "index.html"
            if not candidate.exists():
                failures.append((page.relative_to(root), raw, "missing file", lineno, excerpt))
        checked += 1

print(f"SUMMARY\t{len(pages)}\t{checked}\t{len(failures)}")
for page, raw, reason, lineno, excerpt in failures:
    # Use unit separator for excerpt to avoid TSV issues; keep tabs as separators, sanitize already
    print(f"FAIL\t{page}\t{raw}\t{reason}\t{lineno}\t{excerpt}")
PY

  pages=0
  checked=0
  failures=0
  while IFS=$'\t' read -r kind field_a field_b field_c rest; do
    case "$kind" in
      SUMMARY)
        pages="$field_a"
        checked="$field_b"
        failures="$field_c"
        ;;
    esac
  done < "$RESULT_FILE"

  # JSON mode: emit machine-readable JSON and exit (still respects DRY_RUN for report)
  if [[ "$JSON_MODE" == true ]]; then
    # SIDE EFFECT (write): creates a bones/tmp scratch file for JSON assembly (deleted below)
    json_tmp=$(mktemp "$TMP_DIR/links-json.XXXXXX")
    # Build JSON array from RESULT_FILE FAIL lines
    {
      echo "{"
      echo "  \"scan_root\": \"$(printf '%s' "$SCAN_ROOT" | sed 's/"/\\"/g')\","
      echo "  \"pages\": $pages,"
      echo "  \"checked\": $checked,"
      echo "  \"failures\": $failures,"
      echo "  \"failures_detail\": ["
      first=true
      while IFS=$'\t' read -r kind f_page f_raw f_reason f_line f_excerpt; do
        [[ "$kind" == "FAIL" ]] || continue
        # JSON escape via jq -R if available, else manual
        if command -v jq >/dev/null 2>&1; then
          j_page=$(printf '%s' "$f_page" | jq -R -s -c .)
          j_raw=$(printf '%s' "$f_raw" | jq -R -s -c .)
          j_reason=$(printf '%s' "$f_reason" | jq -R -s -c .)
          j_excerpt=$(printf '%s' "$f_excerpt" | jq -R -s -c .)
        else
          # fallback manual escape (replace " and \)
          j_page="\"$(printf '%s' "$f_page" | sed 's/\\/\\\\/g; s/"/\\"/g')\""
          j_raw="\"$(printf '%s' "$f_raw" | sed 's/\\/\\\\/g; s/"/\\"/g')\""
          j_reason="\"$(printf '%s' "$f_reason" | sed 's/\\/\\\\/g; s/"/\\"/g')\""
          j_excerpt="\"$(printf '%s' "$f_excerpt" | sed 's/\\/\\\\/g; s/"/\\"/g')\""
        fi
        # line is numeric, default 0 if empty
        f_line=${f_line:-0}
        [[ "$f_line" =~ ^[0-9]+$ ]] || f_line=0
        if [[ "$first" == true ]]; then
          first=false
        else
          echo ","
        fi
        printf '    {"source": %s, "target": %s, "type": %s, "line": %s, "excerpt": %s}' "$j_page" "$j_raw" "$j_reason" "$f_line" "$j_excerpt"
      done < "$RESULT_FILE"
      echo ""
      echo "  ]"
      echo "}"
    # SIDE EFFECT (write): serializes the assembled JSON into the scratch file
    } > "$json_tmp"
    # Validate JSON
    if command -v jq >/dev/null 2>&1; then
      if ! jq empty "$json_tmp" >/dev/null 2>&1; then
        log "ERROR" "Generated JSON is invalid"
        cat "$json_tmp" >&2
        # SIDE EFFECT (delete): removes the JSON scratch file before failing
        rm -f "$json_tmp"
        exit 1
      fi
    fi
    # Emit to fd 3 (visible even in QUIET) and to LOG_FILE
    # SIDE EFFECT (write): appends the JSON report to the per-run log under bones/logs
    if [[ -n "${LOG_FILE:-}" ]]; then
      cat "$json_tmp" >> "$LOG_FILE"
    fi
    cat "$json_tmp" >&3 2>/dev/null || cat "$json_tmp"
    # SIDE EFFECT (delete): removes the JSON scratch file after emit
    rm -f "$json_tmp"
    # In JSON mode, still write markdown report unless DRY_RUN, for consistency
    if [[ "$DRY_RUN" == false ]]; then
      mkdir -p "$(dirname -- "$REPORT_FILE")"
      # SIDE EFFECT (write): overwrites the link-audit markdown report
      {
        echo "# Rendered Link Audit (JSON mode)"
        echo
        echo "- Scan root: \`$SCAN_ROOT\`"
        echo "- Pages: $pages"
        echo "- Local links/assets checked: $checked"
        echo "- Failures: $failures"
      } > "$REPORT_FILE"
      log "INFO" "Link audit report written to $REPORT_FILE"
    else
      log "DRY-RUN" "Would write link audit report to $REPORT_FILE"
    fi
    [[ "$failures" -eq 0 ]]
    exit $?
  fi

  if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$(dirname -- "$REPORT_FILE")"
    # SIDE EFFECT (write): overwrites the link-audit markdown report
    {
      echo "# Rendered Link Audit"
      echo
      echo "- Scan root: \`$SCAN_ROOT\`"
      echo "- Pages: $pages"
      echo "- Local links/assets checked: $checked"
      echo "- Failures: $failures"
      echo
      if [[ "$failures" -eq 0 ]]; then
        echo "All local rendered links and asset references resolve."
      else
        echo "## Failures"
        echo
        # Grouped view is for MARKER output; report keeps flat list with line+excerpt
        while IFS=$'\t' read -r kind f_page f_raw f_reason f_line f_excerpt; do
          [[ "$kind" == "FAIL" ]] || continue
          echo "- **$f_reason** (line $f_line): \`$f_page\` → \`$f_raw\`"
          if [[ -n "$f_excerpt" ]]; then
            echo "  - excerpt: \`$(printf '%s' "$f_excerpt" | cut -c1-80)\`"
          fi
          if [[ "$FIX_HINT" == true ]]; then
            if [[ "$f_reason" == "missing anchor" ]]; then
              echo "  - hint: anchor not found — check that id exists in \`$f_page\` (case-sensitive) and that the link uses correct \`\`#fragment\`\`"
            elif [[ "$f_reason" == "missing file" ]]; then
              echo "  - hint: file not found under \`$SCAN_ROOT\` — verify source exists in \`${CONTENT_DIR#"$ROOT_DIR"/}\` and that \`.md\` was rewritten to \`.html\`"
            elif [[ "$f_reason" == "outside rendered root" ]]; then
              echo "  - hint: link escapes rendered root — use relative links within \`$SCAN_ROOT\`"
            fi
          fi
        done < "$RESULT_FILE"
      fi
    } > "$REPORT_FILE"
    log "INFO" "Link audit report written to $REPORT_FILE"
  else
    log "DRY-RUN" "Would write link audit report to $REPORT_FILE"
  fi

  # Human summary: grouped by source, with line+excerpt when verbose
  ok_count=$((checked - failures))
  [[ $ok_count -lt 0 ]] && ok_count=0
  # Count unique pages with failures
  fail_pages=$(awk -F'\t' '$1=="FAIL" {print $2}' "$RESULT_FILE" 2>/dev/null | sort -u | wc -l | tr -d ' ' || echo 0)
  if [[ "$failures" -eq 0 ]]; then
    log "MARKER" "✓ $ok_count/$checked links OK — 0 broken — output clean"
  else
    # Color is handled by rc-utils log MARKER (✗ red, ⚠️ yellow)
    log "MARKER" "✗ $ok_count/$checked links OK — $failures broken in $fail_pages pages — run with --verbose for excerpts, --json for machine"
  fi

  # Grouped MARKER output
  if [[ "$failures" -gt 0 ]]; then
    # Use associative array to group (bash 4+)
    declare -A page_counts=()
    declare -A page_lines=()
    while IFS=$'\t' read -r kind f_page f_raw f_reason f_line f_excerpt; do
      [[ "$kind" == "FAIL" ]] || continue
      # Count per page
      page_counts["$f_page"]=$((${page_counts["$f_page"]:-0} + 1))
      # Build line for verbose or default
      if [[ "$VERBOSE" == true ]]; then
        line_out="  $f_page:$f_line [$f_reason] $f_raw"
        if [[ -n "$f_excerpt" ]]; then
          line_out+=" — excerpt: $(printf '%s' "$f_excerpt" | cut -c1-80)"
        fi
        if [[ "$FIX_HINT" == true ]]; then
          if [[ "$f_reason" == "missing anchor" ]]; then
            line_out+=" — hint: anchor not found (check id in $f_page)"
          elif [[ "$f_reason" == "missing file" ]]; then
            line_out+=" — hint: file not found under $SCAN_ROOT"
          fi
        fi
        log "MARKER" "$line_out"
      else
        # Non-verbose: accumulate for grouped summary per page
        # Store first raw per page for hint
        if [[ -z "${page_lines["$f_page"]:-}" ]]; then
          page_lines["$f_page"]="$f_raw ($f_reason line $f_line)"
        fi
      fi
    done < "$RESULT_FILE"
    if [[ "$VERBOSE" == false ]]; then
      for p in "${!page_counts[@]}"; do
        cnt=${page_counts["$p"]}
        example=${page_lines["$p"]}
        if [[ "$FIX_HINT" == true ]]; then
          # Add hint suffix for grouped view
          hint_suffix=""
          # Find first reason for this page to tailor hint
          first_reason=$(awk -F'\t' -v pg="$p" '$1=="FAIL" && $2==pg {print $4; exit}' "$RESULT_FILE" 2>/dev/null || true)
          if [[ "$first_reason" == "missing anchor" ]]; then
            hint_suffix=" — hint: anchor not found"
          elif [[ "$first_reason" == "missing file" ]]; then
            hint_suffix=" — hint: file not found"
          fi
          log "MARKER" "$p: $cnt broken — e.g. $example$hint_suffix"
        else
          log "MARKER" "$p: $cnt broken — e.g. $example"
        fi
      done
    fi
    # Also show fix-hint footer when not verbose and fix-hint not already shown
    if [[ "$FIX_HINT" == false && "$VERBOSE" == false ]]; then
      log "MARKER" "  run with --fix-hint for per-failure hints, --json for machine"
    fi
  fi

  [[ "$failures" -eq 0 ]]
}

main "$@"
