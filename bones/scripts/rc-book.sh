#!/usr/bin/env bash
# ============================================================
#  ██████╗  ██████╗  ██████╗ ██╗  ██╗
#  ██╔══██╗██╔═══██╗██╔═══██╗██║ ██╔╝
#  ██████╔╝██║   ██║██║   ██║█████╔╝
#  ██╔══██╗██║   ██║██║   ██║██╔═██╗
#  ██████╔╝╚██████╔╝╚██████╔╝██║  ██╗
#  ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-book.sh
#  Purpose : Bind documentation reports — scriptbook, docbook, configbook, contentbook
#  Version : 0.3.1.4
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
VERSION="${ROTKEEPER_VERSION:-0.3.1.4}"

rk_init_script "rc-book" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR REPORT_DIR BOOK_REPORT_DIR

set -euo pipefail
IFS=$'\n\t'


require_gawk_version

MODE=""
# shellcheck disable=SC2034
CONFIG=""
STRIPMODE=false

showhelp() {
  cat <<EOF
rc-book.sh — Documentation binder ritual
v0.3.1.4

Usage: rc-book.sh [mode] [options]

Modes:
  --scriptbook-full   Bind all rc-*.sh scripts into rotkeeper-scriptbook-full.md
  --docbook           Bind docs into rotkeeper-docbook.md
  --docbook-clean     Bind docs, frontmatter stripped
  --configbook        Bind config/templates into rotkeeper-configbook.md
  --fsbook            Bind project file system catalog into rotkeeper-files.md
  --contentbook       Bind all home/content markdown into rotkeeper-contentbook.md
  --contentmeta       Extract frontmatter YAML into rotkeeper-contentmeta.yaml
  --collapse          Collapse all rotkeeper-*.md into collapsed-content.yaml
  --all               Run all documentation and book bindings exhaustive

Options:
  --config FILE       Optional config file
  --dry-run           Show what would be done without making changes
  --strip-frontmatter Strip frontmatter from output where applicable
  --verbose           Enable verbose logging
  --help              Show this helpful void
EOF
}

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
      --verbose)           shift ;;
      --help|-h)           showhelp; exit 0 ;;
      *) echo "Unknown option: $1"; showhelp; exit 1 ;;
    esac
  done
}

# ---
# runscriptbookfull: Gathers all rc-*.sh spells into a single, massive markdown tome.
# Paths are made relative to the root, and code is fenced in bash blocks.
# ---
runscriptbookfull() {
  mkdir -p "$BOOK_REPORT_DIR"
  local OUT="$BOOK_REPORT_DIR/rotkeeper-scriptbook-full.md"
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "Would generate full scriptbook at $OUT"
    { find "$ROOT_DIR/bones/scripts" -maxdepth 1 -type f -name "rc-*.sh"; find "$ROOT_DIR" -maxdepth 1 -type f -name "rotkeeper.sh"; } | sort | while read -r script; do
      echo "  - ${script#"$ROOT_DIR"/}"
    done
    return 0
  fi
  {
    echo "---"
    echo "title: Rotkeeper Scriptbook Full"
    echo "subtitle: All rc-*.sh rituals with relative paths and fences"
    echo "generated: $(date +%Y-%m-%d)"
    echo "---"
    echo ""
  } > "$OUT"
  { find "$ROOT_DIR/bones/scripts" -maxdepth 1 -type f -name "rc-*.sh"; find "$ROOT_DIR" -maxdepth 1 -type f -name "rotkeeper.sh"; } | sort | while read -r script; do
    rel="${script#"$ROOT_DIR"/}"
    {
      echo "<!-- START $rel -->"
      echo ""
      echo '```bash'
      cat "$script"
      echo '```'
      echo "<!-- END $rel -->"
      echo ""
    } >> "$OUT"
  done
  log "INFO" "Full Scriptbook written to $OUT"
}

# ---
# rundocbook: Binds the markdown docs from home/content/docs into one continuous scroll.
# The awk spell preserves frontmatter while appending content.
# ---
rundocbook() {
  mkdir -p "$BOOK_REPORT_DIR"
  local OUT="$BOOK_REPORT_DIR/rotkeeper-docbook.md"
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "Would generate docbook at $OUT"
    return 0
  fi
  {
    echo "---"
    echo "title: Rotkeeper Docbook"
    echo "subtitle: All markdown documentation in home/content/docs with path markers"
    echo "---"
    echo ""
  } > "$OUT"
  mapfile -t docfiles < <(find "$DOCS_DIR" -name "*.md" -type f | sort)
  for file in "${docfiles[@]}"; do
    rel="${file#"$ROOT_DIR"/}"
    {
      echo "<!-- START $rel -->"
      echo ""
      awk -v dostrip="$STRIPMODE" '
        BEGIN { inyaml=0 }
        /^---$/ { inyaml++; if (dostrip=="true") next; print; next }
        inyaml==1 { if (dostrip=="true") next; print; next }
        { print }
      ' "$file"
      echo "<!-- END $rel -->"
      echo ""
    } >> "$OUT"
  done
  log "INFO" "Docbook written to $OUT"
}

# ---
# rundocbookclean: A purified binding of the docbook.
# The awk logic strips the YAML frontmatter, leaving only the mortal text.
# ---
rundocbookclean() {
  mkdir -p "$BOOK_REPORT_DIR"
  local OUT="$BOOK_REPORT_DIR/rotkeeper-docbook-clean.md"
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
  find "$DOCS_DIR" -name "*.md" -type f | sort | while read -r file; do
    local TITLE
    TITLE=$(awk 'BEGIN{found=0} /^---$/{found++; next} found==1 && /^title:/{print substr($0, index($0,$2)); exit}' "$file" | head -n1 | sed 's/^ //;s/ $//')
    [[ -z "$TITLE" ]] && TITLE=$(basename "$file" .md)
    {
      echo "$TITLE"
      echo ""
      awk 'BEGIN{inyaml=0} /^---$/{inyaml++; next} inyaml>=2{print}' "$file"
      echo ""
    } >> "$OUT"
  done
  log "INFO" "Cleaned Docbook written to $OUT"
}

runconfigbook() {
  mkdir -p "$BOOK_REPORT_DIR"
  local OUT="$BOOK_REPORT_DIR/rotkeeper-configbook.md"
  {
    echo "---"
    echo "title: Rotkeeper Configbook"
    echo "subtitle: YAML configuration and templates used by rotkeeper"
    echo "---"
    echo ""
  } > "$OUT"
  find "$ROOT_DIR/bones/config" "$ROOT_DIR/bones/templates" -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.tpl" -o -name "*.html" \) | sort | while read -r file; do
    rel="${file#"$ROOT_DIR"/}"
    {
      echo "<!-- START $rel -->"
      echo ""
      cat "$file"
      echo "<!-- END $rel -->"
      echo ""
    } >> "$OUT"
  done
  log "INFO" "Configbook written to $OUT"
}

runcontentbook() {
  mkdir -p "$BOOK_REPORT_DIR"
  local OUT="$BOOK_REPORT_DIR/rotkeeper-contentbook.md"
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "Would generate full contentbook at $OUT"
    return 0
  fi
  {
    echo "---"
    echo "title: Rotkeeper Contentbook"
    echo "subtitle: All markdown in home/content with path markers"
    echo "---"
    echo ""
  } > "$OUT"
  mapfile -t contentfiles < <(find "$CONTENT_DIR" -name "*.md" -type f | sort)
  for file in "${contentfiles[@]}"; do
    rel="${file#"$ROOT_DIR"/}"
    {
      echo "<!-- START $rel -->"
      echo ""
      awk -v dostrip="$STRIPMODE" '
        BEGIN { inyaml=0; linenumber=0 }
        { linenumber++ }
        linenumber==1 && /^---$/ { inyaml=1; if (dostrip=="true") next; print; next }
        inyaml==1 && /^---$/ { inyaml=2; if (dostrip=="true") next; print; next }
        inyaml==1 { if (dostrip=="true") next; print; next }
        { print }
      ' "$file"
      echo "<!-- END $rel -->"
      echo ""
    } >> "$OUT"
  done
  log "INFO" "Contentbook written to $OUT"
}

# ---
# runcontentmeta: Extracts the soul (YAML frontmatter) from every tomb in the content dir.
# Writes it into a consolidated YAML index for agents to devour.
# ---
runcontentmeta() {
  mkdir -p "$BOOK_REPORT_DIR"
  local OUT="$BOOK_REPORT_DIR/rotkeeper-contentmeta.yaml"
  log "INFO" "Extracting frontmatter YAML from content files..."
  echo "" > "$OUT"
  find "$CONTENT_DIR" -name "*.md" -type f | sort | while read -r file; do
    rel="${file#"$ROOT_DIR"/}"
    awk -v path="$rel" '
      BEGIN { inyaml=0 }
      /^---$/ { inyaml++; if (inyaml==1) { print "- path: " path }; next }
      inyaml==1 { print "  " $0; next }
      inyaml>=2 { exit }
    ' "$file" >> "$OUT"
    echo "" >> "$OUT"
  done
  log "INFO" "Content metadata written to $OUT"
}


# ---
# runfsbook: Generates a complete catalog of every file in the project.
# Writes it into a markdown list for RAG exports and agents.
# ---
runfsbook() {
  mkdir -p "$BOOK_REPORT_DIR"
  local OUT="$BOOK_REPORT_DIR/rotkeeper-files.md"
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
    # Find all files, remove leading ./, sort them
    cd "$ROOT_DIR" && find . -type f | sed 's|^./||' | sort | while read -r f; do
      echo "- $f"
    done
  } > "$OUT"
  log "INFO" "File system catalog written to $OUT"
}

collapse() {

  mkdir -p "$BOOK_REPORT_DIR"
  local OUTPUT="$BOOK_REPORT_DIR/collapsed-content.yaml"
  log "INFO" "Collapsing reports into YAML..."
  echo "" > "$OUTPUT"
  for file in "$BOOK_REPORT_DIR"/rotkeeper-*.md; do
    [[ -f "$file" ]] || continue
    local filename title subtitle
    filename=$(basename "$file")
    title=$(awk 'BEGIN{found=0} /^---$/{found++; next} found==1 && /^title:/{print substr($0, index($0,$2)); exit}' "$file" | head -n1 | sed 's/^ //;s/ $//')
    subtitle=$(awk 'BEGIN{found=0} /^---$/{found++; next} found==1 && /^subtitle:/{print substr($0, index($0,$2)); exit}' "$file" | head -n1 | sed 's/^ //;s/ $//')
    [[ -z "$title" ]] && title=$(basename "$file" .md)
    {
      echo "- filename: $filename"
      echo "  title: $title"
      echo "  subtitle: $subtitle"
      echo "  body: |"
      awk 'BEGIN{skip=1} /^---$/{if(skip){skip=0;next};nextfile} !skip{print "    " $0}' "$file"
    } >> "$OUTPUT"
  done
  echo "" >> "$OUTPUT"
  log "INFO" "Wrote $OUTPUT"
}

runmode() {
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
        log "DRY-RUN" "Would generate scriptbook at $BOOK_REPORT_DIR/rotkeeper-scriptbook-full.md"
        log "DRY-RUN" "Would generate docbook at $BOOK_REPORT_DIR/rotkeeper-docbook.md"
        log "DRY-RUN" "Would generate cleaned docbook at $BOOK_REPORT_DIR/rotkeeper-docbook-clean.md"
        log "DRY-RUN" "Would generate configbook at $BOOK_REPORT_DIR/rotkeeper-configbook.md"
        log "DRY-RUN" "Would generate contentbook at $BOOK_REPORT_DIR/rotkeeper-contentbook.md"
        log "DRY-RUN" "Would generate contentmeta at $BOOK_REPORT_DIR/rotkeeper-contentmeta.yaml"
        log "DRY-RUN" "Would generate file system catalog at $BOOK_REPORT_DIR/rotkeeper-files.md"
        log "DRY-RUN" "Would run collapse to generate $BOOK_REPORT_DIR/collapsed-content.yaml"
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

main() {
  check_dependencies
  log "INFO" "Running rc-book.sh."
  mkdir -p "$BOOK_REPORT_DIR"
  parseflags "$@"
  runmode
}

main "$@"
