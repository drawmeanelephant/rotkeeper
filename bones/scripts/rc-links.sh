#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# ============================================================
#  Project : Rotkeeper
#  Script  : rc-links.sh
#  Purpose : Audit rendered HTML links and local asset references
#  Version : 0.5.0
# ============================================================

show_help() {
  cat <<'EOF'
rc-links.sh — Audit rendered HTML links and local asset references

Usage: rotkeeper.sh links [options]

Options:
  --root DIR       Rendered directory to scan; defaults to output/
  --report FILE    Report destination; defaults to bones/reports/link-report-*.md
  --dry-run        Scan without writing a report
  --verbose        Show detailed logs
  --help, -h       Show this help message
EOF
  exit 0
}

VERSION="${ROTKEEPER_VERSION:-0.5.0}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
rk_init_script "rc-links" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR OUTPUT_DIR REPORT_DIR

SCAN_ROOT="$OUTPUT_DIR"
REPORT_FILE=""

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
    --dry-run|--verbose|--help|-h)
      shift
      ;;
    *)
      log "ERROR" "Unknown option: $1"
      exit 1
      ;;
  esac
done

cleanup() {
  if [[ -n "${RESULT_FILE:-}" ]]; then
    rm -f "$RESULT_FILE"
  fi
}

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
        self.links = []
        self.ids = set()

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        self.ids.update(x for x in (attrs.get("id"), attrs.get("name")) if x)
        attribute = "href" if tag == "a" else "src" if tag in {"script", "img", "source", "video", "audio"} else None
        if attribute and attrs.get(attribute):
            self.links.append((tag, attrs[attribute]))

pages = sorted(root.rglob("*.html"))
checked = 0
failures = []

for page in pages:
    parser = Page()
    parser.feed(page.read_text(errors="replace"))
    for tag, raw in parser.links:
        value = unquote(raw.strip())
        parsed = urlsplit(value)
        if not value or value.startswith(("mailto:", "tel:", "javascript:")) or parsed.scheme or parsed.netloc:
            continue
        if parsed.path == "":
            if parsed.fragment and parsed.fragment not in parser.ids:
                failures.append((page.relative_to(root), raw, "missing anchor"))
            continue

        candidate = (root / parsed.path.lstrip("/")) if parsed.path.startswith("/") else (page.parent / parsed.path)
        candidate = candidate.resolve()
        if candidate != root and root not in candidate.parents:
            failures.append((page.relative_to(root), raw, "outside rendered root"))
        else:
            if candidate.is_dir():
                candidate /= "index.html"
            if not candidate.exists():
                failures.append((page.relative_to(root), raw, "missing file"))
        checked += 1

print(f"SUMMARY\t{len(pages)}\t{checked}\t{len(failures)}")
for page, raw, reason in failures:
    print(f"FAIL\t{page}\t{raw}\t{reason}")
PY

  pages=0
  checked=0
  failures=0
  while IFS=$'\t' read -r kind field_a field_b field_c; do
    case "$kind" in
      SUMMARY)
        pages="$field_a"
        checked="$field_b"
        failures="$field_c"
        ;;
    esac
  done < "$RESULT_FILE"

  if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$(dirname -- "$REPORT_FILE")"
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
        while IFS=$'\t' read -r kind field_a field_b field_c; do
          [[ "$kind" == "FAIL" ]] || continue
          echo "- **$field_c**: \`$field_a\` → \`$field_b\`"
        done < "$RESULT_FILE"
      fi
    } > "$REPORT_FILE"
    log "INFO" "Link audit report written to $REPORT_FILE"
  else
    log "DRY-RUN" "Would write link audit report to $REPORT_FILE"
  fi

  log "MARKER" "Rendered link audit: pages=$pages links_checked=$checked failures=$failures"
  while IFS=$'\t' read -r kind field_a field_b field_c; do
    [[ "$kind" == "FAIL" ]] || continue
    log "MARKER" "Link failure [$field_c]: $field_a -> $field_b"
  done < "$RESULT_FILE"

  [[ "$failures" -eq 0 ]]
}

main "$@"
