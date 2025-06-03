#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-book.sh
# Purpose: Binder ritual for scriptbook, docbook, webbook, and collapse mode
# Version: 0.2.5-pre
# Updated: 2025-06-02
# -----------------------------------------

set -euo pipefail
trap 'echo "Error on line $LINENO"; exit 1' ERR

# Source shared environment variables
source "$(dirname "${BASH_SOURCE[0]}")/rc-env.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPORT_DIR="$PROJECT_ROOT/bones/reports"

# Defaults
MODE=""
CONFIG=""
DRY_RUN=false

show_help() {
  cat <<EOF
Usage: rc-book.sh [--scriptbook|--docbook|--webbook|--all|--collapse|--docbook-clean] [--config file]

  --scriptbook   Bind full source + comments into rotkeeper-scriptbook.md
  --docbook      Bind meta documentation into rotkeeper-docbook.md
  --webbook      Bind public markdown into rotkeeper-webbook.md
  --all          Run all 3 binder rituals above
  --collapse     Collapse all rotkeeper-*.md into collapsed-content.yaml
  --docbook-clean  Bind meta documentation into rotkeeper-docbook-clean.md (frontmatter stripped)
  --config FILE  Optional config file for future filtering logic
  --dry-run      Show what would be done without making changes
  --help         Show this helpful void

EOF
}

parse_flags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --scriptbook) MODE="scriptbook"; shift ;;
      --docbook)    MODE="docbook"; shift ;;
      --webbook)    MODE="webbook"; shift ;;
      --all)        MODE="all"; shift ;;
      --collapse)   MODE="collapse"; shift ;;
      --docbook-clean) MODE="docbook_clean"; shift ;;
      --config)     CONFIG="$2"; shift 2 ;;
      --dry-run)    DRY_RUN=true; shift ;;
      --help)       show_help; exit 0 ;;
      *) echo "Unknown option: $1"; show_help; exit 1 ;;
    esac
  done
}

run_scriptbook() {
  local OUT="$REPORT_DIR/rotkeeper-scriptbook.md"

  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY-RUN] Would generate scriptbook at: $OUT"
    return 0
  fi

  echo "---" > "$OUT"
  echo "title: \"Rotkeeper Scriptbook\"" >> "$OUT"
  echo "subtitle: \"Generated from script docblocks\"" >> "$OUT"
  echo "---" >> "$OUT"

  for script in "$PROJECT_ROOT"/bones/scripts/rc-*.sh; do
    echo "## $(basename "$script")" >> "$OUT"
    echo '```bash' >> "$OUT"
    cat "$script" >> "$OUT"
    echo '```' >> "$OUT"
    echo "" >> "$OUT"
  done

  echo "[✔] Scriptbook written to $OUT"
}

run_docbook() {
  local OUT="$REPORT_DIR/rotkeeper-docbook.md"

  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY-RUN] Would generate docbook at: $OUT"
    return 0
  fi

  echo "---" > "$OUT"
  echo "title: \"Home Content\"" >> "$OUT"
  echo "subtitle: \"Structured documentation from meta/\"" >> "$OUT"
  echo "---" >> "$OUT"
  echo "" >> "$OUT"

  mapfile -t doc_files < <(find "$DOCS_DIR" -name '*.md' -type f | sort)
  for file in "${doc_files[@]}"; do
    # [[ -f "$file" ]] || continue
    echo "# $(basename "$file")" >> "$OUT"
    echo "" >> "$OUT"
    cat "$file" >> "$OUT"
    echo "" >> "$OUT"
  done

  echo "[✔] Docbook written to $OUT"
}

run_docbook_clean() {
  local OUT="$REPORT_DIR/rotkeeper-docbook-clean.md"

  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY-RUN] Would generate cleaned docbook at: $OUT"
    return 0
  fi

  echo "---" > "$OUT"
  echo "title: \"Home Content (Cleaned)\"" >> "$OUT"
  echo "subtitle: \"Frontmatter-stripped, collapse-friendly version\"" >> "$OUT"
  echo "---" >> "$OUT"
  echo "" >> "$OUT"

  find "$DOCS_DIR" -name '*.md' -type f | sort | while read -r file; do
    local TITLE
    TITLE=$(awk 'BEGIN {found=0} /^\-\-\-/ {found+=1; next} found==1 && /^title:/ {print substr($0, index($0,$2))}' "$file" | head -n1 | sed 's/^"//; s/"$//')
    [[ -z "$TITLE" ]] && TITLE=$(basename "$file" .md)

    echo "## $TITLE" >> "$OUT"
    echo "" >> "$OUT"

    awk '
      BEGIN {in_yaml = 0}
      {
        if ($0 ~ /^---/) {
          in_yaml++
          next
        }
        if (in_yaml >= 2) {
          print
        }
      }
    ' "$file" >> "$OUT"

    echo "" >> "$OUT"
  done

  echo "[✔] Cleaned Docbook written to $OUT"
}

run_webbook() {
  local OUT="$REPORT_DIR/rotkeeper-webbook.md"

  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY-RUN] Would generate webbook at: $OUT"
    return 0
  fi

  {
    echo "---"
    echo "title: \"Rotkeeper Webbook\""
    echo "subtitle: \"Compiled from rendered HTML pages in home/content/\""
    echo "---"
    echo ""
  } > "$OUT"

  find "$PROJECT_ROOT/home/content" -name '*.html' -print0 | sort -z |
  while IFS= read -r -d '' file; do
    echo "[INFO] Appending: $file"
    echo "<!-- FILE: ${file} -->" >> "$OUT"
    cat "$file" >> "$OUT"
    echo -e "\n<!-- END: ${file} -->" >> "$OUT"
  done

  echo "[✔] Webbook written to $OUT"
}

run_mode() {
  case "$MODE" in
    scriptbook)
      run_scriptbook
      ;;
    docbook)
      run_docbook
      ;;
    docbook_clean)
      run_docbook_clean
      ;;
    webbook)
      run_webbook
      ;;
    all)
      if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY-RUN] Would generate scriptbook at: $REPORT_DIR/rotkeeper-scriptbook.md"
        echo "[DRY-RUN] Would generate docbook at: $REPORT_DIR/rotkeeper-docbook.md"
        echo "[DRY-RUN] Would generate webbook at: $REPORT_DIR/rotkeeper-webbook.md"
      else
        run_scriptbook
        run_docbook
        run_webbook
      fi
      ;;
    collapse)
      echo "[INFO] Collapsing reports into YAML..."

      mkdir -p "$REPORT_DIR"

      OUTPUT="$REPORT_DIR/collapsed-content.yaml"
      > "$OUTPUT"

      for file in "$REPORT_DIR"/rotkeeper-*.md; do
        [[ -f "$file" ]] || continue

        filename=$(basename "$file")

        echo "[DEBUG] Reading: $file" >&2

        title=$(awk 'BEGIN {found=0} /^\-\-\-/ {found+=1; next} found==1 && /^title:/ {print substr($0, index($0,$2))}' "$file" | head -n1 | sed 's/^"//; s/"$//')
        subtitle=$(awk 'BEGIN {found=0} /^\-\-\-/ {found+=1; next} found==1 && /^subtitle:/ {print substr($0, index($0,$2))}' "$file" | head -n1 | sed 's/^"//; s/"$//')
        echo "[DEBUG] → Found: $filename | title: '$title' | subtitle: '$subtitle'" >&2

        if [[ -z "$title" ]]; then
          echo "[WARN] No title in frontmatter for $filename — falling back to basename." >&2
          title=$(basename "$file" .md)
        fi

        echo "- filename: \"$filename\"" >> "$OUTPUT"
        echo "  title: \"$title\"" >> "$OUTPUT"
        echo "  subtitle: \"$subtitle\"" >> "$OUTPUT"
        echo "  body: |" >> "$OUTPUT"
        awk 'BEGIN{skip=1} /^---/ {if (skip==1) {skip=0; next}; if (skip==0) {nextfile}} skip==0' "$file" | sed 's/^/    /' >> "$OUTPUT"
      done

      echo "" >> "$OUTPUT"

      echo "[DONE] Wrote: $OUTPUT"
      ;;
    *)
      echo "[WARN] No mode selected — defaulting to '--all'"
      MODE="all"
      run_mode
      ;;
  esac
}

# Main entry
parse_flags "$@"
run_mode