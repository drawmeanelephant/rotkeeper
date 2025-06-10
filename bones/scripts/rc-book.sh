#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-book.sh
# Purpose: Binder ritual for scriptbook, docbook, webbook, and collapse mode
# Version: 0.2.5-pre
# Updated: 2025-06-02
# -----------------------------------------

set -euo pipefail
trap 'echo "Error on line $LINENO"; exit 1' ERR

# Source utility functions, which includes require_gawk_version and sources rc-env.sh via source_rc_env()
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"

# Ensure GNU Awk is available before any awk-based operations
require_gawk_version

# Defaults
MODE=""
CONFIG=""
DRY_RUN=false
STRIP_MODE=false

show_help() {
  cat <<EOF
Usage: rc-book.sh [--scriptbook-full|--docbook|--all|--collapse|--docbook-clean|--configbook|--contentbook|--contentmeta] [--config file]

  --scriptbook-full  Bind full scripts with relative paths and fences into rotkeeper-scriptbook-full.md
  --docbook          Bind meta documentation into rotkeeper-docbook.md
  --all              Run all 3 binder rituals above
  --collapse         Summarize all rotkeeper-*.md files into collapsed-content.yaml (YAML structure for tools or downstream pipelines)
  --docbook-clean    Bind meta documentation into rotkeeper-docbook-clean.md (frontmatter stripped)
  --configbook       Bind config + template files into rotkeeper-configbook.md
  --contentbook      Bind all markdown in home/content/ into rotkeeper-contentbook.md
  --contentmeta      Extract frontmatter YAML metadata from content markdown files into rotkeeper-contentmeta.yaml
  --config FILE      Optional config file for future filtering logic
  --dry-run          Show what would be done without making changes
  --help             Show this helpful void

EOF
}

parse_flags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --scriptbook-full) MODE="scriptbook_full"; shift ;;
      --docbook)         MODE="docbook"; shift ;;
      --all)             MODE="all"; shift ;;
      --collapse)        MODE="collapse"; shift ;;
      --docbook-clean)   MODE="docbook_clean"; shift ;;
      --configbook)      MODE="configbook"; shift ;;
      --contentbook)     MODE="contentbook"; shift ;;
      --contentmeta)     MODE="contentmeta"; shift ;;
      --config)          CONFIG="$2"; shift 2 ;;
      --dry-run)         DRY_RUN=true; shift ;;
      --strip-frontmatter) STRIP_MODE=true; shift ;;
      --help)            show_help; exit 0 ;;
      *) echo "Unknown option: $1"; show_help; exit 1 ;;
    esac
  done
}

run_scriptbook_full() {
  local OUT="$REPORT_DIR/rotkeeper-scriptbook-full.md"

  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY-RUN] Would generate full scriptbook at: $OUT"
    find "$ROOT_DIR"/bones/scripts "$ROOT_DIR" -maxdepth 1 -type f \( -name 'rc-*.sh' -o -name 'rotkeeper.sh' \) | sort | while read -r script; do
      rel="${script#$ROOT_DIR/}"
      echo "  - $rel"
    done
    return 0
  fi

  echo "---" > "$OUT"
  echo "title: \"Rotkeeper Scriptbook (Full)\"" >> "$OUT"
  echo "subtitle: \"All \`rc-*.sh\` rituals with relative paths and fences\"" >> "$OUT"
  echo "generated: \"$(date +'%Y-%m-%d')\"" >> "$OUT"
  echo "---" >> "$OUT"
  echo "" >> "$OUT"

  find "$ROOT_DIR"/bones/scripts "$ROOT_DIR" -maxdepth 1 -type f \( -name 'rc-*.sh' -o -name 'rotkeeper.sh' \) | sort | while read -r script; do
    rel="${script#$ROOT_DIR/}"
    echo "<!-- START: $rel -->" >> "$OUT"
    echo "" >> "$OUT"
    # Write script content without markdown code fences to prevent resurrection errors
    while IFS= read -r line; do
      [[ "$line" == '```' ]] && continue
      echo "$line"
    done < "$script" >> "$OUT"
    echo "<!-- END: $rel -->" >> "$OUT"
    echo "" >> "$OUT"
  done

  echo "[✔] Full Scriptbook written to $OUT"
}

run_docbook() {
  local OUT="$REPORT_DIR/rotkeeper-docbook.md"

  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY-RUN] Would generate docbook at: $OUT"
    return 0
  fi

  echo "---" > "$OUT"
  echo "title: \"Rotkeeper Docbook\"" >> "$OUT"
  echo "subtitle: \"All markdown documentation in home/content/docs/ with path markers\"" >> "$OUT"
  echo "---" >> "$OUT"
  echo "" >> "$OUT"

  mapfile -t doc_files < <(find "$DOCS_DIR" -name '*.md' -type f | sort)
  for file in "${doc_files[@]}"; do
    rel="${file#$ROOT_DIR/}"
    echo "<!-- START: $rel -->" >> "$OUT"
    echo "" >> "$OUT"
    # Write markdown content with optional frontmatter handling
    awk -v do_strip="$STRIP_MODE" '
      BEGIN { in_yaml = 0 }
      {
        if ($0 ~ /^---$/) {
          in_yaml++
          if (do_strip == "true") next
          print
          next
        }
        if (do_strip == "true" && in_yaml < 2) next
        print
      }
    ' "$file" >> "$OUT"
    echo "<!-- END: $rel -->" >> "$OUT"
    echo "" >> "$OUT"
  done

  echo "[✔] Docbook written to $OUT"
}

# TODO: Consider merging this into docbook with a --strip-frontmatter flag for cleaner maintenance
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

# Main entry
run_configbook() {
  local OUT="$REPORT_DIR/rotkeeper-configbook.md"

  echo "---" > "$OUT"
  echo "title: \"Rotkeeper Configbook\"" >> "$OUT"
  echo "subtitle: \"YAML configuration and templates used by rotkeeper\"" >> "$OUT"
  echo "---" >> "$OUT"
  echo "" >> "$OUT"

  find "$ROOT_DIR/bones/config" "$ROOT_DIR/bones/templates" \
    -type f \( -name '*.yaml' -o -name '*.yml' -o -name '*.tpl' -o -name '*.html' \) | sort | while read -r file; do
    rel="${file#$ROOT_DIR/}"
    echo "<!-- START: $rel -->" >> "$OUT"
    echo "" >> "$OUT"
    # Write config content without markdown code fences to ensure clean resurrection
    while IFS= read -r line; do
      [[ "$line" == '```' ]] && continue
      echo "$line"
    done < "$file" >> "$OUT"
    echo "<!-- END: $rel -->" >> "$OUT"
    echo "" >> "$OUT"
  done

  echo "[✔] Configbook written to $OUT"
}

run_contentbook() {
  local OUT="$REPORT_DIR/rotkeeper-contentbook.md"

  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY-RUN] Would generate full contentbook at: $OUT"
    return 0
  fi

  echo "---" > "$OUT"
  echo "title: \"Rotkeeper Contentbook\"" >> "$OUT"
  echo "subtitle: \"All markdown in home/content/ with path markers\"" >> "$OUT"
  echo "---" >> "$OUT"
  echo "" >> "$OUT"

  mapfile -t content_files < <(find "$CONTENT_DIR" -name '*.md' -type f | sort)
  for file in "${content_files[@]}"; do
    rel="${file#$ROOT_DIR/}"
    echo "<!-- START: $rel -->" >> "$OUT"
    echo "" >> "$OUT"
    awk -v do_strip="$STRIP_MODE" '
      BEGIN { in_yaml = 0; yaml_complete = 0; line_number = 0 }
      {
        line_number++
        if (line_number == 1 && $0 ~ /^---$/) {
          in_yaml = 1
          if (do_strip == "true") next
          print
          next
        }
        if (in_yaml == 1 && $0 ~ /^---$/) {
          in_yaml = 2
          if (do_strip == "true") { yaml_complete = 1; next }
          print
          next
        }
        if (do_strip == "true" && in_yaml == 1) next
        if (do_strip == "true" && in_yaml == 2 && yaml_complete == 0) next
        print
      }
    ' "$file" >> "$OUT"
    echo "<!-- END: $rel -->" >> "$OUT"
    echo "" >> "$OUT"
  done

  echo "[✔] Contentbook written to $OUT"
}

run_contentmeta() {
  local OUT="$REPORT_DIR/rotkeeper-contentmeta.yaml"

  echo "[INFO] Extracting frontmatter YAML from content files..."
  echo "" > "$OUT"

  find "$CONTENT_DIR" -name '*.md' -type f | sort | while read -r file; do
    rel="${file#$ROOT_DIR/}"

    awk -v path="$rel" '
      BEGIN { in_yaml=0; print "- path: \"" path "\"" }
      /^---$/ { in_yaml++; next }
      in_yaml==1 { print "  " $0 }
      /^---$/ && in_yaml==2 { exit }
    ' "$file" >> "$OUT"

    echo "" >> "$OUT"
  done

  echo "[✔] Content metadata written to $OUT"
}

run_mode() {
  case "$MODE" in
    scriptbook_full)
      run_scriptbook_full
      ;;
    docbook)
      run_docbook
      ;;
    docbook_clean)
      run_docbook_clean
      ;;
    configbook)
      run_configbook
      ;;
    contentbook)
      run_contentbook
      ;;
    contentmeta)
      run_contentmeta
      ;;
    all)
      if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY-RUN] Would generate full scriptbook at: $REPORT_DIR/rotkeeper-scriptbook-full.md"
        echo "[DRY-RUN] Would generate docbook at: $REPORT_DIR/rotkeeper-docbook.md"
        echo "[DRY-RUN] Would generate cleaned docbook at: $REPORT_DIR/rotkeeper-docbook-clean.md"
      else
        run_scriptbook_full
        run_docbook
        run_docbook_clean
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