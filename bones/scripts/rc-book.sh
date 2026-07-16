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
#  Version : 0.4.0.4
# ============================================================

VERSION="${ROTKEEPER_VERSION:-0.4.0.4}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
rk_init_script "rc-book" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR TEMPLATE_DIR LOG_DIR TMP_DIR REPORT_DIR BOOK_REPORT_DIR DOCS_DIR CONTENT_DIR

set -euo pipefail
IFS=$'\n\t'

require_gawk_version

MODE=""
CONFIG=""
STRIPMODE=false
FORCE_BIND=false

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
    echo "subtitle: All markdown documentation with path markers"
    echo "---"
    echo ""
  } > "$OUT"
  mapfile -t docfiles < <(find "$DOCS_DIR" -name "*.md" -type f | sort)
  for file in ${docfiles[@]+"${docfiles[@]}"}; do
    if [[ -f "$file" ]]; then
      rel="${file#"$ROOT_DIR"/}"
      {
        echo "<!-- START $rel::$BOOK_SUFFIX -->"
        echo ""
        awk -v dostrip="$STRIPMODE" '
          BEGIN { inyaml=0 }
          /^---$/ { inyaml++; if (dostrip=="true") next; print; next }
          inyaml==1 { if (dostrip=="true") next; print; next }
          { print }
        ' "$file"
        echo "<!-- END $rel::$BOOK_SUFFIX -->"
        echo ""
      } >> "$OUT"
    fi
  done
  log "INFO" "Docbook written to $OUT"
}

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
  while read -r file; do
    if [[ -f "$file" ]]; then
      local TITLE
      TITLE=$(awk 'BEGIN{found=0} /^---$/{found++; next} found==1 && /^title:/{print substr($0, index($0,$2)); exit}' "$file" | head -n1 | sed 's/^ //;s/ $//')
      [[ -z "$TITLE" ]] && TITLE=$(basename "$file" .md)
      {
        echo "$TITLE"
        echo ""
        awk 'BEGIN{inyaml=0} /^---$/{inyaml++; next} inyaml>=2{print}' "$file"
        echo ""
      } >> "$OUT"
    fi
  done < <(find "$DOCS_DIR" -name "*.md" -type f | sort)
  log "INFO" "Cleaned Docbook written to $OUT"
}

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
    echo "subtitle: All markdown in home/content with path markers"
    echo "---"
    echo ""
  } > "$OUT"
  mapfile -t contentfiles < <(find "$CONTENT_DIR" -name "*.md" -type f | sort)
  for file in ${contentfiles[@]+"${contentfiles[@]}"}; do
    if [[ -f "$file" ]]; then
      rel="${file#"$ROOT_DIR"/}"
      {
        echo "<!-- START $rel::$BOOK_SUFFIX -->"
        echo ""
        awk -v dostrip="$STRIPMODE" '
          BEGIN { inyaml=0; linenumber=0 }
          { linenumber++ }
          linenumber==1 && /^---$/ { inyaml=1; if (dostrip=="true") next; print; next }
          inyaml==1 && /^---$/ { inyaml=2; if (dostrip=="true") next; print; next }
          inyaml==1 { if (dostrip=="true") next; print; next }
          { print }
        ' "$file"
        echo "<!-- END $rel::$BOOK_SUFFIX -->"
        echo ""
      } >> "$OUT"
    fi
  done
  log "INFO" "Contentbook written to $OUT"
}

runcontentmeta() {
  mkdir -p "$BOOK_REPORT_DIR"
  local OUT="$BOOK_REPORT_DIR/rotkeeper-contentmeta.yaml"
  validate_boundary "$OUT"
  log "INFO" "Extracting frontmatter YAML from content files..."
  echo "" > "$OUT"
  while read -r file; do
    if [[ -f "$file" ]]; then
      rel="${file#"$ROOT_DIR"/}"
      awk -v path="$rel" '
        BEGIN { inyaml=0 }
        /^---$/ { inyaml++; if (inyaml==1) { print "- path: " path }; next }
        inyaml==1 { print "  " $0; next }
        inyaml>=2 { exit }
      ' "$file" >> "$OUT"
      echo "" >> "$OUT"
    fi
  done < <(find "$CONTENT_DIR" -name "*.md" -type f | sort)
  log "INFO" "Content metadata written to $OUT"
}

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
    done < <(cd "$ROOT_DIR" && find . -type f | sed 's|^./||' | sort)
  } > "$OUT"
  log "INFO" "File system catalog written to $OUT"
}

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
    title=$(awk 'BEGIN{found=0} /^---$/{found++; next} found==1 && /^title:/{print substr($0, index($0,$2)); exit}' "$file" | head -n1 | sed 's/^ //;s/ $//')
    subtitle=$(awk 'BEGIN{found=0} /^---$/{found++; next} found==1 && /^subtitle:/{print substr($0, index($0,$2)); exit}' "$file" | head -n1 | sed 's/^ //;s/ $//')
    [[ -z "$title" ]] && title=$(basename "$file" .md)
    {
      echo "- filename: $filename"
      echo "  title: $title"
      echo "  subtitle: $subtitle"
      echo "  body: |"
      # Strip YAML frontmatter (opening --- ... closing ---), keep the body.
      awk '
        BEGIN { in_fm=0; past_fm=0 }
        NR==1 && /^---[[:space:]]*$/ { in_fm=1; next }
        in_fm && /^---[[:space:]]*$/ { in_fm=0; past_fm=1; next }
        in_fm { next }
        { print "    " $0 }
      ' "$file"
    } >> "$OUTPUT"
  done
  log "INFO" "Wrote $OUTPUT"
}

runmode() {
  local total_size
  total_size=$( { find "$DOCS_DIR" "$CONTENT_DIR" -type f -name "*.md" 2>/dev/null || true; } | sort -u | tr "\n" "\0" | xargs -0 wc -c 2>/dev/null | awk 'END{print $1}' )
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

main() {
  export BOOK_SUFFIX=$(printf "%04x%04x" $RANDOM $RANDOM)
  check_dependencies
  log "INFO" "Running rc-book.sh safely bounded."
  mkdir -p "$BOOK_REPORT_DIR"
  parseflags "$@"
  runmode
}

main "$@"
