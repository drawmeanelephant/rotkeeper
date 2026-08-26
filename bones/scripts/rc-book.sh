#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# ============================================================
#  ██████╗  ██████╗  ██████╗ ██╗  ██╗
#  ██╔══██╗██╔═══██╗██╔═══██╗██║ ██╔╝
#  ██████╔╝██║   ██║██║   ██║█████╔╝
#  ██╔══██╗██║   ██║██║   ██║██╔═██╗
#  ██████╔╝╚██████╔╝╚██████╔╝██║  ██╗
#  ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝
# ============================================================
#  Project : Rotkeeper
#  Script  : rc-book.sh
#  Purpose : Bind documentation reports cleanly inside authorized boundaries
#  Version : 0.5.1
# ============================================================


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }

# ---
# show_help: Display primary help for binder modes.
# Inputs: none
# Outputs: Prints help to stdout
# ---
show_help() {
  cat <<'HELP_EOF'
rc-book.sh — Aggregate documentation into bound book reports

Modes:
  --fsbook          Filesystem catalog consumed by DIP for core-file discovery
  --docbook         Bind documentation pages
  --docbook-clean   Bind documentation pages, cleaning stale targets
  --scriptbook-full Bind active scripts
  --configbook      Bind configuration and templates
  --contentbook     Bind content pages
  --contentmeta     Emit content metadata
  --collapse        Collapse a book or content tree
  --force-bind      Allow larger than safe default bind

Options:
  --dry-run      Preview the bind without writing
  --verbose      Detailed output
  --help, -h     Show help
  --version, -v  Show version and quit
HELP_EOF
}

rk_init_script "rc-book" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR TEMPLATE_DIR LOG_DIR TMP_DIR REPORT_DIR BOOK_REPORT_DIR DOCS_DIR CONTENT_DIR

set -euo pipefail
IFS=$'\n\t'

require_gawk_version

MODE=""
CONFIG=""
STRIPMODE=false
FORCE_BIND=false

# ---
# showhelp: Display secondary help with --strip-frontmatter details.
# Inputs: none
# Outputs: Prints help to stdout
# ---
showhelp() {
  cat <<HELP_EOF
rc-book.sh — Documentation binder ritual

Usage: rc-book.sh [mode] [options]

Modes:
  --scriptbook-full   Bind all active rc-*.sh scripts dynamically
  --docbook           Bind docs into rotkeeper-docbook.md
  --docbook-clean     Bind docs, frontmatter stripped
  --configbook        Bind config/templates into rotkeeper-configbook.md
  --fsbook            Bind project file system catalog into rotkeeper-files.md
  --force-bind        Bypass memory budget safeguards
  --contentbook       Bind all home/content markdown into rotkeeper-contentbook.md
  --contentmeta       Extract frontmatter YAML into rotkeeper-contentmeta.yaml
  --collapse          Collapse all rotkeeper-*.md into collapsed-content.yaml
  --all               Run all documentation and book bindings exhaustive

Options:
  --config FILE       Optional config file
  --dry-run           Show what would be done without making changes
  --strip-frontmatter Strip frontmatter from output where applicable
  --verbose           Enable verbose logging
  --help              Show this help message
HELP_EOF
}

# ---
# parseflags: Parse binder mode flags and options into globals.
# Inputs: $@ (CLI args)
# Outputs: Sets MODE, CONFIG, STRIPMODE, FORCE_BIND; exits on --help/unknown
# ---
parseflags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --version|-v) echo "$(basename "$0") v${VERSION:-unknown}"; exit 0 ;;
      --scriptbook-full)   MODE=scriptbookfull; shift ;;
      --docbook)           MODE=docbook; shift ;;
      --all)               MODE=all; shift ;;
      --collapse)          MODE=collapse; shift ;;
      --docbook-clean)     MODE=docbookclean; shift ;;
      --configbook)        MODE=configbook; shift ;;
      --fsbook)            MODE=fsbook; shift ;;
      --contentbook)       MODE=contentbook; shift ;;
      --contentmeta)       MODE=contentmeta; shift ;;
      --config)            CONFIG="$2"; shift 2 ;;
      --dry-run)           shift ;;
      --strip-frontmatter) STRIPMODE=true; shift ;;
      --force-bind)        FORCE_BIND=true; shift ;;
      --verbose)           shift ;;
      --help|-h)           showhelp; exit 0 ;;
      *) echo "Unknown option: $1"; showhelp; exit 1 ;;
    esac
  done
}

# Ensure write directory safety boundary
validate_boundary() {
  local target_path="$1"
  if [[ "$target_path" != "$ROOT_DIR"* && "$target_path" != "$BOOK_REPORT_DIR"* ]]; then
    log "ERROR" "Boundary violation: Attempted write outside authorized zones: $target_path"
    exit 3
  fi
}

# ---
# runscriptbookfull: Bind active rc-*.sh plus rotkeeper.sh into scriptbook.
# Inputs: none; reads SCRIPT_DIR, ROOT_DIR, BOOK_REPORT_DIR, BOOK_SUFFIX
# Outputs: Writes rotkeeper-scriptbook-full.md
# ---
runscriptbookfull() {
  mkdir -p "$BOOK_REPORT_DIR"
  local OUT="$BOOK_REPORT_DIR/rotkeeper-scriptbook-full.md"
  validate_boundary "$OUT"

  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "Would generate full scriptbook at $OUT"
    while read -r script; do
      echo "  - ${script#"$ROOT_DIR"/}"
    done < <(find "$SCRIPT_DIR" -maxdepth 1 -type f -name "rc-*.sh" | sort)
    while read -r script; do
      echo "  - ${script#"$ROOT_DIR"/}"
    done < <(find "$ROOT_DIR" -maxdepth 1 -type f -name "rotkeeper.sh")
    return 0
  fi

  {
    echo "---"
    echo "title: Rotkeeper Scriptbook Full"
    echo "subtitle: All active rc-*.sh rituals dynamically discovered"
    echo "generated: $(date +%Y-%m-%d)"
    echo "---"
    echo ""
  } > "$OUT"

  while read -r script; do
    if [[ -f "$script" ]]; then
      rel="${script#"$ROOT_DIR"/}"
      {
        echo "<!-- START $rel::$BOOK_SUFFIX -->"
        echo ""
        echo '```bash'
        cat "$script"
        echo '```'
        echo "<!-- END $rel::$BOOK_SUFFIX -->"
        echo ""
      } >> "$OUT"
    fi
  done < <({ find "$SCRIPT_DIR" -maxdepth 1 -type f -name "rc-*.sh"; find "$ROOT_DIR" -maxdepth 1 -type f -name "rotkeeper.sh"; } | sort)
  log "INFO" "Full Scriptbook written to $OUT"
}

# ---
# rundocbook: Bind DOCS_DIR docs with path markers into docbook.
# Inputs: none; reads DOCS_DIR, STRIPMODE
# Outputs: Writes rotkeeper-docbook.md
# ---
rundocbook() {
  mkdir -p "$BOOK_REPORT_DIR"
  local OUT="$BOOK_REPORT_DIR/rotkeeper-docbook.md"
  validate_boundary "$OUT"
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "Would generate docbook at $OUT"
    return 0
  fi
  {
    echo "---"
    echo "title: Rotkeeper Docbook"
    echo "subtitle: All documentation sources with path markers"
    echo "---"
    echo ""
  } > "$OUT"
  # Find all 3 content formats (md/textile/cook) — sorted for deterministic book order
  mapfile -t docfiles < <(find "$DOCS_DIR" -type f \( -name "*.md" -o -name "*.textile" -o -name "*.cook" \) | sort)
  for file in ${docfiles[@]+"${docfiles[@]}"}; do
    if [[ -f "$file" ]]; then
      rel="${file#"$ROOT_DIR"/}"
      {
        echo "<!-- START $rel::$BOOK_SUFFIX -->"
        echo ""
        if [[ "$STRIPMODE" == "true" ]]; then
          rk_strip_frontmatter "$file"
        else
          awk '{ print }' "$file"  # cat via awk keeps pipeline shape uniform
        fi
        echo "<!-- END $rel::$BOOK_SUFFIX -->"
        echo ""
      } >> "$OUT"
    fi
  done
  log "INFO" "Docbook written to $OUT"
}

# ---
# rundocbookclean: Bind docs with frontmatter stripped and title headings.
# Inputs: none; reads DOCS_DIR
# Outputs: Writes rotkeeper-docbook-clean.md
# ---
rundocbookclean() {
  mkdir -p "$BOOK_REPORT_DIR"
  local OUT="$BOOK_REPORT_DIR/rotkeeper-docbook-clean.md"
  validate_boundary "$OUT"
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "Would generate cleaned docbook at $OUT"
    return 0
  fi
  {
    echo "---"
    echo "title: Home Content Cleaned"
    echo "subtitle: Frontmatter-stripped, collapse-friendly version"
    echo "---"
    echo ""
  } > "$OUT"
  # Same 3-format find sorted deterministically; derivate title from basename stripped of any of the 3 extensions
  while read -r file; do
    if [[ -f "$file" ]]; then
      local TITLE
      TITLE=$(rk_frontmatter_field "title" "$file")
      [[ -z "$TITLE" ]] && TITLE=$(basename -- "$file" .md) && TITLE="${TITLE%.textile}" && TITLE="${TITLE%.cook}"
      {
        echo "$TITLE"
        echo ""
        rk_strip_frontmatter "$file"
        echo ""
      } >> "$OUT"
    fi
  done < <(find "$DOCS_DIR" -type f \( -name "*.md" -o -name "*.textile" -o -name "*.cook" \) | sort)
  log "INFO" "Cleaned Docbook written to $OUT"
}

# ---
# runconfigbook: Bind YAML config and HTML templates into configbook.
# Inputs: none; reads CONFIG_DIR, TEMPLATE_DIR
# Outputs: Writes rotkeeper-configbook.md
# ---
runconfigbook() {
  mkdir -p "$BOOK_REPORT_DIR"
  local OUT="$BOOK_REPORT_DIR/rotkeeper-configbook.md"
  validate_boundary "$OUT"
  {
    echo "---"
    echo "title: Rotkeeper Configbook"
    echo "subtitle: YAML configuration and templates used by rotkeeper"
    echo "---"
    echo ""
  } > "$OUT"
  # Config/template find covers yaml/yml/tpl/html across both dirs; sort for reproducibility
  while read -r file; do
    if [[ -f "$file" ]]; then
      rel="${file#"$ROOT_DIR"/}"
      {
        echo "<!-- START $rel::$BOOK_SUFFIX -->"
        echo ""
        cat "$file"
        echo "<!-- END $rel::$BOOK_SUFFIX -->"
        echo ""
      } >> "$OUT"
    fi
  done < <(find "$CONFIG_DIR" "$TEMPLATE_DIR" -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.tpl" -o -name "*.html" \) 2>/dev/null | sort)
  log "INFO" "Configbook written to $OUT"
}

# ---
# runcontentbook: Bind CONTENT_DIR pages with path markers into contentbook.
# Inputs: none; reads CONTENT_DIR, STRIPMODE
# Outputs: Writes rotkeeper-contentbook.md
# ---
runcontentbook() {
  mkdir -p "$BOOK_REPORT_DIR"
  local OUT="$BOOK_REPORT_DIR/rotkeeper-contentbook.md"
  validate_boundary "$OUT"
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "Would generate full contentbook at $OUT"
    return 0
  fi
  {
    echo "---"
    echo "title: Rotkeeper Contentbook"
    echo "subtitle: All content sources with path markers"
    echo "---"
    echo ""
  } > "$OUT"
  # Same 3-format find sorted deterministically for content order
  mapfile -t contentfiles < <(find "$CONTENT_DIR" -type f \( -name "*.md" -o -name "*.textile" -o -name "*.cook" \) | sort)
  for file in ${contentfiles[@]+"${contentfiles[@]}"}; do
    if [[ -f "$file" ]]; then
      rel="${file#"$ROOT_DIR"/}"
      {
        echo "<!-- START $rel::$BOOK_SUFFIX -->"
        echo ""
        if [[ "$STRIPMODE" == "true" ]]; then
          rk_strip_frontmatter "$file"
        else
          awk '{ print }' "$file"
        fi
        echo "<!-- END $rel::$BOOK_SUFFIX -->"
        echo ""
      } >> "$OUT"
    fi
  done
  log "INFO" "Contentbook written to $OUT"
}

# ---
# runcontentmeta: Extract frontmatter YAML from content sources to YAML index.
# Inputs: none; reads CONTENT_DIR via rk_find_content (NUL-delimited)
# Outputs: Writes rotkeeper-contentmeta.yaml
# ---
runcontentmeta() {
  mkdir -p "$BOOK_REPORT_DIR"
  local OUT="$BOOK_REPORT_DIR/rotkeeper-contentmeta.yaml"
  validate_boundary "$OUT"
  log "INFO" "Extracting frontmatter YAML from content files..."
  echo "" > "$OUT"
  # Iterate NUL-delimited content files (safe for spaces/newlines); rk_find_content emits -print0
  while IFS= read -r -d '' file; do
    if [[ -f "$file" ]]; then
      rel="${file#"$ROOT_DIR"/}"
      # awk extracts YAML frontmatter block (between first two --- lines) into indented mapping
      awk -v path="$rel" '
        BEGIN { inyaml=0 }
        /^---$/ { inyaml++; if (inyaml==1) { print "- path: " path }; next }
        inyaml==1 { print "  " $0; next }
        inyaml>=2 { exit }
      ' "$file" >> "$OUT"
      echo "" >> "$OUT"
    fi
  done < <(rk_find_content "$CONTENT_DIR" md textile cook | sort -z)
  log "INFO" "Content metadata written to $OUT"
}

# ---
# runfsbook: Build filesystem catalog excluding generated/cache trees.
# Inputs: none; reads ROOT_DIR, OUTPUT_DIR, TMP_DIR, LOG_DIR, REPORT_DIR, BOOK_REPORT_DIR, ARCHIVE_DIR
# Outputs: Writes rotkeeper-files.md
# ---
runfsbook() {
  mkdir -p "$BOOK_REPORT_DIR"
  local OUT="$BOOK_REPORT_DIR/rotkeeper-files.md"
  validate_boundary "$OUT"
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "Would generate file system catalog at $OUT"
    return 0
  fi
  {
    echo "---"
    echo "title: Rotkeeper File System Catalog"
    echo "subtitle: Complete directory listing of the project"
    echo "generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "---"
    echo ""
    while read -r f; do
      echo "- $f"
    done < <(
      cd "$ROOT_DIR" || exit 1
      local_rel_output="${OUTPUT_DIR#"$ROOT_DIR"/}"
      local_rel_tmp="${TMP_DIR#"$ROOT_DIR"/}"
      local_rel_logs="${LOG_DIR#"$ROOT_DIR"/}"
      local_rel_reports="${REPORT_DIR#"$ROOT_DIR"/}"
      local_rel_books="${BOOK_REPORT_DIR#"$ROOT_DIR"/}"
      local_rel_archive="${ARCHIVE_DIR#"$ROOT_DIR"/}"
      # Prune generated/cache trees (git, ide, output, tmp, logs, reports, books, archive) then list remaining files; sed strips ./ prefix, sort for determinism
      find . -type d \( -path ./.git -o -path ./.freebuff -o -path ./.vscode -o -path ./.idea -o -path "./$local_rel_output" -o -path "./$local_rel_tmp" -o -path "./$local_rel_logs" -o -path "./$local_rel_reports" -o -path "./$local_rel_books" -o -path "./$local_rel_archive" \) -prune -o \
        -type f \
        ! -name '*.log' \
        ! -name '.DS_Store' \
        ! -name '*.tmp' \
        ! -path './bones/manifest.txt' \
        -print | sed 's|^./||' | sort
    )
  } > "$OUT"
  log "INFO" "File system catalog written to $OUT"
}

# ---
# collapse: Collapse rotkeeper-*.md books into a single YAML with bodies.
# Inputs: none; reads BOOK_REPORT_DIR
# Outputs: Writes collapsed-content.yaml
# ---
collapse() {
  mkdir -p "$BOOK_REPORT_DIR"
  local OUTPUT="$BOOK_REPORT_DIR/collapsed-content.yaml"
  validate_boundary "$OUTPUT"
  log "INFO" "Collapsing reports into YAML..."
  echo "" > "$OUTPUT"
  for file in "$BOOK_REPORT_DIR"/rotkeeper-*.md; do
    [[ -f "$file" ]] || continue
    local filename title subtitle
    filename=$(basename "$file")
    title=$(rk_frontmatter_field "title" "$file")
    subtitle=$(rk_frontmatter_field "subtitle" "$file")
    [[ -z "$title" ]] && title=$(basename "$file" .md)
    {
      echo "- filename: $filename"
      echo "  title: $title"
      echo "  subtitle: $subtitle"
      echo "  body: |"
      rk_strip_frontmatter "$file" | awk '{ print "    " $0 }'  # indent body for YAML block literal
    } >> "$OUTPUT"
  done
  log "INFO" "Wrote $OUTPUT"
}

# ---
# runmode: Enforce size guard and dispatch MODE to the matching binder.
# Inputs: none; reads MODE, FORCE_BIND, DOCS_DIR, CONTENT_DIR
# Outputs: Writes selected book(s); exits 1 if >5MB without --force-bind
# ---
runmode() {
  local total_size
  # Estimate total bind size deterministically: find all 3 source extensions across docs+content, dedupe, NUL->wc
  total_size=$( { find "$DOCS_DIR" "$CONTENT_DIR" -type f \( -name "*.md" -o -name "*.textile" -o -name "*.cook" \) 2>/dev/null || true; } | sort -u | tr "\n" "\0" | xargs -0 wc -c 2>/dev/null | awk 'END{print $1}' )
  [[ -z "$total_size" ]] && total_size=0
  if [[ "$total_size" -gt 5242880 ]]; then
    if [[ "$FORCE_BIND" != "true" ]]; then
      log "ERROR" "Resulting binder will be massive (>5MB). Aborting. Append --force-bind to proceed."
      exit 1
    else
      log "WARN" "Resulting binder will be massive (>5MB). Proceeding because --force-bind is set."
    fi
  fi
  case "$MODE" in
    scriptbookfull) runscriptbookfull ;;
    docbook)        rundocbook ;;
    docbookclean)   rundocbookclean ;;
    configbook)     runconfigbook ;;
    fsbook)         runfsbook ;;
    contentbook)    runcontentbook ;;
    contentmeta)    runcontentmeta ;;
    collapse)       collapse ;;
    all)
      if [[ "$DRY_RUN" == true ]]; then
        log "DRY-RUN" "Would generate all binders inside $BOOK_REPORT_DIR safely."
      else
        runscriptbookfull
        rundocbook
        rundocbookclean
        runconfigbook
        runcontentbook
        runcontentmeta
        runfsbook
        collapse
      fi
      ;;
    *)
      log "WARN" "No mode selected — defaulting to --all"
      MODE=all
      runmode
      ;;
  esac
}

# ---
# main: Bootstrap binder, parse flags, and run selected mode.
# Inputs: $@ (CLI args)
# Outputs: Generates book artifacts; exits on error
# ---
main() {
  export BOOK_SUFFIX=$(printf "%04x%04x" "$RANDOM" "$RANDOM")
  require_bins bash
  log "INFO" "Running rc-book.sh safely bounded."
  mkdir -p "$BOOK_REPORT_DIR"
  parseflags "$@"
  runmode
}

main "$@"
