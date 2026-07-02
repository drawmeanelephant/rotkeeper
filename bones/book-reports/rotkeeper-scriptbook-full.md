---
title: Rotkeeper Scriptbook Full
subtitle: All rc-*.sh rituals with relative paths and fences
generated: 2026-07-02
---

<!-- START bones/scripts/rc-assets.sh::4ad3790b -->

```bash
#!/usr/bin/env bash
# ============================================================
#   █████╗ ███████╗███████╗███████╗████████╗███████╗
#  ██╔══██╗██╔════╝██╔════╝██╔════╝╚══██╔══╝██╔════╝
#  ███████║███████╗███████╗█████╗     ██║   ███████╗
#  ██╔══██║╚════██║╚════██║██╔══╝     ██║   ╚════██║
#  ██║  ██║███████║███████║███████╗   ██║   ███████║
#  ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝   ╚═╝   ╚══════╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-assets.sh
#  Purpose : Generate a selective YAML manifest of referenced assets
#  Version : 0.4.0.3
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================
show_help() {
  cat << EOF
rc-assets.sh — Generate a selective YAML manifest of referenced assets

Usage: rc-assets.sh [options]

Options:
  --version, -v    Show script version and quit
  --help, -h       Show this help message and exit
  --dry-run        Preview actions without writing files
  --verbose        Show detailed logs
  --sitemap        Generate sitemap.yaml manifest (opt-in)
EOF
  exit 0
}

source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
VERSION="${ROTKEEPER_VERSION:-0.4.0.3}"

rk_init_script "rc-assets" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR ASSETS_DIR
set -euo pipefail
IFS=$'\n\t'


# --- Helpers & Flag Parsing ---
GENERATE_SITEMAP=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version|-v) echo "$(basename "$0") v${VERSION:-unknown}"; exit 0 ;;
    --dry-run)   DRY_RUN=true; shift ;;
    --verbose)   VERBOSE=true; shift ;;
    --help|-h)   show_help ;;
    --sitemap)   GENERATE_SITEMAP=true; shift ;;
    *) break ;;
  esac
done






cleanup() {
    log "INFO" "Cleaning up after rc-assets.sh."
}


main() {
    TIMESTAMP=$(date +%Y-%m-%d_%H%M)
    check_dependencies
    $VERBOSE && log "INFO" "Dependencies verified."

    MANIFEST="$BONES_DIR/asset-manifest.yaml"
    REPORT="$REPORT_DIR/asset-report-$TIMESTAMP.yaml"
    OUTPUT_ASSET_DIR="$OUTPUT_DIR/assets"

    run mkdir -p "$OUTPUT_ASSET_DIR" "$ARCHIVE_DIR" "$REPORT_DIR"

    if [[ -f "$MANIFEST" ]]; then
        run mv "$MANIFEST" "$ARCHIVE_DIR/asset-manifest-$TIMESTAMP.yaml"
        log "INFO" "Archived old manifest"
    fi

    ASSET_PATHS=$(find "$ASSETS_DIR" -type f | sed "s|^$ASSETS_DIR/||" | sort)

    asset_count=$(echo "$ASSET_PATHS" | grep -c . || true)
    log "INFO" "Found $asset_count assets in $ASSETS_DIR"

    [[ "$DRY_RUN" == false ]] && : > "$REPORT"

    if [[ "$asset_count" -eq 0 ]]; then
        log "WARN" "No assets found under $ASSETS_DIR"
        echo "# assets: []" > "$REPORT"
        run cp "$REPORT" "$MANIFEST"
        log "INFO" "Empty manifest generated at: $MANIFEST"
    else
        echo "$ASSET_PATHS" | while read -r relpath; do
            src="$ASSETS_DIR/$relpath"
            dest="$OUTPUT_ASSET_DIR/$relpath"
            if [[ -f "$src" ]]; then
                if [[ "$relpath" == *"../"* ]] || [[ ! "$relpath" =~ ^[a-zA-Z0-9/._-]+$ ]]; then
                    log "ERROR" "Illegal characters in asset path"
                    continue
                fi
                run mkdir -p "$(dirname "$dest")"
                run rsync -a "$src" "$dest"
                checksum=$(sha256sum "$src" | awk '{print $1}')
                log "INFO" "Copied asset: $relpath"
                {
                    echo "- path: \"$relpath\""
                    echo "  sha256: \"$checksum\""
                } >> "$REPORT"
            else
                log "WARN" "Missing asset file unexpectedly: $relpath"
            fi
        done
        run cp "$REPORT" "$MANIFEST"
        log "INFO" "Full asset manifest generated at: $MANIFEST"
    fi

    # SITEMAP PURGED ENTIRELY FROM CORE PIPELINE.
}

# --- Entry Point ---
main "$@"
```
<!-- END bones/scripts/rc-assets.sh::4ad3790b -->

<!-- START bones/scripts/rc-autopsy.sh::4ad3790b -->

```bash
#!/usr/bin/env bash
# shellcheck disable=SC2129
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
#  Script  : rc-autopsy.sh
#  Purpose : Script dissection and output cataloging
#  Version : 0.4.0.3
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; return 1; }
source "$SCRIPT_DIR/rc-env.sh"   || { echo "FATAL: cannot source rc-env.sh" >&2; return 1; }


show_help() { cat <<HELP_EOF
rc-autopsy.sh — Script dissection ritual v$VERSION
Usage: rc-autopsy.sh [mode] [options]

Modes:
  --help-report    Extract --help output from all rc-*.sh into a reference report
  --output-report  Scan scripts for file-write operations and catalog outputs
  --all            Run both reports (default)

Options:
  --dry-run        Preview without writing
  --verbose        Detailed logging
  --help, -h       Show this message
  --version, -v    Show version
HELP_EOF
}

VERSION="${ROTKEEPER_VERSION:-0.4.0.3}"

rk_init_script rc-autopsy "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR REPORT_DIR

set -euo pipefail
IFS=$'\n\t'

HELP_REPORT=false
OUTPUT_REPORT=false

parse_args() {
  local has_mode=false
  for arg in "$@"; do
    case "$arg" in
      --help-report) HELP_REPORT=true; has_mode=true ;;
      --output-report) OUTPUT_REPORT=true; has_mode=true ;;
      --all) HELP_REPORT=true; OUTPUT_REPORT=true; has_mode=true ;;
      --help|-h) show_help; return 1 ;;
      --version|-v) echo "rc-autopsy.sh v$VERSION"; return 1 ;;
      --dry-run|--verbose) ;; # Handled by rc-utils.sh
      -*) ;; # Ignore other flags
      *) ;;
    esac
  done

  if [[ "$has_mode" == false ]]; then
    HELP_REPORT=true
    OUTPUT_REPORT=true
  fi
  return 0
}

run_help_report() {
  local OUT="$REPORT_DIR/autopsy-help.md"
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "Would generate help report at $OUT"
    return 0
  fi

  mkdir -p "$REPORT_DIR"
  {
    echo "---"
    echo "title: \"Rotkeeper Script Help Reference\""
    echo "generated: \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
    echo "template: \"rotkeeper-doc.html\""
    echo "---"
    echo
    echo "# Script Help Reference"
    echo
  } > "$OUT"

  mapfile -t scripts < <({ find "$SCRIPT_DIR" -maxdepth 1 -type f -name "rc-*.sh"; find "$ROOT_DIR" -maxdepth 1 -type f -name "rotkeeper.sh"; } | sort | uniq)

  for script in "${scripts[@]}"; do
    name="$(basename "$script")"
    echo "## $name" >> "$OUT"
    echo >> "$OUT"
    echo '```text' >> "$OUT"

    local help_output
    if ! help_output=$(bash "$script" --help 2>&1) || echo "$help_output" | grep -qi 'No help available' || [[ -z "$help_output" ]]; then
      help_output=$(grep -oE '\-\-[a-z][a-z-]+' "$script" | sort -u || echo "(No help available and no flags found)")
      log "WARN" "Script $name did not respond well to --help. Used fallback."
    fi
    echo "$help_output" >> "$OUT"

    echo '```' >> "$OUT"
    echo >> "$OUT"
    log "INFO" "Extracted help: $name"
  done

  log "INFO" "Help report written to $OUT"
}

render_output_report_md() {
  local OUT="$REPORT_DIR/autopsy-outputs.md"
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "Would generate output report at $OUT"
    return 0
  fi

  mkdir -p "$REPORT_DIR"
  {
    echo "---"
    echo "title: \"Rotkeeper Outputs Reference\""
    echo "generated: \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
    echo "template: \"rotkeeper-doc.html\""
    echo "---"
    echo
    echo "# Script Outputs Reference"
    echo
  } > "$OUT"

  declare -A ENV_VARS
  while IFS='=' read -r key val; do
    if [[ "$key" == *"_DIR" ]]; then
      ENV_VARS["$key"]="$val"
    fi
  done < <(env)

  mapfile -t scripts < <({ find "$SCRIPT_DIR" -maxdepth 1 -type f -name "rc-*.sh"; find "$ROOT_DIR" -maxdepth 1 -type f -name "rotkeeper.sh"; } | sort | uniq)

  for script in "${scripts[@]}"; do
    name="$(basename "$script")"

    local matches
    matches=$(grep -nE '(>\s*\$[A-Z_]+|>>\s*\$[A-Z_]+|tee\s+\$[A-Z_]+|mv\s+.*\$[A-Z_]+|cp\s+.*\$[A-Z_]+|tar\s+.*-[cf]f?\s)' "$script" || true)

    if [[ -n "$matches" ]]; then
      echo "## $name" >> "$OUT"
      echo "" >> "$OUT"
      echo "| Line | Operation | Resolved Path |" >> "$OUT"
      echo "|------|-----------|---------------|" >> "$OUT"

      while IFS= read -r line_match; do
        local line_num="${line_match%%:*}"
        local op_content="${line_match#*:}"

        op_content=$(echo "$op_content" | sed -E 's/^[[:space:]]+//')
        local original_op="$op_content"

        local resolved_path="$op_content"
        for var_name in "${!ENV_VARS[@]}"; do
          local val="${ENV_VARS[$var_name]}"
          local rel_val="${val#"$ROOT_DIR"/}"
          resolved_path=$(echo "$resolved_path" | sed -E "s|\\\$${var_name}|${rel_val}|g; s|\\\$\\{${var_name}\\}|${rel_val}|g")
        done

        resolved_path=$(echo "$resolved_path" | sed -E 's/(\$[A-Za-z_]+|\$\{[A-Za-z_]+\})/(unresolved: \1)/g')

        local simple_op=""
        if [[ "$original_op" =~ (>\s*\$[A-Z_]+) ]]; then simple_op="${BASH_REMATCH[1]}"; fi
        if [[ -z "$simple_op" ]] && [[ "$original_op" =~ (>>\s*\$[A-Z_]+) ]]; then simple_op="${BASH_REMATCH[1]}"; fi
        if [[ -z "$simple_op" ]] && [[ "$original_op" =~ (tee\s+\$[A-Z_]+) ]]; then simple_op="${BASH_REMATCH[1]}"; fi
        if [[ -z "$simple_op" ]] && [[ "$original_op" =~ (mv\s+[^\s]+\s+\$[A-Z_]+) ]]; then simple_op="${BASH_REMATCH[1]}"; fi
        if [[ -z "$simple_op" ]] && [[ "$original_op" =~ (cp\s+[^\s]+\s+\$[A-Z_]+) ]]; then simple_op="${BASH_REMATCH[1]}"; fi
        if [[ -z "$simple_op" ]] && [[ "$original_op" =~ (tar\s+[^\s]+\s+-[cf]f?\s) ]]; then simple_op="${BASH_REMATCH[1]}"; fi

        if [[ -z "$simple_op" ]]; then
           simple_op="$(echo "$original_op" | grep -oE '(>|>>|tee|mv|cp|tar)\s+\S+' | head -n1 || echo "$original_op")"
        fi

        local final_path="$resolved_path"
        final_path=$(echo "$final_path" | sed -E 's/.*(>|>>|tee|mv|cp|tar[ a-zA-Z-]*)[[:space:]]+//' | sed 's/"//g')

        echo "| $line_num | \`${simple_op}\` | \`${final_path}\` |" >> "$OUT"

      done <<< "$matches"
      echo "" >> "$OUT"
    fi
  done

  log "INFO" "Output report written to $OUT"
}

run_output_report() {
  render_output_report_md
}

main() {
  if ! parse_args "$@"; then
    return 0
  fi

  if [[ "$HELP_REPORT" == true ]]; then
    run_help_report
  fi

  if [[ "$OUTPUT_REPORT" == true ]]; then
    run_output_report
  fi
}

main "$@"
```
<!-- END bones/scripts/rc-autopsy.sh::4ad3790b -->

<!-- START bones/scripts/rc-book.sh::4ad3790b -->

```bash
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
#  Version : 0.4.0.3
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
VERSION="${ROTKEEPER_VERSION:-0.4.0.3}"

rk_init_script "rc-book" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR REPORT_DIR BOOK_REPORT_DIR

set -euo pipefail
IFS=$'\n\t'


require_gawk_version

MODE=""
# shellcheck disable=SC2034
CONFIG=""
STRIPMODE=false
FORCE_BIND=false

showhelp() {
  cat <<EOF
rc-book.sh — Documentation binder ritual
v0.4.0.3

Usage: rc-book.sh [mode] [options]

Modes:
  --scriptbook-full   Bind all rc-*.sh scripts into rotkeeper-scriptbook-full.md
  --docbook           Bind docs into rotkeeper-docbook.md
  --docbook-clean     Bind docs, frontmatter stripped
  --configbook        Bind config/templates into rotkeeper-configbook.md
  --fsbook            Bind project file system catalog into rotkeeper-files.md
  --force-bind        Bypass memory budget safeguards when generating massive books
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
      --force-bind)        FORCE_BIND=true; shift ;;
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
      echo "<!-- START $rel::$BOOK_SUFFIX -->"
      echo ""
      echo '```bash'
      cat "$script"
      echo '```'
      echo "<!-- END $rel::$BOOK_SUFFIX -->"
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
      echo "<!-- START $rel::$BOOK_SUFFIX -->"
      echo ""
      cat "$file"
      echo "<!-- END $rel::$BOOK_SUFFIX -->"
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
        log "DRY-RUN" "Would generate scriptbook at $BOOK_REPORT_DIR/rotkeeper-scriptbook-full.md"
        log "DRY-RUN" "Would generate docbook at $BOOK_REPORT_DIR/rotkeeper-docbook.md"
        log "DRY-RUN" "Would generate configbook at $BOOK_REPORT_DIR/rotkeeper-configbook.md"
        log "DRY-RUN" "Would generate contentbook at $BOOK_REPORT_DIR/rotkeeper-contentbook.md"
        log "DRY-RUN" "Would generate contentmeta at $BOOK_REPORT_DIR/rotkeeper-contentmeta.yaml"
        log "DRY-RUN" "Would generate file system catalog at $BOOK_REPORT_DIR/rotkeeper-files.md"
        log "DRY-RUN" "Would run collapse to generate $BOOK_REPORT_DIR/collapsed-content.yaml"
      else
        runscriptbookfull
        rundocbook
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
  log "INFO" "Running rc-book.sh."
  mkdir -p "$BOOK_REPORT_DIR"
  parseflags "$@"
  runmode
}

main "$@"
```
<!-- END bones/scripts/rc-book.sh::4ad3790b -->

<!-- START bones/scripts/rc-bump.sh::4ad3790b -->

```bash
#!/usr/bin/env bash
# ============================================================
#  ██████╗ ██╗   ██╗███╗   ███╗██████╗
#  ██╔══██╗██║   ██║████╗ ████║██╔══██╗
#  ██████╔╝██║   ██║██╔████╔██║██████╔╝
#  ██╔══██╗██║   ██║██║╚██╔╝██║██╔═══╝
#  ██████╔╝╚██████╔╝██║ ╚═╝ ██║██║
#  ╚═════╝  ╚═════╝ ╚═╝     ╚═╝╚═╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-bump.sh
#  Purpose : Automated microbump logging and version bumping workflow
#  Version : 0.4.0.3
# ------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'


export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/rc-utils.sh"
VERSION="${ROTKEEPER_VERSION:-0.4.0.3}"

rk_init_script "rc-bump" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR

MESSAGE=""
COMMIT=false

show_help() {
  cat <<EOF
rc-bump.sh — Microbump Version Logging

Usage:
  rc-bump.sh [message] [options]

Options:
  --version, -v    Show script version and quit
  --message, -m MSG  The update message to log
  --dry-run          Preview changes without saving or committing
  --commit           Stage changes and commit them to git
  --verbose          Detailed output
  --help, -h         Show help
EOF
}

# Parse flags manually
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version|-v) echo "$(basename "$0") v${VERSION:-unknown}"; exit 0 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --commit) COMMIT=true; shift ;;
    --verbose) # shellcheck disable=SC2034
               VERBOSE=true; shift ;;
    --help|-h) show_help ;;
    --to) NEW_VERSION_OVERRIDE="$2"; shift 2 ;;
    --message|-m) MESSAGE="${2:-}"; shift 2 ;;
    -*) log "ERROR" "Unknown flag: $1"; show_help; exit 1 ;;
    *)
      if [[ -z "$MESSAGE" ]]; then
        MESSAGE="$1"
      else
        MESSAGE="$MESSAGE $1"
      fi

if [[ -n "$(git -C "$ROOT_DIR" status --porcelain 2>/dev/null)" ]]; then
  log "WARN" "Working tree is dirty. Proceeding with version bump, but be aware uncommitted changes exist."
fi
      shift
      ;;
  esac
done

if [[ -z "$MESSAGE" ]]; then
  log "ERROR" "No update message provided."
  show_help
  exit 1
fi

if [[ -n "$(git -C "$ROOT_DIR" status --porcelain 2>/dev/null)" ]]; then
  log "WARN" "Working tree is dirty. Proceeding with version bump, but be aware uncommitted changes exist."
fi

# Step 1: Read current version from rotkeeper.sh
CURRENT_VERSION=$(grep -E '^VERSION=' "$ROOT_DIR/rotkeeper.sh" | cut -d'"' -f2)

if [[ -z "$CURRENT_VERSION" ]]; then
  log "ERROR" "Could not determine current version from rotkeeper.sh"
  exit 1
fi

log "INFO" "Current version is $CURRENT_VERSION"

# Step 2: Bump the micro version
# Example: 0.3.0 -> 0.3.0.1
# Example: 0.3.0.1 -> 0.3.0.2
if [[ -n "${NEW_VERSION_OVERRIDE:-}" ]]; then
  NEW_VERSION="$NEW_VERSION_OVERRIDE"
elif [[ "$CURRENT_VERSION" =~ ^([0-9]+\.[0-9]+\.[0-9]+)\.([0-9]+)$ ]]; then
  BASE_VER="${BASH_REMATCH[1]}"
  MICRO="${BASH_REMATCH[2]}"
  NEW_MICRO=$((MICRO + 1))
  NEW_VERSION="${BASE_VER}.${NEW_MICRO}"
else
  # Treat as new micro branch
  NEW_VERSION="${CURRENT_VERSION}.1"
fi

log "INFO" "Bumping version to $NEW_VERSION"

# Step 3: Global File Replacements
if [[ "$DRY_RUN" == true ]]; then
  log "DRYRUN" "Would update scripts to $NEW_VERSION"
else
  for f in "$ROOT_DIR/rotkeeper.sh" "$SCRIPT_DIR"/*.sh; do
    awk -v old_ver="$CURRENT_VERSION" -v new_ver="$NEW_VERSION" '
      {
        gsub("VERSION=\"" old_ver "\"", "VERSION=\"" new_ver "\"")
        gsub(/VERSION="\$\{ROTKEEPER_VERSION:-[0-9.]+\}"/, "VERSION=\"${ROTKEEPER_VERSION:-" new_ver "}\"")
        gsub("#  Version : " old_ver, "#  Version : " new_ver)
        gsub("# Version: " old_ver, "# Version: " new_ver)
        gsub("\\(v" old_ver "\\)", "(v" new_ver ")")
        gsub("v" old_ver, "v" new_ver)
        print
      }
    ' "$f" > "${f}.tmp" && mv "${f}.tmp" "$f" && chmod +x "$f"
  done
  log "INFO" "Updated version tags in all scripts."
fi

# Step 4: Inject into Living Buildlog
ROADMAP_FILE="$ROOT_DIR/home/content/docs/road-to-bones/index.md"
DATE_STR=$(date +"%Y-%m-%d %H:%M")
ENTRY="* \`v$NEW_VERSION\` - ($DATE_STR) - $MESSAGE"

if [[ -f "$ROADMAP_FILE" ]]; then
  if [[ "$DRY_RUN" == true ]]; then
    log "DRYRUN" "Would inject into roadmap: $ENTRY"
  else
    # Inject after the anchor
    awk -v entry="$ENTRY" '
      /<!-- LIVING_BUILDLOG_START -->/ {
        print $0
        print entry
        next
      }
      {print}
    ' "$ROADMAP_FILE" > "$ROADMAP_FILE.tmp" && mv "$ROADMAP_FILE.tmp" "$ROADMAP_FILE"
    log "INFO" "Injected update into Living Buildlog."
  fi
else
  log "WARN" "Roadmap file not found: $ROADMAP_FILE"
fi

# Step 5: Append to CHANGELOG.md
CHANGELOG_FILE="$ROOT_DIR/CHANGELOG.md"
if [[ -f "$CHANGELOG_FILE" ]]; then
  if [[ "$DRY_RUN" == true ]]; then
    log "DRYRUN" "Would append to CHANGELOG.md"
  else
    echo -e "\n## [$NEW_VERSION] - $(date +%Y-%m-%d)\n- $MESSAGE" >> "$CHANGELOG_FILE"
    log "INFO" "Appended to CHANGELOG.md."
  fi
fi

# Step 6: Git Commit
if [[ "$DRY_RUN" == true ]]; then
  log "DRYRUN" "Would commit changes with message: bump: $NEW_VERSION - $MESSAGE"
  log "INFO" "Bump ritual complete."
  exit 0
fi

if [[ "${COMMIT:-false}" != true ]]; then
  log "INFO" "Changes applied locally. Run with --commit to stage and commit them."
  log "INFO" "Bump ritual complete."
  exit 0
fi

cd "$ROOT_DIR"
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  log "ERROR" "Not inside a git work tree. Cannot commit."
  exit 1
fi

log "INFO" "Staging touched files..."
git add "rotkeeper.sh"
git add bones/scripts/*.sh
if [[ -f "CHANGELOG.md" ]]; then
  git add "CHANGELOG.md"
fi
if [[ -f "home/content/docs/road-to-bones/index.md" ]]; then
  git add "home/content/docs/road-to-bones/index.md"
fi

if git diff --quiet --cached; then
  log "WARN" "No changes to commit. Staged diff is empty."
else
  git commit -m "bump: $NEW_VERSION - $MESSAGE"
  log "INFO" "Committed to git repository."
fi

log "INFO" "Bump ritual complete."
```
<!-- END bones/scripts/rc-bump.sh::4ad3790b -->

<!-- START bones/scripts/rc-cleanup-bones.sh::4ad3790b -->

```bash
#!/usr/bin/env bash
# ============================================================
#   ██████╗██╗     ███████╗ █████╗ ███╗   ██╗██╗   ██╗██████╗
#  ██╔════╝██║     ██╔════╝██╔══██╗████╗  ██║██║   ██║██╔══██╗
#  ██║     ██║     █████╗  ███████║██╔██╗ ██║██║   ██║██████╔╝
#  ██║     ██║     ██╔══╝  ██╔══██║██║╚██╗██║██║   ██║██╔═══╝
#  ╚██████╗███████╗███████╗██║  ██║██║ ╚████║╚██████╔╝██║
#   ╚═════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-cleanup-bones.sh
#  Purpose : Backup and prune unneeded directories and templates from bones
#  Version : 0.4.0.3
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

show_help() {
  cat <<EOF
rc-cleanup-bones.sh — Backup and prune unneeded directories and templates from bones
v0.4.0.3

Usage: rc-cleanup-bones.sh [options]

Options:
  --version, -v    Show script version and quit
  --help, -h     Show this help message and exit
  --dry-run      Preview actions without executing
  --confirm-prune Execute pruning and deletion of ephemeral data
  --verbose      Show detailed logs
  --days N       Set retention window in days (default: 30)
EOF
  exit 0
}

source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
VERSION="${ROTKEEPER_VERSION:-0.4.0.3}"

rk_init_script "rc-cleanup-bones" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR



set -euo pipefail
IFS=$'\n\t'



RETAINDAYS=30
CONFIRM_PRUNE=false

parseflags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --version|-v) echo "$(basename "$0") v${VERSION:-unknown}"; exit 0 ;;
      --help|-h)
        show_help
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --confirm-prune)
        CONFIRM_PRUNE=true
        shift
        ;;
      --verbose)
        VERBOSE=true
        shift
        ;;
      --days)
        RETAINDAYS="$2"
        shift 2
        ;;
      *)
        break
        ;;
    esac
  done
}

checkdependencies() {
  require_bins tar find rm
}

parseflags "$@"

log "DEBUG" "DRY_RUN=$DRY_RUN, VERBOSE=$VERBOSE, RETAINDAYS=$RETAINDAYS"

main() {
  checkdependencies
  log INFO "Running rc-cleanup-bones.sh."

  BACKUPDIR="bones/backups"
  TIMESTAMP=$(date +%Y-%m-%d_%H%M)
  BACKUPNAME="bones-backup-${TIMESTAMP}.tar.gz"
  BACKUPPATH="${BACKUPDIR}/${BACKUPNAME}"

  if [[ "$DRY_RUN" == true ]] || [[ "$CONFIRM_PRUNE" == false ]]; then
    log INFO "Dry run / preview mode: simulating backup and cleanup actions"
    echo "Would create backup: $BACKUPPATH"
    echo "Would prune backups older than $RETAINDAYS days from $BACKUPDIR"
    echo "Would prune logs older than $RETAINDAYS days from bones/logs"
    echo "Would explicitly delete the following ephemeral directories under $ROOT_DIR/bones/:"
    for d in "tmp" "archive" "reports" "book-reports" "ingested"; do
      echo "  - $ROOT_DIR/bones/$d"
    done
    if [[ "$CONFIRM_PRUNE" == false && "$DRY_RUN" == false ]]; then
      log INFO "Run with --confirm-prune to execute actual deletion."
    else
      log INFO "Dry run complete: no changes made."
    fi
    log INFO "Ritual concluded at $(date +%Y-%m-%d\ %H:%M) — bones remain undisturbed."
    return 0
  fi

  log INFO "Starting cleanup sequence for $RETAINDAYS days retention."

  if [ ! -d "$BACKUPDIR" ]; then
      log WARN "Backup directory $BACKUPDIR does not exist. Creating it."
      run mkdir -p "$BACKUPDIR"
  fi

  log INFO "Backing up bones to $BACKUPPATH"

  # FIX: use -C "$ROOT_DIR" so archive paths are relative (bones/...) not absolute
  run tar --exclude="$BACKUPDIR" -czf "$BACKUPPATH" -C "$ROOT_DIR" bones

  if [[ ! -s "$BACKUPPATH" ]]; then
    log ERROR "Backup tarball appears to be missing or empty: $BACKUPNAME"
    exit 1
  fi

  BACKUPSIZE=$(du -h "$BACKUPPATH" | cut -f1)
  log INFO "Backup created successfully: $BACKUPNAME ($BACKUPSIZE)"

  log INFO "Pruning backups older than $RETAINDAYS days in $BACKUPDIR"
  run find "$BACKUPDIR" -type f -name "bones-backup-*.tar.gz" -mtime +"$RETAINDAYS" -print -delete

  LOGDIR="bones/logs"
  log INFO "Pruning logs older than $RETAINDAYS days in $LOGDIR"
  run find "$LOGDIR" -type f -mtime +"$RETAINDAYS" -print -delete

  log INFO "Removing non-essential files and folders in bones/"
  for d in "tmp" "archive" "reports" "book-reports" "ingested"; do
    target="$ROOT_DIR/bones/$d"
    if [[ -d "$target" ]]; then
      run rm -rf "$target"
    fi
  done

  log INFO "Cleanup complete: bones pruned, logs trimmed, backup created: $BACKUPNAME ($BACKUPSIZE)"
  log INFO "Ritual concluded at $(date +%Y-%m-%d\ %H:%M) — decay logged and archived."
}

main
```
<!-- END bones/scripts/rc-cleanup-bones.sh::4ad3790b -->

<!-- START bones/scripts/rc-dip.sh::4ad3790b -->

```bash
#!/usr/bin/env bash
# ============================================================
#  ██████╗ ██╗██████╗
#  ██╔══██╗██║██╔══██╗
#  ██║  ██║██║██████╔╝
#  ██║  ██║██║██╔═══╝
#  ██████╔╝██║██║
#  ╚═════╝ ╚═╝╚═╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-dip.sh
#  Purpose : Document Improvement Project - audits and fixes docs
#  Version : 0.4.0.3
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/rc-utils.sh" ]]; then
    source "$SCRIPT_DIR/rc-utils.sh"
else
    echo "FATAL: cannot source rc-utils.sh" >&2
    return 1
fi

if [[ -f "$SCRIPT_DIR/rc-env.sh" ]]; then
    source "$SCRIPT_DIR/rc-env.sh"
else
    echo "FATAL: cannot source rc-env.sh" >&2
    return 1
fi

VERSION="${ROTKEEPER_VERSION:-0.4.0.3}"

rk_init_script rc-dip "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR CONTENT_DIR DOCS_DIR REPORT_DIR BOOK_REPORT_DIR

OBSOLETE_DIR="${ROOT_DIR}/home/obsolete/docs"
MATRIX_FILE="${DOCS_DIR}/dip-matrix.md"
DATE_STR=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

get_fs_date() {
    local file=$1
    if [ -f "$file" ]; then
        if stat --version >/dev/null 2>&1; then date -u -d "@$(stat -c %Y "$file")" "+%Y-%m-%d"; else TZ=UTC stat -f "%Sm" -t "%Y-%m-%d" "$file"; fi
    else
        echo "Missing"
    fi
}

get_fs_iso() {
    local file=$1
    if [ -f "$file" ]; then
        if stat --version >/dev/null 2>&1; then date -u -d "@$(stat -c %Y "$file")" "+%Y-%m-%dT%H:%M:%SZ"; else TZ=UTC stat -f "%Sm" -t "%Y-%m-%dT%H:%M:%SZ" "$file"; fi
    else
        echo "0000-00-00T00:00:00Z"
    fi
}

log "INFO" "Starting Document Improvement Project audit..."

AUTOPSY_REPORT="$REPORT_DIR/autopsy-outputs.md"
FSBOOK_CATALOG="$BOOK_REPORT_DIR/rotkeeper-files.md"

# 1. Read autopsy report to build artifact exclusions
declare -A AUTOPSY_EXCLUDES
if [[ -f "$AUTOPSY_REPORT" ]]; then
    log "INFO" "Reading autopsy outputs report for artifact exclusions..."
    while IFS= read -r line; do
        [[ "$line" =~ ^\|[[:space:]]+[0-9] ]] || continue
        path_col=$(echo "$line" | awk -F'|' '{print $4}' | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//;s/`//g')
        path_col=$(echo "$path_col" | awk '{print $1}')

        # Add the exact path or its prefix
        if [[ ! "$path_col" =~ \(unresolved: ]]; then
            AUTOPSY_EXCLUDES["$path_col"]=1
            first_dir=$(echo "$path_col" | cut -d/ -f1)
            if [[ -n "$first_dir" ]] && [[ ! "$first_dir" =~ ^- ]] && [[ ${#first_dir} -ge 4 ]]; then
                AUTOPSY_EXCLUDES["$first_dir"]=1
            fi
            dir_path=$(dirname -- "$path_col")
            if [[ "$dir_path" != "." ]] && [[ ! "$dir_path" =~ ^- ]] && [[ ${#dir_path} -ge 4 ]]; then
               AUTOPSY_EXCLUDES["$dir_path"]=1
            fi
        else
            if [[ "$path_col" =~ ^([^ ]+)/\(unresolved: ]]; then
                known_dir="${BASH_REMATCH[1]}"
                if [[ ! "$known_dir" =~ ^- ]]; then
                    AUTOPSY_EXCLUDES["$known_dir"]=1
                fi
            fi
        fi
    done < "$AUTOPSY_REPORT"
else
    log "WARN" "Autopsy report not found at $AUTOPSY_REPORT. Run rc-autopsy.sh --all first."
fi

# Hardcode some directories that should never be audited
AUTOPSY_EXCLUDES[".git"]=1
AUTOPSY_EXCLUDES[".github"]=1
AUTOPSY_EXCLUDES[".vscode"]=1
AUTOPSY_EXCLUDES[".idea"]=1
AUTOPSY_EXCLUDES["home/content"]=1
AUTOPSY_EXCLUDES["home/assets"]=1
AUTOPSY_EXCLUDES["messages-from-my-friends"]=1
AUTOPSY_EXCLUDES["tmp"]=1
AUTOPSY_EXCLUDES["bones/releases"]=1
AUTOPSY_EXCLUDES["bones/tmp"]=1
AUTOPSY_EXCLUDES["bones/archive"]=1
AUTOPSY_EXCLUDES["bones/logs"]=1
AUTOPSY_EXCLUDES["bones/reports"]=1
AUTOPSY_EXCLUDES["bones/book-reports"]=1
AUTOPSY_EXCLUDES["output"]=1
AUTOPSY_EXCLUDES["bones/asset-manifest.yaml"]=1

# 2. Discover Core Files from fsbook catalog
CORE_FILES=()
if [[ ! -f "$FSBOOK_CATALOG" ]]; then
    log "INFO" "FSBook catalog not found at $FSBOOK_CATALOG. Auto-generating..."
    bash "$SCRIPT_DIR/rc-book.sh" --fsbook
fi

if [[ -f "$FSBOOK_CATALOG" ]]; then
    log "INFO" "Reading fsbook catalog for file discovery..."
    while IFS= read -r line; do
        if [[ "$line" =~ ^-[[:space:]]+(.*) ]]; then
            file_path="${BASH_REMATCH[1]}"
            file_path=$(echo "$file_path" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')

            # Remove leading ./ if present
            file_path="${file_path#./}"

            # Ensure it is a valid path that wasn't excluded
            exclude=false
            for excl in "${!AUTOPSY_EXCLUDES[@]}"; do
                if [[ "$file_path" == "$excl" || "$file_path" == "$excl/"* ]]; then
                    exclude=true
                    break
                fi
            done

            if [[ "$exclude" == false ]]; then
                if [[ "$file_path" =~ \.(png|css|md|DS_Store|db)$ ]]; then
                    continue
                fi
                if [[ -n "$file_path" ]]; then
                   CORE_FILES+=("$file_path")
                fi
            fi
        fi
    done < "$FSBOOK_CATALOG"
else
    log "ERROR" "FSBook catalog could not be generated. File discovery cannot proceed. Run rc-book.sh --fsbook to debug."
    exit 1
fi

declare -A EXPECTED_DOCS
for file in "${CORE_FILES[@]}"; do
    BASE_NO_EXT=$(get_base_no_ext "$file")
    if [ "$BASE_NO_EXT" == "$file" ]; then
        DOC_PATH="${DOCS_DIR}/${file}.md"
    else
        DOC_PATH="${DOCS_DIR}/${BASE_NO_EXT}.md"
    fi
    EXPECTED_DOCS["$DOC_PATH"]="$file"
done

# 3. Whisk Obsolete Docs
log "INFO" "Checking for obsolete docs..."
mapfile -d '' EXISTING_DOCS < <(find "$DOCS_DIR" -type f -name "*.md" -print0)

declare -A WHITELIST
WHITELIST_FILE="$CONFIG_DIR/dip-whitelist.txt"
if [[ -f "$WHITELIST_FILE" ]]; then
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        WHITELIST["$ROOT_DIR/$line"]=1
    done < "$WHITELIST_FILE"
fi

declare -a UNOWNED_DOCS=()

for doc in "${EXISTING_DOCS[@]}"; do
    [[ "$doc" == "$MATRIX_FILE" ]] && continue
    [[ -n "${WHITELIST["$doc"]:-}" ]] && continue

    if [[ -z "${EXPECTED_DOCS["$doc"]:-}" ]]; then
        if ! grep -q "^target_file:" "$doc"; then
            UNOWNED_DOCS+=("$doc")
            continue
        fi

        REL_PATH="${doc#"$DOCS_DIR"/}"
        DEST_PATH="${OBSOLETE_DIR}/${REL_PATH}"
        DEST_DIR=$(dirname "$DEST_PATH")

        if [[ "${DRY_RUN:-false}" == true ]]; then
            log "DRY-RUN" "Would whisk obsolete doc: $doc -> $DEST_PATH"
        else
            mkdir -p "$DEST_DIR"
            mv "$doc" "$DEST_PATH"
            log "INFO" "Whisked obsolete doc: $REL_PATH"
        fi
    fi
done


inject_env() {
    local doc_path="$1"

    # Source rc-env.sh to get the variables
    source "${SCRIPT_DIR}/rc-env.sh"

    local env_list
    env_list=$(cat <<INNER_EOF
- **\$ROOT_DIR**: $ROOT_DIR
- **\$OUTPUT_DIR**: $OUTPUT_DIR
- **\$CONTENT_DIR**: $CONTENT_DIR
- **\$ASSETS_DIR**: $ASSETS_DIR
- **\$DOCS_DIR**: $DOCS_DIR
- **\$HELP_DIR**: $HELP_DIR
- **\$BONES_DIR**: $BONES_DIR
- **\$SCRIPT_DIR**: $SCRIPT_DIR
- **\$CONFIG_DIR**: $CONFIG_DIR
- **\$LOG_DIR**: $LOG_DIR
- **\$TMP_DIR**: $TMP_DIR
- **\$ARCHIVE_DIR**: $ARCHIVE_DIR
- **\$REPORT_DIR**: $REPORT_DIR
- **\$BOOK_REPORT_DIR**: $BOOK_REPORT_DIR
- **\$TEMPLATE_DIR**: $TEMPLATE_DIR
- **\$META_DIR**: $META_DIR
- **\$WEB_DIR**: $WEB_DIR
INNER_EOF
)

    export ENV_LIST="$env_list"
    local marker="<!-- DIP-ENV-EXTRACTED: $(date +%F) -->"

    awk -v marker="$marker" '
    /^## Environment/ { print $0; print marker; next }
    /TODO: Stitch environment variables\./ { print ENVIRON["ENV_LIST"]; next }
    { print $0 }
    ' "$doc_path" > "${doc_path}.tmp" && mv "${doc_path}.tmp" "$doc_path"
}



inject_cli_usage() {
    local doc_path="$1"
    local target_script="$2"
    local help_report="$REPORT_DIR/autopsy-help.md"

    if [[ ! -f "$help_report" ]]; then
        return 0
    fi

    local script_name
    script_name=$(basename "$target_script")

    local help_content
    help_content=$(sed -n "/^## $script_name\$/,/^## /{ /^## /d; p; }" "$help_report" | sed -e '1{/^$/d;}' | sed -e '${/^$/d;}')

    if [[ -z "$help_content" ]]; then
        return 0
    fi

    export HELP_CONTENT="$help_content"
    local marker="<!-- DIP-HELP-EXTRACTED: $(date +%F) -->"

    awk -v marker="$marker" '
    /^###### CLI Usage/ { print $0; print marker; next }
    /TODO: Stitch extracted help block\./ { print ENVIRON["HELP_CONTENT"]; next }
    { print $0 }
    ' "$doc_path" > "${doc_path}.tmp" && mv "${doc_path}.tmp" "$doc_path"
}


inject_necromancer_notes() {
    local doc_path=$1
    local target_script_name=$2

    if [[ ! -d "$CONTENT_DIR/messages" ]]; then
        return 0
    fi

    local extracted_body=""

    for msg_file in "$CONTENT_DIR/messages"/*.md; do
        [[ -f "$msg_file" ]] || continue

        if grep -q 'report_type: "necromancer-notes"' "$msg_file" && grep -q "subject_script: \"$target_script_name\"" "$msg_file"; then
            extracted_body=$(sed '1{/^---$/!q;}; 1,/^---$/d' "$msg_file")
            break
        fi
    done

    if [[ -z "$extracted_body" ]]; then
        return 0
    fi

    export EXTRACTED_BODY="$extracted_body"
    local marker="<!-- DIP-SOUL-EXTRACTED: $(date +%F) -->"

    awk -v marker="$marker" '
    /^#### Necromancer'\''s Notes/ || /^## Necromancer'\''s Notes/ { print $0; print marker; next }
    /TODO: Stitch necromancer notes\./ { print ENVIRON["EXTRACTED_BODY"]; next }
    { print $0 }
    ' "$doc_path" > "${doc_path}.tmp" && mv "${doc_path}.tmp" "$doc_path"
    unset EXTRACTED_BODY
}


# 3.5 Verify Folder Souls
log "INFO" "Verifying folder souls..."
find "$ROOT_DIR" -type d | while read -r DIR; do
    [[ "$DIR" == "$ROOT_DIR" ]] && continue
    # Skip excluded directories
    REL_DIR="${DIR#"$ROOT_DIR"/}"
    [[ -z "$REL_DIR" ]] && continue
    exclude=false
    for excl in "${!AUTOPSY_EXCLUDES[@]}"; do
        if [[ "$REL_DIR" == "$excl" || "$REL_DIR" == "$excl/"* || "$REL_DIR" == .git* ]]; then
            exclude=true
            break
        fi
    done
    [[ "$exclude" == true ]] && continue

    if [[ -d "$DIR" ]]; then
        SOUL_FILE="$META_DIR/${REL_DIR}.soul.md"
        EXPECTED_DOCS["$SOUL_FILE"]="$REL_DIR"
    fi
done

# 4. Stub Missing Docs
log "INFO" "Checking for missing docs..."
for doc_path in "${!EXPECTED_DOCS[@]}"; do
    target_file="${EXPECTED_DOCS["$doc_path"]}"
    if [ ! -f "$doc_path" ]; then
        if [[ "${DRY_RUN:-false}" == true ]]; then
            log "DRY-RUN" "Would stub missing doc: $doc_path"
        else
            mkdir -p "$(dirname "$doc_path")"
            TITLE=$(basename "$doc_path" .md)
            cat << STUB > "$doc_path"
---
target_file: "$target_file"
date: "$DATE_STR"
template: "rotkeeper-doc.html"
status: "stub"
version: "0.1.0"
author: "Rotkeeper DIP"
project: "Rotkeeper"
---

# $TITLE

Documentation for \`$target_file\`. This file was auto-generated by the Document Improvement Project (DIP).

## Overview
<!-- DIP-GENERATED-MARKER: Overview -->
TODO: Provide a brief overview of what this file does.

###### CLI Usage
TODO: Stitch extracted help block.

## Environment
<!-- DIP-ENV-EXTRACTED: 0000-00-00T00:00:00Z -->
TODO: Stitch environment variables.

## Ritual History
<!-- DIP-HISTORY-EXTRACTED: 0000-00-00T00:00:00Z -->
TODO: Stitch ritual history.

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 0000-00-00T00:00:00Z -->
TODO: Stitch necromancer notes.
STUB
            inject_cli_usage "$doc_path" "$target_file"
            inject_env "$doc_path"
            inject_necromancer_notes "$doc_path" "$(basename "$target_file")"
            log "INFO" "Stubbed missing doc: $doc_path"
        fi
    fi
done

# 5. Stitch Frankenstein Pillars
log "INFO" "Stitching dynamic content into Frankenstein pillars..."

stitch_pillar() {
    local doc_path="$1"
    local marker="$2"
    local new_content="$3"
    local source_mtime="$4"

    if ! grep -q "<!-- $marker:" "$doc_path"; then
        return
    fi

    local doc_mtime
    doc_mtime=$(grep -o "<!-- $marker: [0-9TZ:-]* -->" "$doc_path" | grep -o "[0-9TZ:-]\{10,\}") || true

    if [[ -z "$doc_mtime" || "$source_mtime" > "$doc_mtime" ]]; then
        local tmp_file="${doc_path}.tmp"
        export NEW_CONTENT="$new_content"
        export DATE_STR="$DATE_STR"
        export MARKER="$marker"

        awk '
        BEGIN { skip=0 }
        skip && /^## / { skip=0 }
        $0 ~ "<!-- " ENVIRON["MARKER"] ":" {
            sub(/<!-- [^:]+:.*-->/, "<!-- " ENVIRON["MARKER"] ": " ENVIRON["DATE_STR"] " -->")
            print $0
            print ""
            print ENVIRON["NEW_CONTENT"]
            skip=1
            next
        }
        !skip { print $0 }
        ' "$doc_path" > "$tmp_file"
        mv "$tmp_file" "$doc_path"
    fi
}

for doc_path in "${!EXPECTED_DOCS[@]}"; do
    if [[ ! -f "$doc_path" ]]; then continue; fi
    target_file="${EXPECTED_DOCS["$doc_path"]}"
    script_name=$(basename "$target_file")

    # Pillar 2: Ritual History
    history_content=""
    history_mtime="0000-00-00"
    for log_file in "$ROOT_DIR/CHANGELOG.md" "$DOCS_DIR/road-to-bones/index.md"; do
        if [[ -f "$log_file" ]]; then
            fm_mtime=$(get_fs_iso "$log_file")
            [[ "$fm_mtime" > "$history_mtime" ]] && history_mtime="$fm_mtime"
            matches=$(grep -i "$script_name" "$log_file" | sed 's/^/- /' || true)
            if [[ -n "$matches" ]]; then
                history_content+="$matches"$'\n'
            fi
        fi
    done
    history_content=$(echo "$history_content" | grep -v '^$' || true)
    if [[ -n "$history_content" ]]; then
        stitch_pillar "$doc_path" "DIP-HISTORY-EXTRACTED" "$history_content" "$history_mtime"
    fi

    # Pillar 3: Necromancer's Notes
    soulbody=$(read_meta_sidecar_body "$target_file")
    if [[ -n "$soulbody" ]]; then
        base_no_ext=$(get_base_no_ext "$target_file")
        soulmtime=$(get_fs_iso "$(get_sidecar_path "$target_file")")

        # Auto-upgrade legacy documentation files to include the marker if missing
        if ! grep -q "<!-- DIP-SOUL-EXTRACTED:" "$doc_path"; then
            echo -e "
## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 0000-00-00T00:00:00Z -->
TODO: Stitch necromancer notes." >> "$doc_path"
        fi

        stitch_pillar "$doc_path" "DIP-SOUL-EXTRACTED" "$soulbody" "$soulmtime"
    fi
done

# 6. Check Formatting & Generate Matrix
log "INFO" "Generating DIP Matrix at $MATRIX_FILE..."

if [[ "${DRY_RUN:-false}" == true ]]; then
    log "DRY-RUN" "Would generate DIP matrix at $MATRIX_FILE"
else
    cat << 'MATRIX' > "$MATRIX_FILE"
---
title: "Document Improvement Project (DIP) Matrix"
date: "GENERATED_DATE"
template: "rotkeeper-doc.html"
---

# Document Improvement Project Matrix

This page tracks the documentation status of core project files.

| Target File | Doc Page | Last Code Edit | Last Doc Edit | Status |
|-------------|----------|----------------|---------------|--------|
MATRIX

    content=$(<"$MATRIX_FILE")
    printf '%s\n' "${content//GENERATED_DATE/$DATE_STR}" > "$MATRIX_FILE"
fi



declare -A STAT_COUNTS
STAT_COUNTS=(["OK"]=0 ["Stub"]=0 ["Missing"]=0 ["Stale"]=0 ["unowned-doc"]=0)

for doc_path in "${!EXPECTED_DOCS[@]}"; do
    target_file="${EXPECTED_DOCS["$doc_path"]}"

    # Read status from doc frontmatter
    status="unknown"
    if [ -f "$doc_path" ]; then
        # Check if file has frontmatter
        if grep -q "^---$" "$doc_path"; then
            status=$(sed -n 's/^status: "\(.*\)"/\1/p' "$doc_path" | head -n 1)
        fi
    else
        status="missing"
    fi
    [[ -z "$status" ]] && status="unknown"

    code_date=$(get_fs_date "$ROOT_DIR/$target_file")
    doc_date=$(get_fs_date "$doc_path")

    # Stale/Needs Review Detection
    if [[ "$code_date" != "Missing" && "$doc_date" != "Missing" && "$code_date" > "$doc_date" ]]; then
        status="Stale"
    fi

    # TODO Cross-Check
    if [[ "$status" == "complete" || "$status" == "OK" ]]; then
        todo_count=$(grep -c "^TODO:" "$doc_path" || true)
        if [[ "$todo_count" -gt 0 ]]; then
            status="OK (${todo_count} TODOs remain)"
        fi
    fi

    base_stat="$status"
    if [[ "$status" =~ ^OK ]]; then base_stat="OK"; fi
    if [[ "${status,,}" == "stub" ]]; then base_stat="Stub"; fi
    if [[ "${status,,}" == "stale" ]]; then base_stat="Stale"; fi
    if [[ "${status,,}" == "missing" ]]; then base_stat="Missing"; fi
    STAT_COUNTS["$base_stat"]=$(( ${STAT_COUNTS["$base_stat"]:-0} + 1 ))

    # Format paths relative to ROOT_DIR for matrix display
    rel_doc="${doc_path#"$ROOT_DIR"/}"

    if [[ "${DRY_RUN:-false}" == false ]]; then
        echo "| \`$target_file\` | [$rel_doc]($rel_doc) | $code_date | $doc_date | $status |" >> "$MATRIX_FILE"
    fi
done

for doc_path in "${UNOWNED_DOCS[@]}"; do
    rel_doc="${doc_path#"$ROOT_DIR"/}"
    doc_date=$(get_fs_date "$doc_path")
    status="unowned-doc"
    STAT_COUNTS["unowned-doc"]=$((STAT_COUNTS["unowned-doc"] + 1))
    if [[ "${DRY_RUN:-false}" == false ]]; then
        echo "| \`Unknown\` | [$rel_doc]($rel_doc) | Missing | $doc_date | $status |" >> "$MATRIX_FILE"
    fi
done

if [[ "${DRY_RUN:-false}" == false ]]; then
    echo "" >> "$MATRIX_FILE"
    echo "**Totals:** OK: ${STAT_COUNTS["OK"]:-0} | Stub: ${STAT_COUNTS["Stub"]:-0} | Missing: ${STAT_COUNTS["Missing"]:-0} | Stale: ${STAT_COUNTS["Stale"]:-0} | Unowned: ${STAT_COUNTS["unowned-doc"]:-0}" >> "$MATRIX_FILE"
    log "INFO" "DIP audit complete. See $MATRIX_FILE for details."
fi
```
<!-- END bones/scripts/rc-dip.sh::4ad3790b -->

<!-- START bones/scripts/rc-env.sh::4ad3790b -->

```bash
#!/usr/bin/env bash
# ============================================================
#  ███████╗███╗   ██╗██╗   ██╗
#  ██╔════╝████╗  ██║██║   ██║
#  █████╗  ██╔██╗ ██║██║   ██║
#  ██╔══╝  ██║╚██╗██║╚██╗ ██╔╝
#  ███████╗██║ ╚████║ ╚████╔╝
#  ╚══════╝╚═╝  ╚═══╝  ╚═══╝
# ============================================================
#  Project : Rotkeeper
#  Script  : rc-env.sh
#  Purpose : Dynamic Environment Bootstrap — Portability Hardening
#  Version : 0.4.0.3
# ============================================================

VERSION="0.4.0.3"
[[ -n "$BASH_VERSION" ]] || {
  echo "[ERROR] rc-env.sh must be sourced in Bash." >&2
  return 1 2>/dev/null || exit 1
}

# Core structural bounds
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BONES_DIR="$ROOT_DIR/bones"
SCRIPT_DIR="$BONES_DIR/scripts"
CONFIG_DIR="$BONES_DIR/config"
LOG_DIR="$BONES_DIR/logs"
TMP_DIR="$BONES_DIR/tmp"
ARCHIVE_DIR="$BONES_DIR/archive"
REPORT_DIR="$BONES_DIR/reports"
BOOK_REPORT_DIR="$BONES_DIR/book-reports"
META_DIR="$BONES_DIR/meta"

# Dynamic layout parsing before fixing layout-dependent constants
# Looks at bones/config/rotkeeper.yaml first, drops back to root file for flat dist models
CONFIG_TARGET="$CONFIG_DIR/rotkeeper.yaml"
[[ ! -f "$CONFIG_TARGET" && -f "$ROOT_DIR/config/rotkeeper.yaml" ]] && CONFIG_TARGET="$ROOT_DIR/config/rotkeeper.yaml"

LAYOUT_STYLE="crypt"
if [[ -f "$CONFIG_TARGET" ]]; then
  LAYOUT_STYLE=$(grep -E '^layout_style:' "$CONFIG_TARGET" | cut -d'"' -f2 || echo "crypt")
fi

case "${LAYOUT_STYLE,,}" in
  "busy")
    # Pull templates, assets, and markdown roots up into visible project space
    TEMPLATE_DIR="$ROOT_DIR/templates"
    ASSETS_DIR="$ROOT_DIR/assets"
    CONTENT_DIR="$ROOT_DIR/home/content"
    OUTPUT_DIR="$ROOT_DIR/output"
    ;;

  "sterile")
    # Traditional non-spooky enterprise conventions
    TEMPLATE_DIR="$ROOT_DIR/config/templates"
    ASSETS_DIR="$ROOT_DIR/src/assets"
    CONTENT_DIR="$ROOT_DIR/src/content"
    OUTPUT_DIR="$ROOT_DIR/dist"
    ;;

  "crypt"|*)
    # Standard deep brutalist encapsulation mode
    TEMPLATE_DIR="$BONES_DIR/templates"
    ASSETS_DIR="$ROOT_DIR/home/assets"
    CONTENT_DIR="$ROOT_DIR/home/content"
    OUTPUT_DIR="$ROOT_DIR/output"
    ;;
esac

DOCS_DIR="$CONTENT_DIR/docs"
HELP_DIR="$CONTENT_DIR/help"
WEB_DIR="$OUTPUT_DIR"

export ROOT_DIR BONES_DIR OUTPUT_DIR CONTENT_DIR ASSETS_DIR DOCS_DIR HELP_DIR
export LOG_DIR TMP_DIR CONFIG_DIR ARCHIVE_DIR REPORT_DIR BOOK_REPORT_DIR SCRIPT_DIR TEMPLATE_DIR META_DIR
export WEB_DIR LAYOUT_STYLE
```
<!-- END bones/scripts/rc-env.sh::4ad3790b -->

<!-- START bones/scripts/rc-glue.sh::4ad3790b -->

```bash
#!/usr/bin/env bash
# ============================================================
#   ██████╗ ██╗     ██╗   ██╗███████╗
#  ██╔════╝ ██║     ██║   ██║██╔════╝
#  ██║  ███╗██║     ██║   ██║█████╗
#  ██║   ██║██║     ██║   ██║██╔══╝
#  ╚██████╔╝███████╗╚██████╔╝███████╗
#   ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-glue.sh
#  Purpose : Generate navigation glue (index.md) for unindexed directories
#  Version : 0.4.0.3
# ------------------------------------------------------------

set -euo pipefail
FORCE_GLUE=false

# shellcheck disable=SC2034


source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
VERSION="${ROTKEEPER_VERSION:-0.4.0.3}"

rk_init_script "rc-glue" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR CONTENT_DIR DOCS_DIR

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE_GLUE=true; shift ;;
    *) shift ;;
  esac
done

main() {
  log "INFO" "Applying navigation glue to unindexed tombs in $CONTENT_DIR..."

  # Process bottom-up to ensure we only glue things that make sense
  find "$CONTENT_DIR" -type d -print0 | while IFS= read -r -d '' DIR; do
    INDEX_FILE="$DIR/index.md"

    IS_EXISTING_CUSTOM=false
    if [[ -f "$INDEX_FILE" ]]; then
      if grep -q "rotkeeper_glued: true" "$INDEX_FILE"; then
        if [[ "$FORCE_GLUE" == true ]]; then
            log "INFO" "Overwriting existing auto-glued index with --force: $INDEX_FILE"
            rm "$INDEX_FILE"
        else
            log "WARN" "Auto-glued index exists at $INDEX_FILE. Skipping. Use --force to replace."
            continue
        fi
      else
        IS_EXISTING_CUSTOM=true
      fi
    fi

    DIR_NAME=$(basename "$DIR")
    if [[ "$DIR" == "$CONTENT_DIR" ]]; then
      DIR_NAME="Root Index"
    fi

    # --- Path-Mirrored Folder Soul Ingestion ---
    # e.g., "home/content/docs/bones" -> "bones/meta/docs/bones.soul.md"
    REL_DIR_PATH="${DIR#"$CONTENT_DIR"/}"

    if [[ -z "$REL_DIR_PATH" || "$REL_DIR_PATH" == "$DIR" ]]; then
        SOUL_FILE="$META_DIR/rotkeeper.soul.md" # Root fallthrough
    else
        SOUL_FILE="$META_DIR/${REL_DIR_PATH}.soul.md"
    fi

    # Initialize baseline frontmatter defaults
    DEFAULT_YAML="title: \"Index of $DIR_NAME\"
template: \"rotkeeper-blog.html\"
rotkeeper_glued: true"

    if [[ -f "$SOUL_FILE" ]]; then
        log "INFO" "💀 Found folder soul tombstone: $SOUL_FILE"
        # Overwrite auto-generated structural headers with data pulled directly from the target folder's sidecar
        # Merge the complete frontmatter dictionary blocks directly
        MERGED_YAML=$(yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' <(echo "$DEFAULT_YAML") <(yq eval --front-matter="extract" '.' "$SOUL_FILE"))
        SOUL_TITLE=$(echo "$MERGED_YAML" | yq eval '.title // ""' -)
        FRONTMATTER="---
${MERGED_YAML}
---"
    else
        SOUL_TITLE="Index of $DIR_NAME"
        FRONTMATTER="---
${DEFAULT_YAML}
---"
    fi

    log "INFO" "Generating glued metadata map for $DIR_NAME..."

    GLUE_CONTENT="<!-- ROTKEEPER-GLUE-START -->"
    while IFS= read -r -d '' SUBDIR; do
      SUBDIR_NAME=$(basename "$SUBDIR")
      GLUE_CONTENT+=$'\n'"- [$SUBDIR_NAME/](<$SUBDIR_NAME/index.html>)"
    done < <(find "$DIR" -maxdepth 1 -mindepth 1 -type d -print0 | sort -z)

    while IFS= read -r -d '' FILE; do
      FILE_NAME=$(basename "$FILE" .md)
      GLUE_CONTENT+=$'\n'"- [$FILE_NAME](<$FILE_NAME.html>)"
    done < <(find "$DIR" -maxdepth 1 -mindepth 1 -type f -name "*.md" ! -name "index.md" -print0 | sort -z)
    GLUE_CONTENT+=$'\n'"<!-- ROTKEEPER-GLUE-END -->"

    if [[ "$IS_EXISTING_CUSTOM" == true ]]; then
        local MARKERS_OK=false
        if awk '
            BEGIN { start=0; end=0; ok=0 }
            /<!-- ROTKEEPER-GLUE-START -->/ { start++ }
            /<!-- ROTKEEPER-GLUE-END -->/ { end++; if(start == 1) ok=1 }
            END { if (start == 1 && end == 1 && ok == 1) exit 0; else exit 1 }
        ' "$INDEX_FILE"; then
            MARKERS_OK=true
        fi

        if [[ "$MARKERS_OK" == true ]]; then
            log "INFO" "Updating existing custom index with boundaries: $INDEX_FILE"
            GLUE_CONTENT="$GLUE_CONTENT" gawk '
                BEGIN { p=1 }
                /<!-- ROTKEEPER-GLUE-START -->/ {
                    print ENVIRON["GLUE_CONTENT"]
                    p=0
                }
                /<!-- ROTKEEPER-GLUE-END -->/ {
                    p=1
                    next
                }
                p { print }
            ' "$INDEX_FILE" > "${INDEX_FILE}.tmp"
            mv "${INDEX_FILE}.tmp" "$INDEX_FILE"
        else
            if grep -q "<!-- ROTKEEPER-GLUE" "$INDEX_FILE"; then
                log "WARN" "Malformed glue boundaries in custom index, appending to footer: $INDEX_FILE"
            fi
            log "INFO" "Appending dynamic block to footer of custom index: $INDEX_FILE"
            printf '\n%s\n' "$GLUE_CONTENT" >> "$INDEX_FILE"
        fi
    else
        printf '%s\n\n# %s\n\n%s\n' "$FRONTMATTER" "$SOUL_TITLE" "$GLUE_CONTENT" > "$INDEX_FILE"
    fi

    log "INFO" "Created/Updated structured tomb index: $INDEX_FILE"
  done

  log "INFO" "Navigation glue applied successfully."
}

main "$@"
```
<!-- END bones/scripts/rc-glue.sh::4ad3790b -->

<!-- START bones/scripts/rc-ingest.sh::4ad3790b -->

```bash
#!/usr/bin/env bash
# ============================================================
#  ██╗███╗   ██╗ ██████╗ ███████╗███████╗████████╗
#  ██║████╗  ██║██╔════╝ ██╔════╝██╔════╝╚══██╔══╝
#  ██║██╔██╗ ██║██║  ███╗█████╗  ███████╗   ██║
#  ██║██║╚██╗██║██║   ██║██╔══╝  ╚════██║   ██║
#  ██║██║ ╚████║╚██████╔╝███████╗███████║   ██║
#  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚══════╝   ╚═╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-ingest.sh
#  Purpose : Ingests .tar.gz archives from an inbox into the local content repository safely
#  Version : 0.4.0.3
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

show_help() {
  cat << EOF
rc-ingest.sh — Rotkeeper Ingestion Pipeline

Usage: rc-ingest.sh [options]

Options:
  --version, -v    Show script version and quit
  --help, -h       Show this help message and exit
  --inbox DIR      Specify a custom inbox directory (default: messages-from-my-friends)
  --verbose        Enable detailed debug logging
EOF
  exit 0
}

source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
VERSION="${ROTKEEPER_VERSION:-0.4.0.3}"

rk_init_script "rc-ingest" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR CONTENT_DIR DOCS_DIR
set -euo pipefail
IFS=$'\n\t'



# --- Shared Configuration ---
INBOX_DIR="messages-from-my-friends"

# --- Flag parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version|-v) echo "$(basename "$0") v${VERSION:-unknown}"; exit 0 ;;
    --inbox)     INBOX_DIR="$2"; shift 2 ;;
    --verbose)   VERBOSE=true; shift ;;
    --help|-h)   show_help ;;
    *) break ;;
  esac
done

main() {
    log "INFO" "Running rc-ingest.sh"
    check_dependencies

    INGESTED_ARCHIVE_DIR="bones/ingested"
    QUARANTINE_DIR="bones/quarantine"
    TARGET_CONTENT_DIR="$CONTENT_DIR/messages"

    mkdir -p "$INGESTED_ARCHIVE_DIR"
    mkdir -p "$QUARANTINE_DIR"
    mkdir -p "$TARGET_CONTENT_DIR"
    mkdir -p "$INBOX_DIR"

    # Check for .tar.gz files in the inbox
    shopt -s nullglob
    archives=("$INBOX_DIR"/*.tar.gz)
    shopt -u nullglob

    if [[ ${#archives[@]} -eq 0 ]]; then
      echo "📭 Inbox is empty. No new messages found in $INBOX_DIR/."
      log "INFO" "No archives found to ingest."
      exit 0
    fi

    echo "📬 Found ${#archives[@]} message(s) in inbox. Beginning ingestion..."

    for archive in "${archives[@]}"; do
      basename_archive=$(basename "$archive" .tar.gz)
      echo "📦 Ingesting: $(basename "$archive")"
      log "INFO" "Ingesting $archive"

      # Validate archive paths against traversal attacks
      safe_archive=true
      while IFS= read -r archive_path; do
        if [[ "$archive_path" == /* ]] || [[ "$archive_path" == *"../"* ]]; then
          safe_archive=false
          break
        fi
      done < <(tar -tf "$archive" 2>/dev/null || true)

      if [[ "$safe_archive" == false ]]; then
        log "WARN" "Unsafe path detected in $archive. Moving to quarantine."
        echo "⚠️  WARNING: Unsafe paths (e.g. ../ or /) found in $archive. Moved to quarantine."
        run mv "$archive" "$QUARANTINE_DIR/"
        continue
      fi

      # Create safe subdirectory for this specific payload
      SAFE_DEST="$TARGET_CONTENT_DIR/$basename_archive"
      if [[ -d "$SAFE_DEST" ]]; then
        log "WARN" "Destination $SAFE_DEST already exists. Appending timestamp."
        SAFE_DEST="${SAFE_DEST}_$(date +%s)"
      fi
      mkdir -p "$SAFE_DEST"

      # Extract to temp
      TMP_EXTRACT=$(mktemp -d)
      run tar -xzf "$archive" -C "$TMP_EXTRACT"

      # Retroactive cleanup: remove redundant docs from older payloads
      rm -rf "$TMP_EXTRACT/home/content/docs" "$TMP_EXTRACT/home/content/help" 2>/dev/null || true
      rm -f "$TMP_EXTRACT/home/content/"*_temp.md 2>/dev/null || true

      # Identify if the archive has a home/content directory structure
      if [[ -d "$TMP_EXTRACT/home/content" ]]; then
        # Move everything from home/content into the safe destination
        run mv "$TMP_EXTRACT"/home/content/* "$SAFE_DEST"/ 2>/dev/null || true
      else
        # Just move everything from the root of the extract
        run mv "$TMP_EXTRACT"/* "$SAFE_DEST"/ 2>/dev/null || true
      fi

      rm -rf "$TMP_EXTRACT"

      # Move original archive to ingested vault
      run mv "$archive" "$INGESTED_ARCHIVE_DIR/"
      echo "✅ Successfully unboxed into home/content/messages/$(basename "$SAFE_DEST")/"
    done

    echo "🎉 Ingestion complete! Applying navigation glue..."
    bash "$SCRIPT_DIR/rc-glue.sh" || true
    echo "🎉 Run ./rotkeeper.sh render to compile."
    log "INFO" "rc-ingest.sh completed successfully."
}

main "$@"
```
<!-- END bones/scripts/rc-ingest.sh::4ad3790b -->

<!-- START bones/scripts/rc-init.sh::4ad3790b -->

```bash
#!/usr/bin/env bash
# ============================================================
#  ██╗███╗   ██╗██╗████████╗
#  ██║████╗  ██║██║╚══██╔══╝
#  ██║██╔██╗ ██║██║   ██║
#  ██║██║╚██╗██║██║   ██║
#  ██║██║ ╚████║██║   ██║
#  ╚═╝╚═╝  ╚═══╝╚═╝   ╚═╝
# ============================================================
#  Project : Rotkeeper (Jules Compat Prototype)
#  Script  : rc-init.sh
#  Purpose : Minimal, non-destructive environment initialization
# ============================================================

show_help() {
  cat << EOF2
rc-init.sh — Initialize environment

Usage: rc-init.sh [options]

Options:
  --version, -v    Show script version and quit
  --help, -h       Show this help message and exit
  --dry-run        Preview actions
  --verbose        Show detailed logs

Initialization Flags:
  --with-sample    Generate starter test-file.md
  --with-assets    Run assets generation
  --with-render    Run the render ritual
  --full           Perform full reseed, sample, assets, render, and scan
EOF2
  return 0
}

# Source shared Rotkeeper helpers
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
VERSION="${ROTKEEPER_VERSION:-0.4.0.3}"

rk_init_script "rc-init" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR CONTENT_DIR DOCS_DIR

set -euo pipefail
IFS=$'\n\t'

# shellcheck disable=SC2034

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESEED_CMD="$SCRIPTDIR/rc-reseed.sh"
PROJECT_ROOT="$SCRIPTDIR/../.."

# Flags
WITH_SAMPLE=false
WITH_ASSETS=false
WITH_RENDER=false
FULL=false

# Parse custom flags
for arg in "$@"; do
    case "$arg" in
        --with-sample) WITH_SAMPLE=true ;;
        --with-assets) WITH_ASSETS=true ;;
        --with-render) WITH_RENDER=true ;;
        --full)        FULL=true ;;
    esac
done

if [[ "$FULL" == true ]]; then
    WITH_SAMPLE=true
    WITH_ASSETS=true
    WITH_RENDER=true
fi

# Make all rc-*.sh and rc-utils.bats scripts executable
log "INFO" "🔐 Blessing scripts with +x permissions..."
find "$SCRIPTDIR" -type f \( -name "rc-*.sh" -o -name "rc-*.bats" \) -exec chmod +x {} \;

main() {
    # Verify required tools
    check_dependencies
    $VERBOSE && log "INFO" "Dependencies verified."

    if [[ ! -d "$PROJECT_ROOT/bones/templates" ]]; then
        # This check might fail in pure sandbox without templates, but keeping the logic
        log "WARN" "bones/templates directory is missing (ignored in prototype if not rendering)."
    fi

    log "INFO" "🔄 Starting initialization (Minimal mode by default)..."

    if [[ "$FULL" == true ]]; then
        if [[ -f "$RESEED_CMD" ]]; then
            run "$RESEED_CMD" --force
        else
            log "WARN" "rc-reseed.sh not found in prototype, skipping reseed."
        fi
    fi

    # Create core directories non-destructively
    mkdir -p "$PROJECT_ROOT/home/content"
    mkdir -p "$PROJECT_ROOT/output"
    mkdir -p "$PROJECT_ROOT/bones/config"
    log "INFO" "✅ Verified core directories exist."

    if [[ "$WITH_SAMPLE" == true ]]; then
        cat << 'EOF_HELLO' > "$PROJECT_ROOT/home/content/test-file.md"
---
title: "Test File"
slug: test-file
template: rotkeeper-blog.html
description: "A simple starter page to demonstrate YAML frontmatter in Rotkeeper."
---

# Test File!

This is a demonstration page created during initialization.
EOF_HELLO
        log "INFO" "📄 Generated starter content at home/content/test-file.md"
    fi

    if [[ "$WITH_ASSETS" == true ]]; then
        if [[ -f "$SCRIPTDIR/rc-assets.sh" ]]; then
            run "$SCRIPTDIR/rc-assets.sh"
        else
            log "WARN" "rc-assets.sh not found in prototype, skipping."
        fi
    fi

    if [[ "$WITH_RENDER" == true ]]; then
        if [[ -f "$SCRIPTDIR/rc-render.sh" ]]; then
            run "$SCRIPTDIR/rc-render.sh" --verbose
        else
            log "WARN" "rc-render.sh not found in prototype, skipping."
        fi
    fi

    if [[ "$FULL" == true ]]; then
        if [[ -f "$SCRIPTDIR/rc-scan.sh" ]]; then
            run "$SCRIPTDIR/rc-scan.sh"
        else
            log "WARN" "rc-scan.sh not found in prototype, skipping scan."
        fi
    fi

    log "INFO" "✅ Initialization complete."
}

# Only run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```
<!-- END bones/scripts/rc-init.sh::4ad3790b -->

<!-- START bones/scripts/rc-new.sh::4ad3790b -->

```bash
#!/usr/bin/env bash
# ============================================================
#  ███╗   ██╗███████╗██╗    ██╗
#  ████╗  ██║██╔════╝██║    ██║
#  ██╔██╗ ██║█████╗  ██║ █╗ ██║
#  ██║╚██╗██║██╔══╝  ██║███╗██║
#  ██║ ╚████║███████╗╚███╔███╔╝
#  ╚═╝  ╚═══╝╚══════╝ ╚══╝╚══╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-new.sh
#  Purpose : Scaffold a new markdown file with YAML frontmatter
#  Version : 0.4.0.3
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

show_help() {
  cat << EOF
rc-new.sh — Scaffold a new markdown file with required YAML frontmatter

Usage: rotkeeper.sh new <file>

Options:
  --title "Title"        Override auto-derived title; skip slug-from-filename
  --author "Name"        Override config-derived author
  --tags "tag1,tag2"     Comma-separated tags; rendered as YAML list
  --template "file.html" Override default rotkeeper-blog.html
  --description "text"   Frontmatter description field
  --body "text"          Starting body content
  --url "https://..."    A URL to embed in the document (creates source skeleton)
  --subdir "path"        Subdirectory under home/content/ to place the file
  --version, -v          Show script version and quit
  --help, -h             Show this help message and exit
  --dry-run              Preview actions without writing files
  --verbose              Enable detailed debug logging
EOF
  exit 0
}

source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
VERSION="${ROTKEEPER_VERSION:-0.4.0.3}"

rk_init_script "rc-new" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR CONTENT_DIR DOCS_DIR

set -euo pipefail
IFS=$'\n\t'




# --- Flag parsing ---
FILE=""
TITLE_OVERRIDE=""
AUTHOR_OVERRIDE=""
TAGS=""
TEMPLATE_OVERRIDE="rotkeeper-blog.html"
DESCRIPTION=""
BODY_TEXT=""
SOURCE_URL=""
SUBDIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run|--verbose|--help|-h)
      shift
      ;;
    --title)
      TITLE_OVERRIDE="$2"
      shift 2
      ;;
    --author)
      AUTHOR_OVERRIDE="$2"
      shift 2
      ;;
    --tags)
      TAGS="$2"
      shift 2
      ;;
    --template)
      TEMPLATE_OVERRIDE="$2"
      shift 2
      ;;
    --description)
      DESCRIPTION="$2"
      shift 2
      ;;
    --body)
      BODY_TEXT="$2"
      shift 2
      ;;
    --url)
      SOURCE_URL="$2"
      shift 2
      ;;
    --subdir)
      SUBDIR="$2"
      shift 2
      ;;
    -*)
      log "ERROR" "Unknown flag: $1"
      exit 1
      ;;
    *)
      if [[ -z "$FILE" ]]; then
        FILE="$1"
        shift
      else
        log "ERROR" "Multiple files specified. Usage: rotkeeper.sh new <file>"
        exit 1
      fi
      ;;
  esac
done

main() {
    if [[ -z "$FILE" ]]; then
      log "ERROR" "No file specified. Usage: rotkeeper.sh new <file>"
      exit 1
    fi

    if [[ ! "$FILE" == *.md ]]; then
        FILE="${FILE}.md"
    fi

    if [[ -n "$SUBDIR" ]]; then
        if [[ "$FILE" == */* ]]; then
            log "WARN" "--subdir is ignored because a path was provided in the filename ($FILE)"
        else
            FILE="$SUBDIR/$FILE"
        fi
    fi

    # Ensure it's in home/content
    if [[ "$FILE" != *"home/content/"* ]]; then
        if [[ "$FILE" == /* ]]; then
            # absolute path provided, check if it's within home/content
            if [[ "$FILE" != *"/home/content/"* ]]; then
                 log "ERROR" "File must be created within home/content/"
                 exit 1
            fi
        else
            FILE="home/content/$FILE"
        fi
    fi

    mkdir -p "$(dirname "$FILE")"

    if [[ -f "$FILE" ]]; then
        log "ERROR" "File already exists: $FILE"
        exit 1
    fi

    TITLE="${TITLE_OVERRIDE:-$(basename "$FILE" .md)}"
    # slugify title
    SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9]/-/g' -e 's/-\+/-/g' -e 's/^-//' -e 's/-$//')

    AUTHOR="$AUTHOR_OVERRIDE"
    if [[ -z "$AUTHOR" ]]; then
        AUTHOR=$(yq e '.author // ""' "$CONFIG_DIR/rotkeeper.yaml" 2>/dev/null || echo "")
    fi

    TAGS_YAML=""
    if [[ -n "$TAGS" ]]; then
        TAGS_YAML="[${TAGS//,/, }]"
    fi

    if [[ "$DRY_RUN" == false ]]; then
        cat << EOF > "$FILE"
---
title: "$TITLE"
slug: $SLUG
template: $TEMPLATE_OVERRIDE
description: "${DESCRIPTION}"
EOF

        if [[ -n "$AUTHOR" ]]; then
            echo "author: \"$AUTHOR\"" >> "$FILE"
        fi

        if [[ -n "$TAGS_YAML" ]]; then
            echo "tags: $TAGS_YAML" >> "$FILE"
        fi

        if [[ -n "$SOURCE_URL" ]]; then
            echo "source_url: \"$SOURCE_URL\"" >> "$FILE"
        fi

        {
            echo "---"
            echo ""
            echo "# $TITLE"
            echo ""

            if [[ -n "$SOURCE_URL" ]]; then
                echo "## Source"
                echo ""
                echo "- **URL:** <$SOURCE_URL>"
                echo ""
                echo "## Notes"
                echo ""
                if [[ -n "$BODY_TEXT" ]]; then
                    echo "$BODY_TEXT"
                else
                    echo "<!-- Add your notes, observations, or excerpts here -->"
                fi
                echo ""
                echo "## Summary"
                echo ""
                echo "<!-- Add a summary, key points, or LLM-generated content here -->"
            else
                if [[ -n "$BODY_TEXT" ]]; then
                    echo "$BODY_TEXT"
                fi
            fi
        } >> "$FILE"

        log "INFO" "📄 Scaffolded new file at $FILE"
    else
        log "DRYRUN" "Would scaffold $FILE with title '$TITLE'"
    fi
}

main "$@"
```
<!-- END bones/scripts/rc-new.sh::4ad3790b -->

<!-- START bones/scripts/rc-pack.sh::4ad3790b -->

```bash
#!/usr/bin/env bash
# ============================================================
#  ██████╗  █████╗  ██████╗██╗  ██╗
#  ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝
#  ██████╔╝███████║██║     █████╔╝
#  ██╔═══╝ ██╔══██║██║     ██╔═██╗
#  ██║     ██║  ██║╚██████╗██║  ██╗
#  ╚═╝     ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-pack.sh
#  Purpose : Bundle rendered output into versioned .tar.gz archive and export markdown to JSON
#  Version : 0.4.0.3
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================
show_help() {
  cat << EOF
rc-pack.sh — Ritual Compression Packager (v0.3.1.4)

Usage: rc-pack.sh [options]

Options:
  --version, -v    Show script version and quit
  --help, -h       Show this help message and exit
  --dry-run        Preview actions without writing files
  --self           Archive the full Rotkeeper system (rotkeeper.sh, bones/, home/, output/)
  --content        Archive only the home/content directory to preserve source files
  --verbose        Enable detailed debug logging
EOF
  exit 0
}

source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
VERSION="${ROTKEEPER_VERSION:-0.4.0.3}"

rk_init_script "rc-pack" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR CONTENT_DIR DOCS_DIR OUTPUT_DIR
set -euo pipefail
IFS=$'\n\t'



# =============================================================================
# rc-pack.sh – Ritual Compression Packager
#
#   When rendering ends and the tombs are aligned,
#   This script collects what rot left behind.
#   With tarball and timestamp, it seals the decay,
#   And preps it for transit or end-of-day.
#
#   MODES:
#   - Default: archive only rendered output/
#   - --self:  full system bundle (rotkeeper.sh, bones/, home/, output/)
#   - --content: bundle only the home/content/ directory
#   - --dry-run: preview without writing
#
#   FUTURE:
#   - Modular targeting, asset tagging, alt formats (Tiki, Sora, etc.)
#
# 💀 MANDATE:
# Preserve the rot. Export with intention. Archive before deletion.
# =============================================================================
main() {
    log "INFO" "Running rc-pack.sh."

    SELF_MODE=false
    CONTENT_MODE=false

    # --- Flag parsing ---
    for arg in "$@"; do
      case "$arg" in
        --dry-run)   DRY_RUN=true ;;
        --verbose)   VERBOSE=true ;;
        --help|-h)   show_help ;;
        --self)      SELF_MODE=true ;;
        --content)   CONTENT_MODE=true ;;
      esac
    done

    check_dependencies
    $VERBOSE && log "DEBUG" "Dependencies verified."

    # --- Shared Configuration ---
    CONFIG_DIR="$BONES_DIR"
    ARCHIVE_DIR="$ARCHIVE_DIR"
    SOURCE_DIR="$CONTENT_DIR"
    OUTPUT_DIR="$OUTPUT_DIR"
    MANIFEST_FILE="$CONFIG_DIR/manifest.txt"
    TIMESTAMP_VERSION=$(date +%Y-%m-%d_%H%M)
    TOMB="tomb-$TIMESTAMP_VERSION.tar"
    EXPORT_JSON="$ARCHIVE_DIR/tomb-export-$TIMESTAMP_VERSION.json"

    run mkdir -p "$ARCHIVE_DIR"
    run mkdir -p "$LOG_DIR"

    # Ensure the rendered output directory exists before packing (only if default mode).
    if [[ "$SELF_MODE" == false && "$CONTENT_MODE" == false ]]; then
      if [ ! -d "$OUTPUT_DIR" ]; then
        if [[ "$DRY_RUN" == true ]]; then
          log "DRYRUN" "No output directory to pack: $OUTPUT_DIR (skipping exit)"
        else
          echo "❌ No output directory to pack: $OUTPUT_DIR"
          exit 1
        fi
      fi
    fi

    if [[ "$CONTENT_MODE" == true ]]; then
      CONTENT_ARCHIVE="tomb-content-$TIMESTAMP_VERSION.tar"
      if [[ "$DRY_RUN" == false ]]; then
        echo "📦 Packing \"$SOURCE_DIR\" into \"$CONTENT_ARCHIVE\""
        run tar --exclude="home/content/help" \
                --exclude="*_temp.md" \
                -cf "$ARCHIVE_DIR/$CONTENT_ARCHIVE" "home/content"
        count=$(tar -tf "$ARCHIVE_DIR/$CONTENT_ARCHIVE" | wc -l)
        log "INFO" "Packaged $count files into $CONTENT_ARCHIVE"
        SHA=$(sha256sum "$ARCHIVE_DIR/$CONTENT_ARCHIVE" | cut -d' ' -f1)
        echo "$CONTENT_ARCHIVE  $SHA" >> "$MANIFEST_FILE"

        run gzip -f "$ARCHIVE_DIR/$CONTENT_ARCHIVE"
        CONTENT_ARCHIVE="$CONTENT_ARCHIVE.gz"
        log "INFO" "Archived content to $CONTENT_ARCHIVE"
        echo "🧾 Archived source content to \"$ARCHIVE_DIR/$CONTENT_ARCHIVE\""
      else
        log "DRYRUN" "Would pack \"$SOURCE_DIR\" into \"$ARCHIVE_DIR/$CONTENT_ARCHIVE.gz\""
      fi
    fi

    if [[ "$SELF_MODE" == false && "$CONTENT_MODE" == false ]]; then
      if [[ "$DRY_RUN" == false ]]; then
        echo "📦 Packing \"$OUTPUT_DIR\" into \"$TOMB\""
        run tar -cf "$ARCHIVE_DIR/$TOMB" "$OUTPUT_DIR"
        count=$(tar -tf "$ARCHIVE_DIR/$TOMB" | wc -l)
        log "INFO" "Packaged $count files into $TOMB"
        SHA=$(sha256sum "$ARCHIVE_DIR/$TOMB" | cut -d' ' -f1)
        echo "$TOMB  $SHA" >> "$MANIFEST_FILE"

        # Embed metadata into archive
        METADATA_FILE="$(mktemp)"
        jq -n \
          --arg name "$TOMB" \
          --arg sha "$SHA" \
          --arg timestamp "$TIMESTAMP_VERSION" \
          --arg mode "default" \
          --arg count "$count" \
          '{name: $name, sha256: $sha, timestamp: $timestamp, mode: $mode, file_count: $count|tonumber}' > "$METADATA_FILE"
        run tar --append --file="$ARCHIVE_DIR/$TOMB" -C "$(dirname "$METADATA_FILE")" "$(basename "$METADATA_FILE")"
        run gzip -f "$ARCHIVE_DIR/$TOMB"
        rm "$METADATA_FILE"
        TOMB="$TOMB.gz"
        log "INFO" "Embedded metadata.json into $TOMB"

        echo "🧾 Archived to \"$ARCHIVE_DIR/$TOMB\""
      else
        log "DRYRUN" "Would pack \"$OUTPUT_DIR\" into \"$ARCHIVE_DIR/$TOMB\""
      fi
    fi

    if [[ "$SELF_MODE" == true ]]; then
      SELF_ARCHIVE="tombkit-$TIMESTAMP_VERSION.tar"
      echo "📦 Packing full rotkeeper system into \"$SELF_ARCHIVE\""
      run tar --exclude="$ARCHIVE_DIR" -cf "$ARCHIVE_DIR/$SELF_ARCHIVE" rotkeeper.sh bones/ home/ output/
      count=$(tar -tf "$ARCHIVE_DIR/$SELF_ARCHIVE" | wc -l)
      log "INFO" "Packaged $count files into $SELF_ARCHIVE"
      SHA=$(sha256sum "$ARCHIVE_DIR/$SELF_ARCHIVE" | cut -d' ' -f1)
      echo "$SELF_ARCHIVE  $SHA" >> "$MANIFEST_FILE"

      # Embed metadata into archive
      METADATA_FILE="$(mktemp)"
      jq -n \
        --arg name "$SELF_ARCHIVE" \
        --arg sha "$SHA" \
        --arg timestamp "$TIMESTAMP_VERSION" \
        --arg mode "self" \
        --arg count "$count" \
        '{name: $name, sha256: $sha, timestamp: $timestamp, mode: $mode, file_count: $count|tonumber}' > "$METADATA_FILE"
      run tar --append --file="$ARCHIVE_DIR/$SELF_ARCHIVE" -C "$(dirname "$METADATA_FILE")" "$(basename "$METADATA_FILE")"
      run gzip -f "$ARCHIVE_DIR/$SELF_ARCHIVE"
      rm "$METADATA_FILE"
      SELF_ARCHIVE="$SELF_ARCHIVE.gz"
      log "INFO" "Embedded metadata.json into $SELF_ARCHIVE"

      echo "🧾 Archived full tombkit to \"$ARCHIVE_DIR/$SELF_ARCHIVE\""
    fi

    if [[ "$SELF_MODE" == false && "$CONTENT_MODE" == false ]]; then
      # --- Optional JSON Export ---
      # Export all Markdown files from the source content directory into a single JSON array.

      if [[ "$DRY_RUN" == false ]]; then
        echo "🧬 Exporting .md from \"$SOURCE_DIR\" to JSON: \"$EXPORT_JSON\""
        TMP_EXPORT=$(mktemp)
        echo "[" > "$TMP_EXPORT"
        FIRST=true
        find "$SOURCE_DIR" -name '*.md' | while read -r mdfile; do
          if ! AST_CONTENT=$(pandoc "$mdfile" -t json 2>/dev/null); then
            log "ERROR" "Pandoc failed on $mdfile, skipping."
            continue
          fi

          ABS_PATH=$(realpath "$mdfile")
          REL_PATH="${mdfile#"$ROOT_DIR"/}"
          FM_CONTENT=$(yq --front-matter="extract" -o=json '.' "$mdfile" 2>/dev/null || echo "{}")

          JSON_ENTRY=$(jq -n --arg abs "$ABS_PATH" --arg rel "$REL_PATH" --argjson ast "$AST_CONTENT" --argjson fm "$FM_CONTENT" \
            '{absolute_path: $abs, relative_path: $rel, frontmatter: (if $fm != null then $fm else {} end), pandoc_ast: (if $ast != null then $ast else {} end)}')

          if [ "$FIRST" = true ]; then
            FIRST=false
          else
            echo "," >> "$TMP_EXPORT"
          fi
          echo "$JSON_ENTRY" >> "$TMP_EXPORT"
        done
        echo "]" >> "$TMP_EXPORT"
        run mv "$TMP_EXPORT" "$EXPORT_JSON"
        echo "$EXPORT_JSON" >> "$MANIFEST_FILE"
        echo "✅ Export complete: \"$EXPORT_JSON\""
      else
        log "DRYRUN" "Would export markdown from \"$SOURCE_DIR\" to JSON: \"$EXPORT_JSON\""
      fi
    fi
    log "INFO" "rc-pack.sh completed successfully."
}

main "$@"
```
<!-- END bones/scripts/rc-pack.sh::4ad3790b -->

<!-- START bones/scripts/rc-release.sh::4ad3790b -->

```bash
#!/usr/bin/env bash
# ============================================================
#  ██████╗ ███████╗██████╗ ███████╗███████╗███████╗
#  ██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝██╔════╝
#  ██████╔╝█████╗  ██████╔╝█████╗  █████╗  █████╗
#  ██╔═══╝ ██╔══╝  ██╔═══╝ ██╔══╝  ██╔══╝  ██╔══╝
#  ██║     ███████╗██║     ███████╗███████╗███████╗
#  ╚═╝     ╚══════╝╚═╝     ╚══════╝╚══════╝╚══════╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-release.sh
#  Purpose : Package the project into versioned lite, full, and dev distribution zips
# ------------------------------------------------------------
#  Three-tier model:
#    dev  — complete archive (home/ untouched, only git/outputs/tmp stripped)
#    full — standard user dist (dev scripts + book-reports + obsolete stripped, all home/ kept)
#    lite — lean runtime (full minus docs dirs and heavy splash asset)
# ============================================================
show_help() {
  cat << HELPEOF
rc-release.sh — Release Packager (Three-Tier)

Usage: rc-release.sh <VERSION> [options]

Options:
  --version, -v    Show script version and quit
  --help, -h       Show this help message and exit
  --dry-run        Preview actions without writing files
  --verbose        Enable detailed debug logging
  --tier <name>    Build only one tier: lite | full | dev (default: all three)
HELPEOF
  exit 0
}

source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
VERSION="${ROTKEEPER_VERSION:-0.4.0.3}"

rk_init_script "rc-release" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR OUTPUT_DIR
set -euo pipefail
IFS=$'\n\t'


LOG_FILE="$PWD/$LOG_FILE"

TARGET_VERSION=""
BUILD_TIER="all"
PREV_ARG=""

# --- Flag parsing ---
for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY_RUN=true ;;
    --verbose)   VERBOSE=true ;;
    --help|-h)   show_help ;;
    --tier)      : ;;
    -*) log "ERROR" "Unknown flag: $arg"; exit 1 ;;
    *)
      if [[ "$PREV_ARG" == "--tier" ]]; then
        BUILD_TIER="$arg"
      elif [[ -z "$TARGET_VERSION" ]]; then
        TARGET_VERSION="$arg"
      fi
      ;;
  esac
  PREV_ARG="$arg"
done

if [[ -n "$TARGET_VERSION" ]]; then
  VERSION="$TARGET_VERSION"
fi

if [[ -z "$VERSION" ]]; then
  log "ERROR" "No version specified. Usage: rc-release.sh <VERSION> [options]"
  exit 1
fi

check_dependencies
require_bins rsync zip

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RELEASE_DIR="$PROJECT_ROOT/bones/releases"
STAGING_DIR="$PROJECT_ROOT/bones/tmp/release-staging"

cleanup() {
    log "INFO" "Cleaning up temporary staging directory..."
    if [[ -d "$STAGING_DIR" ]]; then
        rm -rf "$STAGING_DIR"
    fi
}
trap cleanup EXIT

# ============================================================
# DEV_EXCLUDES — stripped from Full and Lite, kept in Dev.
# Dev tier: home/ is entirely untouched. Only git/outputs/tmp go.
# ============================================================
DEV_EXCLUDES=(
    "bones/scripts/rc-release.sh"
    "bones/scripts/rc-test.sh"
    "bones/scripts/rc-bump.sh"
    "bones/scripts/rc-book.sh"
    "bones/scripts/rc-dip.sh"
    "bones/scripts/rc-reseed.sh"
    "bones/book-reports"
    "home/obsolete"
    ".github"
    ".shellcheckrc"
    "AGENTS.md"
    "GEMINI.md"
)

# LITE_ADDITIONAL_EXCLUDES — applied on top of DEV_EXCLUDES for Lite only.
LITE_ADDITIONAL_EXCLUDES=(
    "home/content/docs"
    "home/content/help"
    "home/content/rotkeeper"
    "home/assets/images/rotkeeper-splash.png"
    "README.md"
    "CHANGELOG.md"
    "CONTRIBUTING.md"
    "CREDITS.md"
)

# ============================================================
# Helpers
# ============================================================
stage_base() {
    local dest="$1"
    log "INFO" "Staging base project into $(basename "$dest") ..."
    [[ "$DRY_RUN" == true ]] && return
    mkdir -p "$dest"
    rsync -a \
        --exclude='.git' \
        --exclude='output' \
        --exclude='bones/logs' \
        --exclude='bones/tmp' \
        --exclude='bones/releases' \
        --exclude='bones/archive' \
        --exclude='bones/ingested' \
        --exclude='bones/reports' \
        --exclude='messages-from-my-friends' \
        --exclude='home/content/messages' \
        --exclude='.DS_Store' \
        --exclude='.vscode' \
        --exclude='todo.md' \
        --exclude='*_temp.md' \
        "$PROJECT_ROOT/" "$dest/"
}

apply_excludes() {
    local dir="$1"; shift
    local excludes=("$@")
    [[ "$DRY_RUN" == true ]] && { log "DRYRUN" "Would strip ${#excludes[@]} items from $(basename "$dir")"; return; }
    for item in "${excludes[@]}"; do
        local target="$dir/$item"
        if [[ -e "$target" || -d "$target" ]]; then
            rm -rf "$target"
            log "INFO" "  Stripped: $item"
        fi
    done
}

make_zip() {
    local tier_dir="$1"
    local zip_path="$2"
    [[ "$DRY_RUN" == true ]] && { log "DRYRUN" "Would zip $(basename "$tier_dir") -> $(basename "$zip_path")"; return; }
    local orig_dir; orig_dir="$(pwd)"
    cd "$STAGING_DIR"
    rm -f "$zip_path"
    zip -rq "$zip_path" "$(basename "$tier_dir")"
    cd "$orig_dir"
    log "INFO" "  ✅ $(basename "$zip_path") — $(du -sh "$zip_path" | cut -f1)"
}

inject_lite_readme() {
    local lite_dir="$1"
    [[ "$DRY_RUN" == true ]] && return
    cat << 'EOF_README' > "$lite_dir/README.md"
# Welcome to Rotkeeper (Lite Distribution)

This is the lean, runtime-only distribution of Rotkeeper.
No documentation, no dev scripts, no heavy assets.

**Quickstart:**
1. Initialize the workspace: `./rotkeeper.sh init`
2. Create markdown files in `home/content/` with YAML frontmatter.
3. Render your output: `./rotkeeper.sh render`

**Frontmatter required for every content file:**
---
title: "My Page"
slug: my-page
template: rotkeeper-blog.html
---

For full documentation, use the Full or Dev distribution.
EOF_README
}

inject_lite_index() {
    local lite_dir="$1"
    [[ "$DRY_RUN" == true ]] && return
    cat << 'EOF_INDEX' > "$lite_dir/home/content/index.md"
---
title: "Welcome to Rotkeeper (Lite)"
slug: home
template: rotkeeper-blog.html
description: "Rotkeeper CLI landing page for the Lite distribution."
---

# Rotkeeper: A Ritual CLI for Flat-File Decay

Welcome to the Lite distribution of Rotkeeper.

To start rendering tombs, run:
`./rotkeeper.sh render`

*Note: Documentation and sample blogs have been stripped from this lite version.*
EOF_INDEX
}

# ============================================================
# Main
# ============================================================
main() {
    log "INFO" "Starting release packaging for version: $VERSION (tiers: $BUILD_TIER)"
    [[ "$DRY_RUN" == false ]] && mkdir -p "$RELEASE_DIR" "$STAGING_DIR"

    # ── Dev tier — home/ untouched, only git/outputs/tmp excluded ──
    if [[ "$BUILD_TIER" == "all" || "$BUILD_TIER" == "dev" ]]; then
        local DEV_DIR="$STAGING_DIR/rotkeeper-dev"
        local DEV_ZIP="$RELEASE_DIR/rotkeeper-$VERSION-dev.zip"
        log "INFO" "Building dev tier..."
        stage_base "$DEV_DIR"
        make_zip "$DEV_DIR" "$DEV_ZIP"
    fi

    # ── Full tier — dev scripts + book-reports + obsolete stripped, all home/ kept ──
    if [[ "$BUILD_TIER" == "all" || "$BUILD_TIER" == "full" ]]; then
        local FULL_DIR="$STAGING_DIR/rotkeeper-full"
        local FULL_ZIP="$RELEASE_DIR/rotkeeper-$VERSION-full.zip"
        log "INFO" "Building full tier..."
        stage_base "$FULL_DIR"
        apply_excludes "$FULL_DIR" "${DEV_EXCLUDES[@]}"
        make_zip "$FULL_DIR" "$FULL_ZIP"
    fi

    # ── Lite tier — full minus docs dirs and splash image ──
    if [[ "$BUILD_TIER" == "all" || "$BUILD_TIER" == "lite" ]]; then
        local LITE_DIR="$STAGING_DIR/rotkeeper-lite"
        local LITE_ZIP="$RELEASE_DIR/rotkeeper-$VERSION-lite.zip"
        log "INFO" "Building lite tier..."
        if [[ -d "$STAGING_DIR/rotkeeper-full" && "$BUILD_TIER" == "all" ]]; then
            [[ "$DRY_RUN" == false ]] && cp -a "$STAGING_DIR/rotkeeper-full" "$LITE_DIR"
        else
            stage_base "$LITE_DIR"
            apply_excludes "$LITE_DIR" "${DEV_EXCLUDES[@]}"
        fi
        apply_excludes "$LITE_DIR" "${LITE_ADDITIONAL_EXCLUDES[@]}"
        inject_lite_readme "$LITE_DIR"
        inject_lite_index "$LITE_DIR"
        make_zip "$LITE_DIR" "$LITE_ZIP"
    fi

    log "INFO" "All requested tiers packaged in $RELEASE_DIR"
    echo "✅ Release packaging complete — see bones/releases/"
}

main "$@"
```
<!-- END bones/scripts/rc-release.sh::4ad3790b -->

<!-- START bones/scripts/rc-render.sh::4ad3790b -->

```bash
#!/usr/bin/env bash
# ============================================================
#  ██████╗ ███████╗███╗   ██╗██████╗ ███████╗██████╗
#  ██╔══██╗██╔════╝████╗  ██║██╔══██╗██╔════╝██╔══██╗
#  ██████╔╝█████╗  ██╔██╗ ██║██║  ██║█████╗  ██████╔╝
#  ██╔══██╗██╔══╝  ██║╚██╗██║██║  ██║██╔══╝  ██╔══██╗
#  ██║  ██║███████╗██║ ╚████║██████╔╝███████╗██║  ██║
#  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═╝  ╚═╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-render.sh
#  Purpose : Render markdown tombs into HTML using Pandoc and templates
#  Version : 0.4.0.3
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================
show_help() {
  cat << EOF
rc-render.sh — Render Markdown tombs into HTML (v0.3.1.4)

Usage: rc-render.sh [options]

Options:
  --version, -v    Show script version and quit
  --help, -h       Show this help message and exit
  --dry-run        Preview actions without invoking pandoc or archiving
  --verbose        Show detailed logs
EOF
  exit 0
}

source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
VERSION="${ROTKEEPER_VERSION:-0.4.0.3}"

rk_init_script "rc-render" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR CONTENT_DIR DOCS_DIR OUTPUT_DIR
set -euo pipefail
IFS=$'\n\t'




# ---
# main: The primary render ritual. Sweeps through home/content, applies pandoc templates,
# and outputs the final resting HTML forms into output/.
# ---
main() {
    check_dependencies
    log "INFO" "Running rc-render.sh."

    if [[ ! -d "$ROOT_DIR/output" ]] || [[ ! -f "$ROOT_DIR/bones/asset-manifest.yaml" ]]; then
      log "WARN" "Workspace may not be initialized. Run ./rotkeeper.sh init first if assets are missing."
      echo -e "\n⚠️  Warning: Workspace not initialized or missing core assets. Run './rotkeeper.sh init' first to avoid rendering issues.\n" >&2
    fi

    # Initialize page counter and start time
    pages_rendered=0
    start_ts=$(date +%s)

    # Use ROOT_DIR from environment instead of recomputing
    PROJ_ROOT="$ROOT_DIR"

    # --- Paths ---
    CONFIG_FILE="$CONFIG_DIR/rotkeeper.yaml"
    MANIFEST="$BONES_DIR/manifest.txt"
    TEMPLATE_DIR="$TEMPLATE_DIR"

    log "INFO" "CONFIG_FILE=$CONFIG_FILE"
    log "INFO" "MANIFEST=$MANIFEST"
    log "INFO" "TEMPLATE_DIR=$TEMPLATE_DIR"

    # Debug available templates and default
    log "INFO" "Available templates: $(find "$TEMPLATE_DIR" -maxdepth 1 -type f -exec basename {} \; 2>/dev/null | tr '\n' ' ')"

    log_manifest() {
      local entry="$1"
      if [[ -n "$MANIFEST" && -f "$MANIFEST" ]]; then
        if ! grep -Fxq "$entry" "$MANIFEST"; then
          echo "$entry" >> "$MANIFEST"
        fi
      fi
    }

    # Parse config
    if [[ ! -f "$CONFIG_FILE" ]]; then
      echo "❌ Missing config: $CONFIG_FILE"
      exit 1
    fi

     # If no template is set in config, fallback to the first found in the templates directory
    DEFAULT_TEMPLATE=$(yq e '.default_template' "$CONFIG_FILE" 2>/dev/null || echo "")
    if [[ -z "${DEFAULT_TEMPLATE:-}" ]]; then
      # No default_template set; fallback to first template in TEMPLATE_DIR
      choices=()
      for tmpl in "$TEMPLATE_DIR"/*; do
        if [[ -f "$tmpl" ]]; then
          choices+=("$(basename "$tmpl")")
        fi
      done
      if [[ ${#choices[@]} -gt 0 ]]; then
        DEFAULT_TEMPLATE="${choices[0]}"
        log "WARN" "No default_template in config; falling back to first available template: $DEFAULT_TEMPLATE"
      else
        log "ERROR" "No templates found in $TEMPLATE_DIR; cannot proceed"
        exit 1
      fi
    fi
    log "INFO" "DEFAULT_TEMPLATE=$DEFAULT_TEMPLATE"
    log "INFO" "Available templates: $(find "$TEMPLATE_DIR" -maxdepth 1 -type f -exec basename {} \; 2>/dev/null | tr '\n' ' ')"

    # Verify templates directory exists
    if [[ ! -d "$TEMPLATE_DIR" ]]; then
      log "ERROR" "Templates directory not found: $TEMPLATE_DIR"
      exit 1
    fi

    log "MARKER" "📄 Reanimating..."

    # Helper for canonicalization
    get_canonical_path() {
      local path="$1"
      local canonical_path
      canonical_path=$(realpath -m "$path" 2>/dev/null || readlink -f "$path" 2>/dev/null || python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$path" 2>/dev/null)
      if [[ -z "$canonical_path" ]]; then
        echo ""
      else
        echo "$canonical_path"
      fi
    }

    CANONICAL_CONTENT_DIR=$(get_canonical_path "$CONTENT_DIR")
    CANONICAL_META_DIR=$(get_canonical_path "$META_DIR")
    CANONICAL_TEMPLATE_DIR=$(get_canonical_path "$TEMPLATE_DIR")

        # Iterate over all markdown files in CONTENT_DIR
    while IFS= read -r mdfile; do
      [ -f "$mdfile" ] || continue

      [[ "$VERBOSE" == true ]] && log "DEBUG" "Found markdown file: $mdfile"
      base=$(basename "$mdfile" .md)
      canonical_mdpath=$(get_canonical_path "$mdfile")
      if [[ -z "$canonical_mdpath" ]]; then
         log "ERROR" "Failed to resolve canonical path for $mdfile; skipping."
         continue
      fi
      if [[ "$canonical_mdpath" != "$CANONICAL_CONTENT_DIR"* ]]; then
         log "ERROR" "mdpath $canonical_mdpath escaped srcpath $CANONICAL_CONTENT_DIR; skipping."
         continue
      fi
      mdpath="$canonical_mdpath"
      srcpath="$CANONICAL_CONTENT_DIR"

      # Harden relpath: ensure srcpath is a prefix of mdpath
      if [[ "$mdpath" == "$srcpath"* ]]; then
        relpath="${mdpath#"$srcpath"/}"
      else
        log "ERROR" "mdpath $mdpath is not under srcpath $srcpath; skipping."
        continue
      fi

      reldir=$(dirname "$relpath")
      outdir="$OUTPUT_DIR/$reldir"
      if [[ -z "$outdir" || "$outdir" =~ ^[[:space:]]*$ ]]; then
        log "WARN" "Invalid or empty output path for $mdfile — skipping."
        continue
      fi

      run mkdir -p "$outdir"
      outfile="$outdir/${base}.html"
      rel_md="${mdpath#"$PROJ_ROOT"/}"
      rel_out="${outfile#"$PROJ_ROOT"/}"

      log "INFO" "Rendering $rel_md → $rel_out"

      # --- File-Level Sidecar Resolution ---
      # Map: home/content/path/file.md -> bones/meta/path/file.soul.md
      # Path traversal protection guard
      local soul_file="$META_DIR/${relpath%.md}.soul.md"

      local canonical_soul=$(get_canonical_path "$soul_file")
      if [[ -z "$canonical_soul" ]]; then
        log "ERROR" "Failed to resolve canonical path for soul_file $soul_file; skipping."
        continue
      fi
      if [[ "$canonical_soul" != "$CANONICAL_META_DIR"* ]]; then
        log "ERROR" "Path traversal detected in soul file path: $canonical_soul escapes $CANONICAL_META_DIR; skipping."
        continue
      fi
      soul_file="$canonical_soul"
      local pandoc_inputs=()

      # Track active inputs and extract the template target cleanly
      if [[ -f "$soul_file" ]]; then
        log "INFO" "💀 Found spiritual shadow sidecar: $soul_file"
        if ! yq eval '.' "$soul_file" >/dev/null 2>&1; then
          log "WARN" "Malformed YAML frontmatter in sidecar $soul_file. Dropping back to isolated pass."
          pandoc_inputs+=("$mdfile")
          TEMPLATE=$(yq --front-matter extract '.template' "$mdfile" 2>/dev/null | grep -v "^null$" || echo "")
        else
          # Sidecar-Dominance: pass the user document FIRST, sidecar SECOND.
          # Pandoc flattens the AST metadata in-memory, letting the sidecar stomp conflicts.
          pandoc_inputs+=("$mdfile" "$soul_file")

          # Read template from sidecar first; fall back to document if missing
          TEMPLATE=$(yq --front-matter extract '.template' "$soul_file" 2>/dev/null | grep -v "^null$" || echo "")
          [[ -z "$TEMPLATE" ]] && TEMPLATE=$(yq --front-matter extract '.template' "$mdfile" 2>/dev/null | grep -v "^null$" || echo "")
        fi
      else
        # Standard fallback pass
        pandoc_inputs+=("$mdfile")
        TEMPLATE=$(yq --front-matter extract '.template' "$mdfile" 2>/dev/null | grep -v "^null$" || echo "")
      fi

      [[ -z "$TEMPLATE" ]] && TEMPLATE="$DEFAULT_TEMPLATE"
      log "INFO" "Rendering $rel_md with template: $TEMPLATE"


      local template_file="$TEMPLATE_DIR/$TEMPLATE"
      local canonical_template=$(get_canonical_path "$template_file")
      if [[ -z "$canonical_template" ]]; then
        log "ERROR" "Failed to resolve canonical path for template $template_file; skipping."
        continue
      fi
      if [[ "$canonical_template" != "$CANONICAL_TEMPLATE_DIR"* ]]; then
        log "ERROR" "Path traversal detected in template path: $canonical_template escapes $CANONICAL_TEMPLATE_DIR; skipping."
        continue
      fi
      if [ ! -f "$canonical_template" ]; then
        log "ERROR" "Template not found: $canonical_template"
        continue
      fi

      if [[ "$reldir" == "." ]]; then
          ASSETS_ROOT="./assets/"
      else
          depth=$(echo "$reldir" | tr -cd '/' | wc -c)
          ASSETS_ROOT=$(printf '../%.0s' $(seq 1 $((depth + 1))))"assets/"
      fi

      PANDOC_ARGS=""
      if [[ "$DEBUG" == true ]]; then
        PANDOC_ARGS="--trace --dump-args --verbose"
      fi

      # Execute the zero-clutter in-memory aggregation pass
      # shellcheck disable=SC2086
      run pandoc "${pandoc_inputs[@]}"         --from markdown         --to html         --template="$canonical_template"         --variable=assets_root="$ASSETS_ROOT"         --lua-filter="$PROJ_ROOT/bones/scripts/rewrite-links.lua"         -o "$outfile" $PANDOC_ARGS

      pages_rendered=$((pages_rendered + 1))
      log_manifest "$outfile"
    done < <(find "$CONTENT_DIR" -type f -name "*.md" -print)
    log "MARKER" "✓ Exorcism complete."


    # Compute and log summary
    end_ts=$(date +%s)
    duration=$((end_ts - start_ts))
    log "INFO" "Rendered $pages_rendered pages in ${duration}s"

    log "INFO" "rc-render.sh completed successfully."
}

main "$@"
```
<!-- END bones/scripts/rc-render.sh::4ad3790b -->

<!-- START bones/scripts/rc-reseed.sh::4ad3790b -->

```bash
#!/usr/bin/env bash
# ============================================================
#  ██████╗ ███████╗███████╗███████╗███████╗██████╗
#  ██╔══██╗██╔════╝██╔════╝██╔════╝██╔════╝██╔══██╗
#  ██████╔╝█████╗  ███████╗█████╗  █████╗  ██║  ██║
#  ██╔══██╗██╔══╝  ╚════██║██╔══╝  ██╔══╝  ██║  ██║
#  ██║  ██║███████╗███████║███████╗███████╗██████╔╝
#  ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚══════╝╚═════╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-reseed.sh
#  Purpose : Reverse ritual — unbind aggregated markdown back into original files
#  Version : 0.4.0.3
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

set -euo pipefail
IFS=$'\n\t'


show_help() {
  cat <<EOF2
rc-reseed.sh — Reverse ritual for scriptbook/docbook/configbook unbinding

Usage: rc-reseed.sh [--input FILE] [--dry-run] [--all]

Options:
  --version, -v    Show script version and quit
  --input FILE       Path to input file (default: ./rotkeeper-scriptbook-full.md)
  --dry-run          Preview actions without writing files
  --all              Reseed from all known books (scriptbook-full, docbook, configbook)
  --help, -h         Display this message
EOF2
  exit 0
}

source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
VERSION="${ROTKEEPER_VERSION:-0.4.0.3}"

rk_init_script "rc-reseed" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR CONTENT_DIR DOCS_DIR

# Use current directory as root — assume script and inputs live together
ROOT_DIR="$(pwd)"

INPUT=""
# =============================================================================
# rc-reseed.sh — Resurrection from Documentation
#
#   If the scripts are gone, and the tombs are quiet,
#   Let the scriptbook speak, and the docbook riot.
#
#   From bones of markdown, traced and torn,
#   We rebuild what once was born.
#   Echoes parsed from fenced-off code,
#   Stitch the fragments back to road.
#
#   Beware, archivist: this rite rewrites.
#   Ghosts return with sharpened bytes.
# =============================================================================
# Arg parsing
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version|-v) echo "$(basename "$0") v${VERSION:-unknown}"; exit 0 ;;
    --input) INPUT="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --verbose) VERBOSE=true; shift ;;
    --all) INPUT="__ALL__"; shift ;;
    --help|-h) show_help ;;
    --force) FORCE=true; shift ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

if [[ -z "$INPUT" ]]; then
  INPUT="$ROOT_DIR/rotkeeper-scriptbook-full.md"
fi

echo "🔁 Running rc-reseed.sh"

if [[ "$INPUT" == "__ALL__" ]]; then
  DEFAULT_BOOKS=("rotkeeper-scriptbook-full.md" "rotkeeper-docbook.md" "rotkeeper-configbook.md")
else
  DEFAULT_BOOKS=("$INPUT")
fi

for INPUT in "${DEFAULT_BOOKS[@]}"; do
  [[ -f "$INPUT" ]] || { echo "⚠️  Skipping missing input: $INPUT"; continue; }
  echo "📖 Reading from: $INPUT"

  # Pre-scan for duplicates
  declare -A file_counts
  declare -A skip_list
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^\<\!\-\-\ START(:)?\ ([^[:space:]:]+)(::[^[:space:]]+)?\ \-\-\>$ ]]; then
      relpath="${BASH_REMATCH[2]}"
      if [[ -z "${file_counts[$relpath]:-}" ]]; then
        file_counts["$relpath"]=1
      else
        ((file_counts["$relpath"]++))
      fi
    fi
  done < "$INPUT"

  for p in "${!file_counts[@]}"; do
    if (( file_counts["$p"] > 1 )); then
      log "WARN" "Skipping duplicate file in binder: $p (found ${file_counts["$p"]} times)"
      skip_list["$p"]=1
    fi
  done

  # State
  outfile=""
  active_suffix=""
  in_block=false
  in_code_fence=false
  skip_next=0

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$in_block" == false && "$line" =~ ^\<\!\-\-\ START(:)?\ ([^[:space:]:]+)(::[^[:space:]]+)?\ \-\-\>$ ]]; then
      relpath="${BASH_REMATCH[2]}"
      if [[ -n "${skip_list[$relpath]:-}" ]]; then
        continue
      fi
      if [[ -n "${BASH_REMATCH[3]:-}" ]]; then
        active_suffix="${BASH_REMATCH[3]}"
      else
        active_suffix=""
      fi
      relpath="${BASH_REMATCH[2]}"
      outfile="$ROOT_DIR/$relpath"
      mkdir -p "$(dirname "$outfile")"
      if [[ "$DRY_RUN" == false ]]; then
        : > "$outfile"
      fi
      echo "📁 Resurrecting → $relpath"
      in_block=true
      skip_next=0 # Frontmatter processing handled natively now
      continue
    fi

    if [[ "$in_block" == true && "$line" =~ ^\<\!\-\-\ END(:)?\ ([^[:space:]:]+)(::[^[:space:]]+)?\ \-\-\>$ ]]; then
      relpath="${BASH_REMATCH[2]}"
      if [[ "$ROOT_DIR/$relpath" != "$outfile" ]]; then
        continue
      fi
      end_suffix="${BASH_REMATCH[3]:-}"
      if [[ -n "$active_suffix" && "$active_suffix" != "$end_suffix" ]]; then
        log "WARN" "Mismatched END suffix for $relpath. Expected $active_suffix, got $end_suffix. Ignoring."
        continue
      fi
      if [[ "$DRY_RUN" == false && "$outfile" == *".sh" ]]; then
        chmod +x "$outfile" 2>/dev/null || true
      fi
      in_block=false
      continue
    fi

    # Write the earthly code lines back into the resurrected files
    if [[ "$in_block" == true && "$DRY_RUN" == false ]]; then
      echo "$line" >> "$outfile"
    fi
  done < "$INPUT"
done

echo "✅ Reseed complete."

exit 0
```
<!-- END bones/scripts/rc-reseed.sh::4ad3790b -->

<!-- START bones/scripts/rc-scan.sh::4ad3790b -->

```bash
#!/usr/bin/env bash
# ============================================================
#  ███████╗██████╗  █████╗ ███╗   ██╗
#  ██╔════╝██╔══██╗██╔══██╗████╗  ██║
#  ███████╗██║  ██║███████║██╔██╗ ██║
#  ╚════██║██║  ██║██╔══██║██║╚██╗██║
#  ███████║██████╔╝██║  ██║██║ ╚████║
#  ╚══════╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-scan.sh
#  Purpose : Audit files vs manifest, classify orphans, and write digest reports
#  Version : 0.4.0.3
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

set -euo pipefail
# Initialize arrays for manifest and disk entries to avoid unbound variable under set -u
manifest_list=()
disk_list=()
IFS=$'\n\t'


show_help() {
  cat <<EOF
rc-scan.sh — Audit manifest and scan environment for file reports (v0.3.1.4)

Options:
  --version, -v    Show script version and quit

Usage: rc-scan.sh [flags]

Flags:
  --manifest-only   Read only manifest file, skip disk scan.
  --include <ext>   Comma-separated list of extensions to include.
  --exclude <pat>   Glob pattern to exclude (can repeat).
  --dry-run         Show actions without writing reports.
  --verbose         Print detailed logs.
  --json-only       Output only JSON report.
  --md-only         Output only Markdown report.
  -h, --help        Show this help message and exit.
EOF
  exit 0
}

source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
VERSION="${ROTKEEPER_VERSION:-0.4.0.3}"

rk_init_script "rc-scan" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR OUTPUT_DIR

if [ -z "${BASH_VERSION:-}" ]; then
    echo "🚨 rc-scan.sh requires bash. Please run with: bash ./rc-scan.sh" >&2
    exit 1
fi



main() {
    # check_dependencies
    log "INFO" "Running rc-scan.sh."
    # Use plain arrays for manifest and disk lists
    manifest_list=()
    disk_list=()
#
# --- Output Artifacts ---
# rc-scan.sh emits two optional report types (controlled by flags):
#   - JSON Report: bones/reports/scan-report-YYYYMMDD_HHMMSS.json
#   - Markdown Report: bones/reports/scan-report-YYYYMMDD_HHMMSS.md
# Each report includes:
#   - Missing Files: present in manifest but not on disk
#   - Orphan Files: present on disk but not in manifest
#   - File Digests: SHA256 hashes keyed by relative path
#

#
# --- Configuration ---
# Set up default file paths, directories, and file type filters.
# Default configurations
MANIFEST_FILE="bones/manifest.txt"
SCAN_DIRS=("home/" "bones/" "output/")
REPORT_DIR="bones/reports"
LOG_DIR="bones/logs"
INCLUDE_EXT=("png" "jpg" "svg" "css" "js" "md" "html" "json" "yaml")
EXCLUDE_PATTERNS=()

#
# --- CLI Defaults & Argument Parsing ---
# Initialize CLI-related variables and parse command-line flags.
# CLI defaults
JSON_ONLY=false
MD_ONLY=false

#
# Parse input flags and options.
#
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version|-v) echo "$(basename "$0") v${VERSION:-unknown}"; exit 0 ;;
    --manifest-only) MANIFEST_ONLY=true; shift ;;
    --include) IFS=',' read -ra INCLUDE_EXT <<< "$2"; shift 2 ;;
    --exclude) EXCLUDE_PATTERNS+=("$2"); shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --verbose) VERBOSE=true; shift ;;
    --json-only) JSON_ONLY=true; shift ;;
    --md-only) MD_ONLY=true; shift ;;
    -h|--help) show_help ;;
    *) echo "[ERROR] Unknown flag: $1"; show_help ;;
  esac
done

#
# Create necessary report and log directories.
#
mkdir -p "$REPORT_DIR" "$LOG_DIR"

LOG_FILE="$LOG_DIR/rc-scan-$(date +%Y%m%d_%H%M%S).log"

echo "[INFO] rc-scan started at $(date)"

#
# --- Step 1: Load Manifest ---
# Read manifest file entries into a plain array.
if [[ -f "$MANIFEST_FILE" ]]; then
  while read -r line; do
    manifest_list+=("$line")
  done < "$MANIFEST_FILE"
  log "INFO" "Loaded ${#manifest_list[@]} entries from $MANIFEST_FILE"
elif [[ "${MANIFEST_ONLY:-false}" == true ]]; then
  echo "[ERROR] Manifest file not found: $MANIFEST_FILE"; exit 2
fi

#
# --- Step 2: Disk Scan ---
# Walk specified directories, apply include/exclude filters.
if [[ "${MANIFEST_ONLY:-false}" != true ]]; then
  for dir in "${SCAN_DIRS[@]}"; do
    [[ -d "$dir" ]] || continue
    while IFS= read -r file; do
      ext="${file##*.}"
      # check include
      if [[ ! " ${INCLUDE_EXT[*]} " =~ " $ext " ]]; then
        $VERBOSE && echo "[SKIP] Extension filter: $file"
        continue
      fi
      # check exclude
      skip=false
      for pat in "${EXCLUDE_PATTERNS[@]}"; do
        [[ "$file" == $pat ]] && skip=true
      done
      $skip && { $VERBOSE && echo "[SKIP] Excluded by pattern: $file"; continue; }
      disk_list+=("$file")
    done < <(find "$dir" -type f)
  done
  echo "[INFO] Disk scan completed"
fi

#
# --- Step 3: Compare Manifest vs Disk ---
# Determine missing and orphaned files by comparing arrays.
missing=(); orphans=()
for f in "${manifest_list[@]}"; do
  [[ ! -e "$f" ]] && missing+=("$f")
done

# Add fallback for disk_list in case it is unexpectedly unbound
disk_list=("${disk_list[@]:-}")

if [[ ${#disk_list[@]} -eq 0 ]]; then
  log "WARN" "No files found during disk scan; disk_list is empty."
fi

for f in "${disk_list[@]}"; do
  [[ -z "$f" ]] && continue
  rel="${f#./}"
  if ! printf '%s\n' "${manifest_list[@]}" | grep -xq "$rel"; then
    orphans+=("$rel")
  fi
done

#
# --- Step 4: Generate File Metadata ---
# Compute SHA256 checksums for each scanned file.
# Requires bash — file path to SHA256 digest
declare -A file_checksums
for f in "${disk_list[@]}"; do
  f_clean=$(echo "$f" | tr -d '\r' | xargs)
  [[ -z "$f_clean" ]] && continue
  if [[ -f "$f_clean" ]]; then
    sha=$(shasum -a 256 "$f_clean" | awk '{print $1}')
  else
    log "WARN" "File not found for digest: $f_clean"
    sha=""
  fi
  [[ -n "$sha" ]] && file_checksums["$f_clean"]="$sha"
done

#
# --- Step 5: JSON Report ---
# Output findings in JSON format.
# 5. Write JSON report
if [[ "$MD_ONLY" == false ]]; then
  json_report="$REPORT_DIR/scan-report-$(date +%Y%m%d_%H%M%S).json"
  if [[ "$DRY_RUN" != true ]]; then
    cat > "$json_report" <<EOF
{
  "missing": ["$(IFS='","'; echo "${missing[*]}")"],
  "orphans": ["$(IFS='","'; echo "${orphans[*]}")"],
  "digests": {
$(for f in "${!file_checksums[@]}"; do
  echo "    \"${f}\": \"${file_checksums[$f]}\","
done)
  }
}
EOF
    log "INFO" "JSON report written: $json_report"
  else
    log "DRY-RUN" "Would write JSON report to $json_report"
  fi
fi

#
# --- Step 6: Markdown Report ---
# Output findings in Markdown format.
# 6. Write Markdown report
if [[ "$JSON_ONLY" == false ]]; then
  mkdir -p "home/content/rotkeeper"
  md_report="$REPORT_DIR/scan-report-$(date +%Y%m%d_%H%M%S).md"
  if [[ "$DRY_RUN" != true ]]; then
    cat > "$md_report" <<EOF
# Scan Report - $(date)
## Missing Files
$(for f in "${missing[@]}"; do echo "- $f"; done)
## Orphan Files
$(for f in "${orphans[@]}"; do echo "- $f"; done)
## File Digests
$(for f in "${!file_checksums[@]}"; do echo "- \`$f\`: ${file_checksums[$f]}"; done)
EOF
    log "INFO" "Markdown report written: $md_report"
  else
    log "DRY-RUN" "Would write Markdown report to $md_report"
  fi
fi

#
# --- Completion ---
# Final log entry and exit.
#
log "INFO" "rc-scan.sh completed successfully."
echo "[INFO] rc-scan completed at $(date)"
exit 0
}

main "$@"
```
<!-- END bones/scripts/rc-scan.sh::4ad3790b -->

<!-- START bones/scripts/rc-showcase.sh::4ad3790b -->

```bash
#!/usr/bin/env bash
# ============================================================
#  Project : Rotkeeper
#  Script  : rc-showcase.sh
#  Purpose : Auto-scaffolds test pages for all HTML templates
# ============================================================

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/rc-env.sh"
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"

rk_init_script "rc-showcase" "$@"

main() {
  log "INFO" "Initializing Gallery of the Damned showcase scanner..."

  local showcase_dir="$CONTENT_DIR/showcase"
  mkdir -p "$showcase_dir"
  log "INFO" "Ensured showcase directory exists: $showcase_dir"

  if [[ ! -d "$TEMPLATE_DIR" ]]; then
    log "ERROR" "Template directory not found: $TEMPLATE_DIR"
    exit 1
  fi

  local count=0
  for template_file in "$TEMPLATE_DIR"/*.html; do
    if [[ ! -f "$template_file" ]]; then
      continue
    fi

    local template_name=$(basename "$template_file")
    local theme_name="${template_name%.html}"
    theme_name="${theme_name#theme-}"

    local target_file="$showcase_dir/showcase-${theme_name}.md"

    log "INFO" "Scaffolding showcase page for template: $template_name -> $target_file"
    log "INFO" "Auditing template: $(basename "$template_file")"

    mapfile -t found_vars < <(grep -oE '\$[a-zA-Z_]+\$' "$template_file" | tr -d '$' | sort -u)

    local frontmatter="---
title: \"Showcase: $theme_name\"
slug: \"showcase-${theme_name}\"
template: \"$template_name\""

    for var in "${found_vars[@]}"; do
      if [[ "$var" == "title" || "$var" == "slug" || "$var" == "template" || "$var" == "body" || "$var" == "endif" || "$var" == "date" ]]; then
        continue
      fi

      if [[ "$var" == "description" ]]; then
        if (( count % 2 == 0 )); then
          frontmatter+=$'\n'"description: \"Programmatic description for $theme_name\""
        fi
        continue
      fi

      frontmatter+=$'\n'"$var: \"Dummy value for $var\""
    done
    frontmatter+=$'\n'"---"

    echo "$frontmatter" > "$target_file"

    cat << MD_EOF >> "$target_file"

# Heading 1
Through a terminal-driven, proactive embalming approach we can remain tomb-focused and artifact-directed, innovate and be an offline-first necropolis which facilitates static bash-readiness.

## Heading 2
Transforming turnkey phylacteries to dead-code 24/365 paradigms with benchmark archival channels implementing viral bash-rituals and flat-file action-items.

### Heading 3
While we take that action item strictly off-line and raise a fatal \`trap_err\` and remember to touch base as you think about the markdown fences outside of the crypt.

#### Heading 4
And seize B2B (Bash-to-Bone) orchestrators and re-envisioneer necromantic partnerships that evolve zero-hydration initiatives delivering synergistic dead-drops.

##### Heading 5
To incentivize CI/CD deliverables that leverage Pandoc solutions to synergize bash-and-bone dropzones while facilitating one-to-one shell-scripts.

###### Heading 6
With revolutionary Frankenstein stitching that deliver viral payloads and grow decentralized supply-chains that expedite seamless embalming.

---

**Bold Text**: Transform back-end shell dependencies through a terminal-driven, proactive embalming approach we can remain tomb-focused and artifact-directed.

*Italic Text*: Innovate and be an offline-first necropolis which facilitates static bash-readiness transforming turnkey phylacteries to dead-code 24/365 paradigms.

> Blockquote:
> With benchmark archival channels implementing viral bash-rituals and flat-file action-items while we take that action item strictly off-line and raise a fatal \`trap_err\`.
>
> And remember to touch base as you think about the markdown fences outside of the crypt and seize B2B (Bash-to-Bone) orchestrators.

---

### Unordered List
* Re-envisioneer necromantic partnerships
* Evolve zero-hydration initiatives delivering synergistic dead-drops
* Incentivize CI/CD deliverables that leverage Pandoc solutions

### Ordered List
1. Synergize bash-and-bone dropzones
2. Facilitating one-to-one shell-scripts with revolutionary Frankenstein stitching
3. Deliver viral payloads

---

### Code Block
\`\`\`bash
echo "Transforming turnkey phylacteries to dead-code 24/365 paradigms."
echo "With benchmark archival channels implementing viral bash-rituals."
\`\`\`

### Table
| Feature | Status | Impact |
|---|---|---|
| Terminal-driven | Active | Proactive embalming |
| Offline-first | Enabled | Static bash-readiness |
| B2B Orchestrators | Seized | Zero-hydration initiatives |

---

## Stress Testing

### Nested Blockquotes & Fences

> Level 1 blockquote
>
> > Level 2 blockquote
> >
> > \`\`\`bash
> > echo "Nested fence!"
> > \`\`\`
> >
> > > Level 3 blockquote

### Side-by-Side Content Overflows

#### Deeply Nested Lists
* Level 1
  * Level 2
    * Level 3
      * Level 4

#### Massive Technical Table

| Col 1 | Col 2 | Col 3 | Col 4 | Col 5 | Col 6 |
|---|---|---|---|---|---|
| A very long string that might cause overflow | Data | Data | Data | Data | Data |
| Data | A very long string that might cause overflow | Data | Data | Data | Data |

MD_EOF

    if ! pandoc "$target_file" --from markdown --to html --template="$template_file" -o /dev/null >/dev/null 2>&1; then
       log "ERROR" "Template $(basename "$template_file") failed Pandoc validation."
       trap_err $LINENO
    fi

    count=$((count + 1))
  done

  log "INFO" "Showcase generation complete! Generated $count files."
}

main "$@"
```
<!-- END bones/scripts/rc-showcase.sh::4ad3790b -->

<!-- START bones/scripts/rc-status.sh::4ad3790b -->

```bash
#!/usr/bin/env bash
# ============================================================
#  ███████╗████████╗ █████╗ ████████╗██╗   ██╗███████╗
#  ██╔════╝╚══██╔══╝██╔══██╗╚══██╔══╝██║   ██║██╔════╝
#  ███████╗   ██║   ███████║   ██║   ██║   ██║███████╗
#  ╚════██║   ██║   ██╔══██║   ██║   ██║   ██║╚════██║
#  ███████║   ██║   ██║  ██║   ██║   ╚██████╔╝███████║
#  ╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-status.sh
#  Purpose : Output a structured, human-readable status report across environment, health, and pulse.
#  Version : 0.4.0.3
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

source "$(dirname "$0")/rc-utils.sh"

JSON_MODE=false
ARGS=()
for arg in "$@"; do
    if [[ "$arg" == "--json" ]]; then
        JSON_MODE=true
    else
        ARGS+=("$arg")
    fi
done

VERSION="${ROTKEEPER_VERSION:-0.4.0.3}"

rk_init_script "rc-status" "${ARGS[@]}"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR ARCHIVE_DIR
set -euo pipefail
IFS=$'\n\t'

LOG_FILE="$LOG_DIR/rc-status-$(date +%Y-%m-%d_%H%M).log"
mkdir -p "$LOG_DIR"

log() {
  local level="$1"; shift
  printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" | tee -a "$LOG_FILE" >/dev/null
}

log "INFO" "Running rc-status.sh"
check_dependencies

CANONICAL_VERSION=$(grep -E '^VERSION=' "$ROOT_DIR/rotkeeper.sh" | cut -d'"' -f2 || echo "unknown")

# Variables to collect JSON data
JSON_ENV=""
JSON_HEALTH=""
JSON_RAG=""
JSON_RELEASES=""
JSON_TOMBS=""
JSON_PULSE=""
JSON_RENDER=""
JSON_INBOX=""
JSON_CONFIG=""

escape_json() {
  # Trim newlines and escape
  echo -n "$1" | jq -R -s -c . | sed 's/^"//' | sed 's/"$//'
}

# --- Section 1: Environment ---
CWD=$(pwd)
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "[no git]")
    GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "[no git]")
else
    GIT_BRANCH="[no git]"
    GIT_COMMIT="[no git]"
fi

if [[ "$JSON_MODE" == true ]]; then
    GIT_B_JSON="\"$GIT_BRANCH\""
    [[ "$GIT_BRANCH" == "[no git]" ]] && GIT_B_JSON="null"
    GIT_C_JSON="\"$GIT_COMMIT\""
    [[ "$GIT_COMMIT" == "[no git]" ]] && GIT_C_JSON="null"

    JSON_ENV="  \"environment\": {
    \"canonical_version\": \"$CANONICAL_VERSION\",
    \"cwd\": \"$CWD\",
    \"branch\": $GIT_B_JSON,
    \"commit\": $GIT_C_JSON
  }"
else
    echo "=== Environment ==="
    echo "Version  : $CANONICAL_VERSION"
    echo "CWD      : $CWD"
    echo "Branch   : $GIT_BRANCH"
    echo "Commit   : $GIT_COMMIT"
    echo ""
fi

# --- Section 2: Script Health ---
scripts_list=("$BONES_DIR/scripts"/rc-*.sh "$ROOT_DIR/rotkeeper.sh")
total_scripts=0

if [[ "$JSON_MODE" == true ]]; then
    json_scripts="["
else
    echo "=== Script Health ==="
    printf "%-30s | %-10s | %s\n" "Script Name" "Version" "Matches Canonical"
    echo "----------------------------------------------------------------------"
fi

first_script=true
for script in "${scripts_list[@]}"; do
    [[ ! -f "$script" ]] && continue
    total_scripts=$((total_scripts + 1))
    s_name=$(basename "$script")
    s_version=$(grep -E '^VERSION=' "$script" | cut -d'"' -f2 | head -n 1 || echo "unknown")

    match="✗ [DRIFT]"
    match_json="false"
    [[ "$s_version" == "$CANONICAL_VERSION" ]] && match="✓" && match_json="true"

    if [[ "$JSON_MODE" == true ]]; then
        [[ "$first_script" == false ]] && json_scripts+=","
        json_scripts+="
      {
        \"script\": \"$s_name\",
        \"version\": \"$s_version\",
        \"matches_canonical\": $match_json
      }"
        first_script=false
    else
        printf "%-30s | %-10s | %s\n" "$s_name" "$s_version" "$match"
    fi
done

if [[ "$JSON_MODE" == true ]]; then
    json_scripts+="
    ]"
    JSON_HEALTH="  \"script_health\": {
    \"total\": $total_scripts,
    \"scripts\": $json_scripts
  }"
else
    echo "----------------------------------------------------------------------"
    echo "Total Scripts: $total_scripts"
    echo ""
fi


# --- Section 3: RAG Exports (book-reports) ---
if [[ "$JSON_MODE" == true ]]; then
    if [[ ! -d "$BOOK_REPORT_DIR" ]]; then
        JSON_RAG='"rag_exports": {"status": "skipped", "reason": "bones/book-reports/ does not exist"}'
    else
        mapfile -t rag_files < <(find "$BOOK_REPORT_DIR" -maxdepth 1 -type f 2>/dev/null || true)
        if [[ ${#rag_files[@]} -eq 0 ]]; then
            JSON_RAG='"rag_exports": {"status": "empty", "reason": "no book-reports found — run: ./rotkeeper.sh book --all"}'
        else
            json_rag_arr="["
            first_rag=true
            for f in "${rag_files[@]}"; do
                fn=$(basename "$f")
                sz=$(du -h "$f" | cut -f1)
                ch=$(wc -c < "$f")
                tk=$(awk -v c="$ch" 'BEGIN { printf "%.0f", c/4 }')
                pct=$(awk -v t="$tk" 'BEGIN { printf "%.1f", t/1280 }')

                [[ "$first_rag" == false ]] && json_rag_arr+=","
                json_rag_arr+="
          {
            \"filename\": \"$fn\",
            \"size\": \"$sz\",
            \"chars\": $ch,
            \"estimated_tokens\": $tk,
            \"context_pct\": $pct
          }"
                first_rag=false
            done
            json_rag_arr+="
        ]"
            JSON_RAG="\"rag_exports\": {\"status\": \"ok\", \"files\": $json_rag_arr}"
        fi
    fi
else
    echo "=== RAG Exports (book-reports) ==="
    if [[ ! -d "$BOOK_REPORT_DIR" ]]; then
        echo "[SKIP] bones/book-reports/ does not exist"
    else
        mapfile -t rag_files < <(find "$BOOK_REPORT_DIR" -maxdepth 1 -type f 2>/dev/null || true)
        if [[ ${#rag_files[@]} -eq 0 ]]; then
            echo "[EMPTY] no book-reports found — run: ./rotkeeper.sh book --all"
        else
            printf "%-30s | %-10s | %-12s | %s\n" "Filename" "Size" "Chars" "Token Estimate / 128k %"
            echo "--------------------------------------------------------------------------------"
            tot_ch=0
            tot_tk=0
            for f in "${rag_files[@]}"; do
                fn=$(basename "$f")
                sz=$(du -h "$f" | cut -f1)
                ch=$(wc -c < "$f")
                tk=$(awk -v c="$ch" 'BEGIN { printf "%.0f", c/4 }')

                tk_disp=$(awk -v t="$tk" 'BEGIN { if(t>=1000) printf "~%.1fk", t/1000; else printf "~%s", t }')
                pct=$(awk -v t="$tk" 'BEGIN { printf "~%.1f%%", t/1280 }')

                tot_ch=$((tot_ch + ch))
                tot_tk=$((tot_tk + tk))

                if [[ "$VERBOSE" == true ]]; then
                    printf "%-30s | %-10s | %-12s | %s tokens (%s context)\n" "$fn" "$sz" "$ch" "$tk_disp" "$pct"
                fi
            done

            echo "--------------------------------------------------------------------------------"
            tot_sz=$(du -sh "$BOOK_REPORT_DIR" 2>/dev/null | cut -f1 || echo "0")
            tot_tk_disp=$(awk -v t="$tot_tk" 'BEGIN { if(t>=1000) printf "~%.1fk", t/1000; else printf "~%s", t }')
            printf "%-30s | %-10s | %-12s | %s tokens\n" "TOTAL" "$tot_sz" "$tot_ch" "$tot_tk_disp"
        fi
    fi
    echo ""
fi


# --- Section 4: Releases ---
RELEASES_DIR="bones/releases"
if [[ "$JSON_MODE" == true ]]; then
    if [[ ! -d "$RELEASES_DIR" ]]; then
        JSON_RELEASES='"releases": {"status": "skipped", "reason": "bones/releases/ does not exist"}'
    else
        mapfile -t rel_files < <(find "$RELEASES_DIR" -maxdepth 1 -type f -name '*.zip' 2>/dev/null | sort -r || true)
        if [[ ${#rel_files[@]} -eq 0 ]]; then
            JSON_RELEASES='"releases": {"status": "empty", "reason": "no releases — run: ./rotkeeper.sh release VERSION"}'
        else
            json_rel_arr="["
            first_rel=true
            for f in "${rel_files[@]}"; do
                fn=$(basename "$f")
                sz=$(du -h "$f" | cut -f1)
                mod=$(date -r "$f" '+%Y-%m-%d %H:%M:%S')

                [[ "$first_rel" == false ]] && json_rel_arr+=","
                json_rel_arr+="
          {
            \"filename\": \"$fn\",
            \"size\": \"$sz\",
            \"date\": \"$mod\"
          }"
                first_rel=false
            done
            json_rel_arr+="
        ]"
            JSON_RELEASES="\"releases\": {\"status\": \"ok\", \"files\": $json_rel_arr, \"count\": ${#rel_files[@]}}"
        fi
    fi
else
    echo "=== Releases ==="
    if [[ ! -d "$RELEASES_DIR" ]]; then
        echo "[SKIP] bones/releases/ does not exist"
    else
        mapfile -t rel_files < <(find "$RELEASES_DIR" -maxdepth 1 -type f -name '*.zip' 2>/dev/null | sort -r || true)
        if [[ ${#rel_files[@]} -eq 0 ]]; then
            echo "[EMPTY] no releases — run: ./rotkeeper.sh release VERSION"
        else
            if [[ "$VERBOSE" == true ]]; then
                printf "%-30s | %-10s | %s\n" "Filename" "Size" "Date"
                echo "----------------------------------------------------------------------"
                for f in "${rel_files[@]}"; do
                    fn=$(basename "$f")
                    sz=$(du -h "$f" | cut -f1)
                    mod=$(date -r "$f" '+%Y-%m-%d %H:%M:%S')
                    printf "%-30s | %-10s | %s\n" "$fn" "$sz" "$mod"
                done
                echo "----------------------------------------------------------------------"
            fi
            echo "Total Releases: ${#rel_files[@]}"
        fi
    fi
    echo ""
fi


# --- Section 4b: Recent Tombs ---
if [[ "$JSON_MODE" == true ]]; then
    if [[ ! -d "$ARCHIVE_DIR" ]]; then
        JSON_TOMBS='"recent_tombs": {"status": "skipped", "reason": "bones/archive/ does not exist"}'
    else
        mapfile -t tomb_files < <(find "$ARCHIVE_DIR" -maxdepth 1 -type f -name '*.tar.gz' 2>/dev/null | sort -r | head -n 5 || true)
        if [[ ${#tomb_files[@]} -eq 0 ]]; then
            JSON_TOMBS='"recent_tombs": {"status": "empty", "reason": "no archives found — run: ./rotkeeper.sh render"}'
        else
            json_tomb_arr="["
            first_tomb=true
            for f in "${tomb_files[@]}"; do
                fn=$(basename "$f")
                sz=$(du -h "$f" | cut -f1)
                mod=$(date -r "$f" '+%Y-%m-%d %H:%M:%S')

                [[ "$first_tomb" == false ]] && json_tomb_arr+=","
                json_tomb_arr+="
          {
            \"filename\": \"$fn\",
            \"size\": \"$sz\",
            \"date\": \"$mod\"
          }"
                first_tomb=false
            done
            json_tomb_arr+="
        ]"
            JSON_TOMBS="\"recent_tombs\": {\"status\": \"ok\", \"files\": $json_tomb_arr, \"count\": ${#tomb_files[@]}}"
        fi
    fi
else
    echo "=== Recent Tombs ==="
    if [[ ! -d "$ARCHIVE_DIR" ]]; then
        echo "[SKIP] bones/archive/ does not exist"
    else
        mapfile -t tomb_files < <(find "$ARCHIVE_DIR" -maxdepth 1 -type f -name '*.tar.gz' 2>/dev/null | sort -r | head -n 5 || true)
        if [[ ${#tomb_files[@]} -eq 0 ]]; then
            echo "[EMPTY] no archives found — run: ./rotkeeper.sh render"
        else
            printf "%-30s | %-10s | %s\n" "Filename" "Size" "Date"
            echo "----------------------------------------------------------------------"
            for f in "${tomb_files[@]}"; do
                fn=$(basename "$f")
                sz=$(du -h "$f" | cut -f1)
                mod=$(date -r "$f" '+%Y-%m-%d %H:%M:%S')
                printf "%-30s | %-10s | %s\n" "$fn" "$sz" "$mod"
            done
            echo "----------------------------------------------------------------------"
            echo "Total Recent Tombs Shown: ${#tomb_files[@]}"
        fi
    fi
    echo ""
fi


# --- Section 5: Content Pulse ---
if [[ ! -d "$CONTENT_DIR" ]] || [[ -z "$(find "$CONTENT_DIR" -type f -name '*.md' -print -quit 2>/dev/null)" ]]; then
    if [[ "$JSON_MODE" == true ]]; then
        JSON_PULSE="  \"content_pulse\": {
    \"status\": \"empty\",
    \"reason\": \"no content files found in home/content/\",
    \"total_md\": 0,
    \"stubs\": 0,
    \"drafts\": 0,
    \"docs_stubs\": 0
  }"
    else
        echo "=== Content Pulse ==="
        echo "[EMPTY] no content files found in home/content/"
        echo "Total .md files : 0"
        echo "Stubs           : 0"
        echo "Drafts          : 0"
        echo "Docs stubs      : 0"
        echo ""
    fi
else
    mapfile -t c_files < <(find "$CONTENT_DIR" -type f -name '*.md' -print)
    total_md=${#c_files[@]}
    stubs=0
    drafts=0
    if [[ $total_md -gt 0 ]]; then
        stubs=$(grep -l '^status: stub' "${c_files[@]}" 2>/dev/null | wc -l | tr -d ' ' || true)
        drafts=$(grep -l '^status: draft' "${c_files[@]}" 2>/dev/null | wc -l | tr -d ' ' || true)
    fi

    docs_stubs=0
    if [[ -d "$DOCS_DIR" ]]; then
        docs_stubs=$(find "$DOCS_DIR" -type f -name '*.md' -exec grep -l '^status: stub' {} + 2>/dev/null | wc -l | tr -d ' ' || true)
    fi

    if [[ "$JSON_MODE" == true ]]; then
        JSON_PULSE="  \"content_pulse\": {
    \"status\": \"ok\",
    \"total_md\": $total_md,
    \"stubs\": $stubs,
    \"drafts\": $drafts,
    \"docs_stubs\": $docs_stubs
  }"
    else
        echo "=== Content Pulse ==="
        echo "Total .md files : $total_md"
        echo "Stubs           : $stubs"
        echo "Drafts          : $drafts"
        echo "Docs stubs      : $docs_stubs"
        echo ""
    fi
fi

# --- Section 6: Render Freshness ---
NEWEST_HTML=$(find "$OUTPUT_DIR" -type f -name '*.html' -exec stat -c %Y {} + 2>/dev/null | sort -nr | head -n 1 || echo "")
NEWEST_MD=$(find "$CONTENT_DIR" -type f -name '*.md' -exec stat -c %Y {} + 2>/dev/null | sort -nr | head -n 1 || echo "")

status_render="[EMPTY] no rendered output found"
status_json="empty"
if [[ -n "$NEWEST_HTML" ]]; then
    if [[ -n "$NEWEST_MD" ]] && [[ "$NEWEST_MD" -gt "$NEWEST_HTML" ]]; then
        status_render="[STALE] content has changed since last render"
        status_json="stale"
    else
        status_render="[OK] output is current"
        status_json="ok"
    fi
fi

if [[ "$JSON_MODE" == true ]]; then
    JSON_RENDER="  \"render_freshness\": {
    \"status\": \"$status_json\",
    \"message\": \"$status_render\"
  }"
else
    echo "=== Render Freshness ==="
    echo "$status_render"
    echo ""
fi


# --- Section 7: Inbox ---
INBOX_DIR="messages-from-my-friends"
if [[ ! -d "$INBOX_DIR" ]]; then
    if [[ "$JSON_MODE" == true ]]; then
        JSON_INBOX='"inbox": {"status": "skipped", "reason": "messages-from-my-friends/ does not exist"}'
    else
        echo "=== Inbox ==="
        echo "[SKIP] messages-from-my-friends/ does not exist"
        echo ""
    fi
else
    inbox_count=$(find "$INBOX_DIR" -maxdepth 1 -type f -name '*.tar.gz' | wc -l | tr -d ' ' || echo 0)
    if [[ "$inbox_count" -eq 0 ]]; then
        inbox_msg="[OK] inbox empty"
        inbox_status="ok"
    else
        inbox_msg="[WAITING] $inbox_count payload(s) pending — run: ./rotkeeper.sh ingest"
        inbox_status="waiting"
    fi
    if [[ "$JSON_MODE" == true ]]; then
        JSON_INBOX="  \"inbox\": {
    \"status\": \"$inbox_status\",
    \"count\": $inbox_count,
    \"message\": \"$inbox_msg\"
  }"
    else
        echo "=== Inbox ==="
        echo "$inbox_msg"
        echo ""
    fi
fi

# --- Section 8: Config Summary ---
CONFIG_FILE="$CONFIG_DIR/rotkeeper.yaml"
if [[ ! -f "$CONFIG_FILE" ]]; then
    if [[ "$JSON_MODE" == true ]]; then
        JSON_CONFIG='"config_summary": {"status": "skipped", "reason": "bones/config/rotkeeper.yaml does not exist"}'
    else
        echo "=== Config Summary ==="
        echo "[SKIP] bones/config/rotkeeper.yaml does not exist"
        echo ""
    fi
else
    conf_project=$(yq eval '.project // "[not set]"' "$CONFIG_FILE" 2>/dev/null | tr -d '\n' || echo "[not set]")
    conf_author=$(yq eval '.author // "[not set]"' "$CONFIG_FILE" 2>/dev/null | tr -d '\n' || echo "[not set]")
    conf_version=$(yq eval '.version // "[not set]"' "$CONFIG_FILE" 2>/dev/null | tr -d '\n' || echo "[not set]")
    conf_default_template=$(yq eval '.default_template // "[not set]"' "$CONFIG_FILE" 2>/dev/null | tr -d '\n' || echo "[not set]")
    conf_license=$(yq eval '.license // "[not set]"' "$CONFIG_FILE" 2>/dev/null | tr -d '\n' || echo "[not set]")

    if [[ "$JSON_MODE" == true ]]; then
        conf_project_j=$(escape_json "$conf_project")
        conf_author_j=$(escape_json "$conf_author")
        conf_version_j=$(escape_json "$conf_version")
        conf_default_template_j=$(escape_json "$conf_default_template")
        conf_license_j=$(escape_json "$conf_license")

        JSON_CONFIG="  \"config_summary\": {
    \"status\": \"ok\",
    \"project\": \"$conf_project_j\",
    \"author\": \"$conf_author_j\",
    \"version\": \"$conf_version_j\",
    \"default_template\": \"$conf_default_template_j\",
    \"license\": \"$conf_license_j\"
  }"
    else
        echo "=== Config Summary ==="
        echo "Project          : $conf_project"
        echo "Author           : $conf_author"
        echo "Version          : $conf_version"
        echo "Default Template : $conf_default_template"
        echo "License          : $conf_license"
        echo "# Config is minimal — additional fields will appear here as rotkeeper.yaml expands."
        echo ""
    fi
fi

if [[ "$JSON_MODE" == true ]]; then
    echo "{"
    echo "$JSON_ENV,"
    echo "$JSON_HEALTH,"
    echo "$JSON_RAG,"
    echo "$JSON_RELEASES,"
    echo "  $JSON_TOMBS,"
    echo "$JSON_PULSE,"
    echo "$JSON_RENDER,"
    echo "$JSON_INBOX,"
    echo "$JSON_CONFIG"
    echo "}"
fi

log "INFO" "rc-status.sh completed"
```
<!-- END bones/scripts/rc-status.sh::4ad3790b -->

<!-- START bones/scripts/rc-sync-inbox.sh::4ad3790b -->

```bash
#!/usr/bin/env bash
# ============================================================
#  Project : Rotkeeper
#  Script  : rc-sync-inbox.sh
#  Purpose : Inbox Autopilot - automates AI documentation ingestion loop
# ============================================================

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPTDIR}/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }

# shellcheck disable=SC2329
show_help() {
  cat <<EOF
rc-sync-inbox.sh — Inbox Autopilot
Automates the AI documentation ingestion loop: scan → ingest → dip → render

Usage: rc-sync-inbox.sh [options]
Options:
  --dry-run     Preview phases without executing
  --verbose     Show detailed logs
  --help, -h    Show this message
  --version, -v Show version
EOF
  exit 0
}

VERSION="${ROTKEEPER_VERSION:-0.4.0.3}"
rk_init_script "rc-sync-inbox" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONTENT_DIR LOG_DIR
set -euo pipefail
IFS=$'\n\t'

log "INFO" "Phase 1: Scanning drop zone..."
INBOX_DIR="$ROOT_DIR/messages-from-my-friends"

# Scan for payloads
shopt -s nullglob
archives=("$INBOX_DIR"/*.tar.gz)
shopt -u nullglob

if [[ ${#archives[@]} -eq 0 ]]; then
    log "INFO" "No pending payloads found in $INBOX_DIR. Exiting gracefully."
    exit 0
fi

log "INFO" "Found ${#archives[@]} payload(s)."

log "INFO" "Phase 2: Unpack & Ingest..."
if [[ "$DRY_RUN" != true ]]; then
    if ! "$ROOT_DIR/rotkeeper.sh" ingest; then
        log "ERROR" "Ingest ritual failed."
        exit 1
    fi
fi

log "INFO" "Phase 3: Stitch the Docs (Auto-DIP)..."
if [[ "$DRY_RUN" != true ]]; then
    if ! "$ROOT_DIR/rotkeeper.sh" dip; then
        log "ERROR" "DIP ritual failed."
        exit 1
    fi
fi

log "INFO" "Phase 4: Publish the HTML..."
if [[ "$DRY_RUN" != true ]]; then
    if ! "$ROOT_DIR/rotkeeper.sh" render; then
        log "ERROR" "Render ritual failed."
        exit 1
    fi
fi

log "INFO" "Inbox Autopilot completed successfully!"
exit 0
```
<!-- END bones/scripts/rc-sync-inbox.sh::4ad3790b -->

<!-- START bones/scripts/rc-test.sh::4ad3790b -->

```bash
#!/usr/bin/env bash
# ============================================================
#  Project : Rotkeeper
#  Script  : rc-test.sh
#  Purpose : Multi-Pass Layout Integration Test Matrix
#  Version : 0.4.0.3
# ============================================================

set -euo pipefail
IFS=$'\n\t'

if [[ "${1:-}" == "--dry-run" ]]; then exit 0; fi

echo "--- Rotkeeper Multi-Pass Layout Matrix Test Suite ---"

TEST_DIR="/tmp/rotkeeper-test-env"
# shellcheck disable=SC2329
cleanup() {
  echo "Pruning testing footprints from the physical realm..."
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT INT TERM ERR

# Establish sandbox footprint
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

# Matrix Configuration Array
LAYOUT_MODES=("crypt" "busy" "sterile")

for mode in "${LAYOUT_MODES[@]}"; do
  echo "======================================================================"
  echo "🔬 EXECUTING VALIDATION PASS: [Layout Mode: $mode]"
  echo "======================================================================"

  # 1. Provision Fresh Sandbox Layout Architecture
  pass_dir="$TEST_DIR/$mode"
  mkdir -p "$pass_dir/bones/scripts"
  mkdir -p "$pass_dir/bones/config"
  mkdir -p "$pass_dir/bones/templates"

  # Copy foundational codebases
  cp rotkeeper.sh "$pass_dir/"
  cp bones/scripts/rc-*.sh "$pass_dir/bones/scripts/"
  cp bones/scripts/rewrite-links.lua "$pass_dir/bones/scripts/"
  cp bones/templates/*.html "$pass_dir/bones/templates/"

  # Inject target layout setting into our active configuration profile
  cat << CONF_EOF > "$pass_dir/bones/config/rotkeeper.yaml"
project: "Test Tomb"
author: "Test Necromancer"
default_template: "theme-light.html"
layout_style: "$mode"
CONF_EOF

  # Setup targeted sub-directories natively based on active pass context
  case "$mode" in
    "busy")
      mv "$pass_dir/bones/templates" "$pass_dir/templates"
      mkdir -p "$pass_dir/assets/css"
      mkdir -p "$pass_dir/home/content"
      cp home/assets/css/*.css "$pass_dir/assets/css/"
      ;;
    "sterile")
      mkdir -p "$pass_dir/config"
      mv "$pass_dir/bones/templates" "$pass_dir/config/templates"
      mkdir -p "$pass_dir/src/assets/css"
      mkdir -p "$pass_dir/src/content"
      cp home/assets/css/*.css "$pass_dir/src/assets/css/"
      ;;
    "crypt")
      mkdir -p "$pass_dir/home/assets/css"
      mkdir -p "$pass_dir/home/content"
      cp home/assets/css/*.css "$pass_dir/home/assets/css/"
      ;;
  esac

  # 2. Enter target workspace boundary and execute lifecycle loops
  (
    cd "$pass_dir"
    export ROT_SKIP_ENV=false # Enforce fresh boots

    echo "  [+] Initializing environment..."
    ./rotkeeper.sh init --with-sample > /dev/null

    # Assert structural content scaffolding placement matches criteria
    case "$mode" in
      "busy")    [ -f "home/content/test-file.md" ] || exit 40 ;;
      "sterile") [ -f "src/content/test-file.md" ] || exit 41 ;;
      "crypt")   [ -f "home/content/test-file.md" ] || exit 42 ;;
    esac

    echo "  [+] Testing 'new' scaffold ritual..."
    ./rotkeeper.sh new "custom-page" > /dev/null

    echo "  [+] Testing path traversal hardening..."
    local_content_dir="home/content"
    if [[ "$mode" == "sterile" ]]; then
      local_content_dir="src/content"
    fi
    cat << 'MALICIOUS_EOF' > "$local_content_dir/malicious-file.md"
---
template: ../../../../../etc/passwd
---
This file should not be rendered successfully.
MALICIOUS_EOF
    ./rotkeeper.sh render > /dev/null

    # Assert that no HTML was generated for malicious file
    if [[ "$mode" == "sterile" ]]; then
      if [[ -f "dist/malicious-file.html" ]]; then
        echo "❌ Path traversal failed: malicious-file.html was generated."
        exit 60
      fi
    else
      if [[ -f "output/malicious-file.html" ]]; then
        echo "❌ Path traversal failed: malicious-file.html was generated."
        exit 60
      fi
    fi

    # Verify ERROR log was created
    if ! grep -q "Path traversal detected in template path" bones/logs/rc-render-*.log; then
      echo "❌ Path traversal failed: No ERROR log found."
      exit 61
    fi
    rm "$local_content_dir/malicious-file.md"

    echo "  [+] Compiling and running Pandoc Forge passes..."
    ./rotkeeper.sh render > /dev/null

    # Validate output targets match criteria
    case "$mode" in
      "busy")    [ -f "output/custom-page.html" ] || exit 50 ;;
      "sterile") [ -f "dist/custom-page.html" ] || exit 51 ;;
      "crypt")   [ -f "output/custom-page.html" ] || exit 52 ;;
    esac

    echo "  [+] Auditing asset mapping constraints..."
    ./rotkeeper.sh assets > /dev/null
    [ -f "bones/asset-manifest.yaml" ] || exit 53

    echo "  [+] Running validation audit tools..."
    ./rotkeeper.sh book --fsbook > /dev/null
    ./rotkeeper.sh autopsy --all > /dev/null
    ./rotkeeper.sh dip > /dev/null

    echo "  [+] Verifying workspace status summaries..."
    ./rotkeeper.sh status --json > /dev/null

    echo "  🎉 Pass [$mode] successful and structurally coherent."
  )
done

echo "======================================================================"
echo "✅ ALL LAYOUT MATRIX PASSES COMPLETED WITHOUT ENTROPY PROLIFERATION."
echo "======================================================================"
exit 0
```
<!-- END bones/scripts/rc-test.sh::4ad3790b -->

<!-- START bones/scripts/rc-utils.sh::4ad3790b -->

```bash
#!/usr/bin/env bash
# ============================================================
#  ██╗   ██╗████████╗██╗██╗     ███████╗
#  ██║   ██║╚══██╔══╝██║██║     ██╔════╝
#  ██║   ██║   ██║   ██║██║     ███████╗
#  ██║   ██║   ██║   ██║██║     ╚════██║
#  ╚██████╔╝   ██║   ██║███████╗███████║
#   ╚═════╝    ╚═╝   ╚═╝╚══════╝╚══════╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-utils.sh
#  Purpose : Shared Rotkeeper helper functions and runtime sanity wrappers
#  Version : 0.4.0.3
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

set -euo pipefail
IFS=$'\n\t'


# --- Global Flags ---
DRY_RUN=false
VERBOSE=false
QUIET=true
DEBUG=false
HELP=false

# Parse common flags: --dry-run, --verbose, --help
# ---
# parse_flags: Interprets the whispered command-line flags (--dry-run, --verbose, --help)
# Inputs: $@ (all arguments)
# Outputs: Modifies global DRY_RUN, VERBOSE, HELP flags
# ---
# Interprets the whispered command-line flags (--dry-run, --verbose, --help)
parse_flags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --version|-v) echo "$(basename "$0") v${VERSION:-unknown}"; exit 0 ;;
      --dry-run)   DRY_RUN=true; shift ;;
      --verbose)   VERBOSE=true; QUIET=false; shift ;;
      --quiet)     QUIET=true; shift ;;
      --debug)     DEBUG=true; VERBOSE=true; QUIET=false; shift ;;
      --help|-h)   HELP=true; shift ;;
      *) break ;;
    esac
  done
}

# Default help handler (can be overridden by scripts)
# ---
# show_help: Displays the eternal void (default help text) if a script has no manual
# ---
# Displays the eternal void (default help text) if a script has no manual
if ! declare -f show_help > /dev/null; then
  show_help() {
    log "INFO" "No help available for this command."
    exit 0
  }
fi

# Logging function: prints timestamped messages and writes to $LOG_FILE if set
# ---
# log: Writes timestamped missives to the console and to the sacred $LOG_FILE
# Inputs: $1 (Level: INFO, ERROR, WARN), $2+ (Message)
# ---
log() {
  local level="$1"; shift
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  local msg="[$ts] [$level] $*"

  # Three-tier verbosity filter for standard stdout
  if [[ "$level" == "MARKER" ]]; then
    echo "$*" >&3
  elif [[ "$QUIET" == true && ( "$level" == "INFO" || "$level" == "DEBUG" || "$level" == "WARN" || "$level" == "DRY-RUN" ) ]]; then
    : # Skip stdout
  elif [[ "$level" == "DEBUG" && "$DEBUG" != true ]]; then
    : # Skip stdout
  else
    echo "$msg"
  fi

  # Always write standard logs to file if present
  if [[ -n "${LOG_FILE:-}" ]]; then
    if [[ "$level" == "MARKER" ]]; then
      echo "[$ts] [MARKER] $*" >> "$LOG_FILE"
    else
      echo "$msg" >> "$LOG_FILE"
    fi
  fi
}

# Runner: dry-run and verbose wrapper for commands
run() {
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log "DRY-RUN" "$*"
  else
    [[ "$VERBOSE" == true ]] && log "INFO" "$*"
    command "$@"
  fi
}

# Require explicitly listed command-line tools (use in main scripts)
# ---
# require_bins: Checks if the required earthly binaries exist in the PATH
# Inputs: $@ (List of binary names like 'pandoc' or 'jq')
# Outputs: Exits with code 2 if a tool is missing
# ---
# Checks if the required earthly binaries exist in the PATH
require_bins() {
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      log "ERROR" "Missing required dependency: $cmd"
      exit 2
    fi
  done
}

# Check all core binary dependencies used by Rotkeeper scripts
check_dependencies() {
  require_bins bash pandoc sha256sum
  require_yq_version
  require_gawk_version
}

# Require yq version 4.x or higher (Go-based CLI)
require_yq_version() {
  if ! yq eval '.foo' <<< 'foo: bar' >/dev/null 2>&1; then
    log "ERROR" "yq version 4.x required. Install from https://github.com/mikefarah/yq"
    exit 2
  fi
}

# Require GNU awk (gawk) instead of macOS/BSD awk
require_gawk_version() {
  if ! awk --version 2>&1 | grep -qi 'GNU Awk'; then
    log "ERROR" "GNU Awk required. Install it via: brew install gawk"
    exit 2
  fi
}

validate_config_syntax() {
  if ! yq eval '.' "$CONFIG_DIR/rotkeeper.yaml" >/dev/null 2>&1; then
    log "FATAL" "YAML configuration is malformed"
    exit 1
  fi
}

# Error trap: report error line and exit
trap_err() {
  log "ERROR" "Error on line ${1:-unknown}"
  exit 2
}

# Cleanup hook: override in scripts to perform teardown
cleanup() {
  :
}

# ---
# set_traps: Binds the err and exit hooks to ensure graceful demise upon failure
# ---
# Binds the err and exit hooks to ensure graceful demise upon failure
set_traps() {
  trap 'trap_err $LINENO' ERR
  trap 'cleanup' EXIT INT TERM
}

# Load rc-env.sh from script root
source_rc_env() {
  local ENV_FILE="$(dirname "${BASH_SOURCE[0]:-$0}")/rc-env.sh"
  if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
  else
    log "WARN" "rc-env.sh not found at $ENV_FILE"
  fi
}

# Initialize log file with script name
init_log() {
  local name="${1:-$(basename "$0" .sh)}"
  LOG_FILE="bones/logs/${name}-$(date +%Y-%m-%d_%H%M).log"
  mkdir -p "$(dirname "$LOG_FILE")"
}

# Standardize script initialization: sets name, logs, traps, and parses common flags
VERSION="${ROTKEEPER_VERSION:-0.4.0.3}"

rk_init_script() {
  SCRIPTNAME="${1:-$(basename "$0" .sh)}"
  shift

  : "${DRY_RUN:=${RK_DRY:-false}}"
  : "${VERBOSE:=${RK_VERBOSE:-false}}"
  : "${QUIET:=${RK_QUIET:-true}}"
  : "${DEBUG:=${RK_DEBUG:-false}}"
  : "${HELP:=false}"

  parse_flags "$@"
  if [[ "$HELP" == true ]]; then
    show_help
    exit 0
  fi

  init_log "$SCRIPTNAME"
  set_traps
  validate_config_syntax

  # Save original stdout to fd 3 for MARKER bypass
  exec 3>&1

  # Redirect output to log file as well
  if [[ "$QUIET" == true ]]; then
    exec > "$LOG_FILE" 2>&1
  else
    if (exec > >(true) 2>/dev/null); then
      exec > >(tee -a "$LOG_FILE") 2>&1
    else
      exec >> "$LOG_FILE" 2>&1
    fi
  fi

  # If debug is enabled, dump env and turn on tracing
  if [[ "$DEBUG" == true ]]; then
    env
    set -x
  fi
}

get_base_no_ext() {
    local file="$1"
    local dir_part="."
    if [[ "$file" == */* ]]; then
        dir_part="${file%/*}"
    fi
    local file_part="${file##*/}"
    local base_name
    if [[ "$file_part" =~ ^\.[^.]+\. ]]; then
        base_name="${file_part%.*}"
    elif [[ "$file_part" =~ ^\.[^.]+$ ]]; then
        base_name="$file_part"
    else
        base_name="${file_part%.*}"
    fi
    if [ "$dir_part" = "." ]; then
        echo "$base_name"
    else
        echo "${dir_part}/${base_name}"
    fi
}

get_sidecar_path() {
    local target="$1"
    local base_no_ext
    base_no_ext=$(get_base_no_ext "$target")

    # If it's a directory, point to path.soul.md, else file.soul.md
    if [[ -d "$ROOT_DIR/$target" ]]; then
        echo "${META_DIR}/${target}.soul.md"
    else
        echo "${META_DIR}/${base_no_ext}.soul.md"
    fi
}

read_meta_sidecar_body() {
    local target_file="$1"
    local sidecar
    sidecar=$(get_sidecar_path "$target_file")
    if [[ -f "$sidecar" ]]; then
        sed "1{/^---$/!q;}; 1,/^---$/d" "$sidecar"
    fi
}

# Return script directory
resolve_script_dir() {
  cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

# Check if file has YAML frontmatter
has_frontmatter() {
  local file="$1"
  grep -q '^---' "$file"
}

# Extract value from YAML frontmatter key (primitive)
get_yaml_key() {
  local key="$1"
  local file="$2"
  awk -v k="$key" '$0 ~ "^"k":" {print $2; exit}' "$file"
}

# List markdown files in a directory
list_md_files() {
  find "$1" -type f -name '*.md'
}

# Require env vars to be set
require_env_vars() {
  for var in "$@"; do
    if [[ -z "${!var:-}" ]]; then
      log "ERROR" "Required env var not set: $var"
      exit 1
    fi
  done
}

# Auto-load environment unless explicitly skipped
: "${ROT_SKIP_ENV:=false}"
if [[ "$ROT_SKIP_ENV" != true ]]; then
  source_rc_env
fi

# Run main only if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main() {
        # placeholder main logic for rc-utils.sh
        :
    }
    main "$@"
fi
```
<!-- END bones/scripts/rc-utils.sh::4ad3790b -->

<!-- START rotkeeper.sh::4ad3790b -->

```bash
#!/usr/bin/env bash
# ============================================================
#  ██████╗  ██████╗ ████████╗██╗  ██╗███████╗███████╗██████╗
#  ██╔══██╗██╔═══██╗╚══██╔══╝██║ ██╔╝██╔════╝██╔════╝██╔══██╗
#  ██████╔╝██║   ██║   ██║   █████╔╝ █████╗  █████╗  ██████╔╝
#  ██╔══██╗██║   ██║   ██║   ██╔═██╗ ██╔══╝  ██╔══╝  ██╔═══╝
#  ██║  ██║╚██████╔╝   ██║   ██║  ██╗███████╗███████╗██║
#  ╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rotkeeper.sh
#  Purpose : CLI dispatcher for all Rotkeeper rituals
#  Version : 0.4.0.3
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

set -euo pipefail
IFS=$'\n\t'

VERSION="0.4.0.3"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BONES="$SCRIPT_DIR/bones/scripts"

trap 'echo "Unexpected error on line $LINENO"; exit 1' ERR

command="${1:-}"
if [[ $# -gt 0 ]]; then shift; fi

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------

show_help() {
  cat <<EOF
rotkeeper.sh — Rotkeeper CLI v$VERSION

Usage:
  rotkeeper.sh <command> [options]

Quickstart:
  ./rotkeeper.sh init
  ./rotkeeper.sh new my-first-page
  ./rotkeeper.sh render
  ./rotkeeper.sh pack --content

Commands:
  showcase    Generate markdown showcase files for all available HTML templates
  init        Initialize environment (minimal by default)
                --with-sample    Generate sample file
                --with-render    Run the render ritual
                --full           Full initialization (reseed, sample, assets, render, scan)
                --force          Force rebuild of all files

  new <file>  Scaffold a new markdown file with required YAML frontmatter

  render      Convert all markdown files (from home/content/) into HTML tombs (in output/)
              Note: This builds the entire site at once; target files cannot be specified.
              (This also creates a timestamped backup archive in bones/archive/)

  pack        Archive rendered HTML into a versioned tarball with embedded JSON metadata
              (Use pack to create shareable tomb releases; render just creates backups)

  autopsy     Dissect scripts and map outputs

  release     Package the project into 'lite' and 'full' distribution zip files

  smoke       Alias for 'test' — Run the integration test harness

  scan        Verify manifest entries against actual files

  assets      Generate asset manifest (home/assets → bones/asset-manifest.yaml)

  glue        Auto-generate index.md navigation glue for unindexed content directories

  templates   List all available HTML templates in the bones/templates/ directory

  ingest      Unpack and safely merge .tar.gz payloads from messages-from-my-friends/

  sync-inbox  Automate the AI documentation ingestion loop (scan, ingest, dip, render)

  dip         Audit documentation coverage, stub missing files, and whisk obsolete docs.

  book        Generate documentation outputs
                --scriptbook-full   Generate rotkeeper-scriptbook-full.md
                --docbook           Generate rotkeeper-docbook.md
                --docbook-clean     Generate collapse-friendly docbook variant
                --configbook        Generate rotkeeper-configbook.md
                --fsbook            Generate rotkeeper-files.md catalog
                --collapse          Convert reports into collapsed-content.yaml
                --all               Run all binding rituals

  cleanup     Backup and prune bones/ archives and logs
                --days N   Set retention window in days (default: 30)

  reseed      Unpack a .tar.gz archive or resurrect from a bound markdown file
                <archive>        Use a .tar.gz archive
                --input FILE     Use a scriptbook/docbook/configbook

  status      Display latest render/log/archive/git state summary
                --json     Output as minified JSON for agent consumption

  agent-handoff Generate books and package a tombkit for AI delegates

  snapshot    Instantly run render, pack, and scan to freeze the current state

  test        Run the integration test harness against the rotkeeper scripts

  bump        Log a micro-update, bump the version, and commit changes

  help        Show this help message

  --version, -v
              Display version and exit

Examples:
  rotkeeper.sh init --force
  rotkeeper.sh render
  rotkeeper.sh book --all
  rotkeeper.sh cleanup --days 14

Note: The 'bones/' directory is an internal system directory. Do not edit it unless you are familiar with Rotkeeper's internals.
EOF
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------

case "$command" in
  showcase)
    echo "Generating showcase files..."
    bash "$BONES/rc-showcase.sh" "$@"
    ;;


  --version|-v)
    echo "rotkeeper v$VERSION"
    ;;

  --help|-h|help|"")
    show_help
    ;;

  init)
    echo "Starting full initialization..."
    bash "$BONES/rc-init.sh" --force "$@"
    ;;

  new)
    echo "Scaffolding new file..."
    bash "$BONES/rc-new.sh" "$@"
    ;;

  render)
    echo "Rendering tombs..."
    bash "$BONES/rc-render.sh" "$@"
    ;;

  pack)
    echo "Packaging output..."
    bash "$BONES/rc-pack.sh" "$@"
    ;;

  release)
    echo "Creating release distributions..."
    bash "$BONES/rc-release.sh" "$VERSION" "$@"
    ;;

  smoke)
    echo "Running smoke test..."
    bash "$BONES/rc-test.sh" "$@" || true
    ;;

  scan)
    echo "Scanning manifest integrity..."
    bash "$BONES/rc-scan.sh" "$@"
    ;;

  assets)
    echo "Generating asset manifest..."
    bash "$BONES/rc-assets.sh" "$@"
    ;;

  glue)
    echo "Applying navigation glue to unindexed directories..."
    bash "$BONES/rc-glue.sh" "$@"
    ;;

  ingest)
    echo "Ingesting new messages..."
    bash "$BONES/rc-ingest.sh" "$@"
    ;;

  sync-inbox)
    echo "Running Inbox Autopilot..."
    bash "$BONES/rc-sync-inbox.sh" "$@"
    ;;

  dip)
    echo "Running Document Improvement Project (DIP) audit..."
    bash "$BONES/rc-dip.sh" "$@"
    ;;

  templates)
    echo "🎨 Available Templates:"
    echo "   (Declare your chosen template in your markdown YAML frontmatter)"
    echo "   Example:"
    echo "   ---"
    echo "   template: rotkeeper-blog.html"
    echo "   ---"
    echo ""
    if [[ -d "$SCRIPT_DIR/bones/templates" ]]; then
      for t in "$SCRIPT_DIR/bones/templates"/*.html; do
        [[ -f "$t" ]] && echo "   - $(basename "$t")"
      done
    else
      echo "   No templates found."
    fi
    ;;

  book)
    echo "Binding documentation reports..."
    bash "$BONES/rc-book.sh" "$@"
    ;;

  cleanup)
    echo "Cleaning up bones/..."
    bash "$BONES/rc-cleanup-bones.sh" "$@"
    ;;

  reseed)
    if [[ $# -eq 0 ]]; then
      echo "Missing argument. Usage:"
      echo "  rotkeeper.sh reseed <archive.tar.gz>"
      echo "  rotkeeper.sh reseed --input FILE"
      exit 1
    fi
    echo "Reseeding from archive..."
    bash "$BONES/rc-reseed.sh" "$@"
    ;;

  status)
    bash "$BONES/rc-status.sh" "$@"
    ;;

  bump)
    echo "Logging microupdate and bumping version..."
    bash "$BONES/rc-bump.sh" "$@"
    ;;

  test)
    echo "Running Rotkeeper test harness..."
    bash "$BONES/rc-test.sh" "$@" || true
    ;;

  agent-handoff)
    echo "Initiating Agent Handoff..."
    bash "$BONES/rc-book.sh" --all
    bash "$BONES/rc-pack.sh" --self
    echo ""
    echo "Tombkit generated. Hand the latest tombkit-*.tar.gz from bones/archive/ to the agent."
    ;;

  snapshot)
    echo "Creating a point-in-time snapshot..."
    bash "$BONES/rc-render.sh" "$@"
    bash "$BONES/rc-pack.sh" "$@"
    bash "$BONES/rc-scan.sh" "$@"
    echo "Snapshot complete."
    ;;

  autopsy)
    echo "Running autopsy audit..."
    bash "$BONES/rc-autopsy.sh" "$@"
    ;;

  *)
    echo "Unknown command: $command"
    echo ""
    show_help
    exit 1
    ;;

esac
```
<!-- END rotkeeper.sh::4ad3790b -->
