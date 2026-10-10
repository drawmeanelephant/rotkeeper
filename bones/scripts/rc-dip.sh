#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# ============================================================
#  ██████╗ ██╗██████╗
#  ██╔══██╗██║██╔══██╗
#  ██║  ██║██║██████╔╝
#  ██║  ██║██║██╔═══╝
#  ██████╔╝██║██║
#  ╚═════╝ ╚═╝╚═╝
# ============================================================
# Env assumptions: reads ARCHIVE_DIR, ASSETS_DIR, BONES_DIR, BOOK_REPORT_DIR, CONFIG_DIR, CONTENT_DIR, DEBUG, DOCS_DIR, DRY_RUN, HELP_DIR, LOG_DIR, META_DIR, OUTPUT_DIR, QUIET, REPORT_DIR, ROOT_DIR, SCRIPT_DIR, TEMPLATE_DIR, TMP_DIR, WEB_DIR (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.
# CWD assumptions: No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.
# Input/Output contracts: reads the fsbook core inventory, script headers/static help/side-effect annotations, sidecars, CHANGELOG, documentation ownership, dip-whitelist.txt, and git commit dates. Generates a missing catalog on demand; a degraded inventory cannot authorize obsolete moves.
#   Rebuilds missing or explicitly owned script references under `DOCS_DIR` with the command-reference v1 contract. Authored task guides are not replaced. Non-command mirrors retain authored prose while Notes/History and marker-owned runtime sections are migrated.
#   Refreshes the opt-in command-index block in `DOCS_DIR/index.md` from dispatcher help and script mappings. Reports explicitly authored guides in docs/help separately, including review dates and placeholders.
#   Obsolete moves require explicit target_file evidence and honor bare whitelist paths; exempt: target | reason entries suppress stubs and stitching. Publishes `DOCS_DIR/dip-matrix.md`; `--json` retains `rotkeeper.dip-matrix.v1` with additive section, placeholder, sidecar coverage/orphan, exemption, and staleness fields. Dry-run previews doc/matrix mutations; shared bootstrap logging still writes.
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-dip.sh
#  Purpose : Document Improvement Project - audits and fixes docs
#  Version : 0.5.1
#  Updated : 2026-07-15
# ------------------------------------------------------------
#  DIP state model (generated vs authored vs stub vs stale vs obsolete):
#  - generated : per-file reference doc under DOCS_DIR mirroring a core
#                path, with target_file frontmatter and DIP markers
#  - authored  : handwritten conceptual docs (whitelist / no target_file
#                ownership); never auto-moved
#  - stub      : doc has a placeholder, empty/missing required section, or status stub
#  - stale     : target git commit date newer than doc or sidecar commit date;
#                unknown in shallow repositories or without path history
#  - exempt    : explicit target exception; no reference page or sidecar required
#  - orphaned  : sidecar has no DIP, content-directory glue, or content-page consumer
#  - obsolete  : generated reference whose target_file is no longer a core
#                file — moved only with strong evidence (explicit target_file)
#  - unowned   : present under DOCS_DIR with uncertain ownership; reported,
#                never silently discarded
# ============================================================


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }

# @HELP
# rc-dip.sh — Document Improvement Project audit
#
# Usage:
#   rotkeeper.sh dip [options]
#
# Description:
#   Reports required-section state and TODO:/Not found: placeholders,
#   including Notes, plus sidecar coverage and unreachable sidecars.
#   Staleness uses git commit dates, never checkout times; shallow or
#   missing history is unknown. Missing help input is reported as degraded
#   (command references read static script help directly).
#   Bare dip-whitelist.txt paths protect docs from obsolete moves;
#   exempt: <core path> | <reason> skips reference generation and coverage.
#   Moves obsolete docs only with explicit ownership evidence.
#   Refreshes the marked command index from dispatcher source. Pages with
#   doc_type: guide and no target_file are preserved and reported separately.
#
# Options:
#   --dry-run      Preview actions without moving or writing docs
#   --verbose      Detailed output
#   --quiet        Suppress informational output
#   --json         Emit a machine-readable DIP matrix JSON on stdout
#   --help, -h     Show help
#   --version, -v  Show version and quit
#
# Examples:
#   bash rotkeeper.sh dip --dry-run     # Audit without moving or writing docs
#   bash rotkeeper.sh dip               # Full audit and matrix publication
#   bash rotkeeper.sh dip --json | jq . # Machine-readable matrix output
#
# Exit codes:
#   0         Audit completed (findings live in the matrix report)
#   nonzero   Audit could not complete
# @END-HELP

# --json is extracted before shared bootstrap because parse_flags stops at the
# first unknown flag; everything else passes through to it untouched.
JSON_MODE=false
DIP_ARGS=()
for _arg in "$@"; do
  if [[ "$_arg" == "--json" ]]; then
    JSON_MODE=true
  else
    DIP_ARGS+=("$_arg")
  fi
done

rk_init_script rc-dip ${DIP_ARGS[@]+"${DIP_ARGS[@]}"}
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR CONTENT_DIR DOCS_DIR REPORT_DIR BOOK_REPORT_DIR META_DIR

# Surface dry-run actions even when QUIET defaults true
if [[ "${DRY_RUN:-false}" == true ]]; then
  QUIET=false
fi

OBSOLETE_DIR="$(dirname "${CONTENT_DIR:-${ROOT_DIR}/home/content}")/obsolete/docs"
MATRIX_FILE="${DOCS_DIR}/dip-matrix.md"
DATE_STR=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
DEGRADED_AUTOPSY=false
DEGRADED_FSBOOK=false
DEGRADED_HELP=false
[[ -f "$REPORT_DIR/autopsy-help.md" ]] || DEGRADED_HELP=true

GIT_HISTORY="unavailable"
# git rev-parse emits a Windows-style path (C:/...) on MSYS while
# rk_canonical_path yields POSIX form (/c/...); canonicalize both sides so the
# toplevel comparison is platform-portable.
_dip_git_top=$(git -C "$ROOT_DIR" rev-parse --show-toplevel 2>/dev/null || true)
_dip_git_top=$(rk_canonical_path "$_dip_git_top" 2>/dev/null || true)
if [[ -n "$_dip_git_top" && "$_dip_git_top" == "$(rk_canonical_path "$ROOT_DIR")" ]]; then
  if [[ "$(git -C "$ROOT_DIR" rev-parse --is-shallow-repository 2>/dev/null || true)" == false ]]; then
    GIT_HISTORY="complete"
  else
    GIT_HISTORY="shallow"
  fi
fi
declare -A GIT_EDIT_TIMES=() GIT_EDIT_DATES=()

# --- helpers ---------------------------------------------------------------

# Cache committed dates only. Unknown history must never fall back to mtime.
record_git_edit() {
  local file="$1" edit
  [[ -z "${GIT_EDIT_DATES[$file]:-}" ]] || return 0
  GIT_EDIT_TIMES["$file"]=""
  GIT_EDIT_DATES["$file"]="unknown"
  if [[ ! -f "$file" ]]; then
    GIT_EDIT_DATES["$file"]="Missing"
  elif [[ "$GIT_HISTORY" == complete ]]; then
    edit=$(git -C "$ROOT_DIR" log -1 --format='%ct %cs' -- "${file#"$ROOT_DIR"/}" 2>/dev/null || true)
    if [[ "$edit" =~ ^([0-9]+)[[:space:]]+([0-9]{4}-[0-9]{2}-[0-9]{2})$ ]]; then
      GIT_EDIT_TIMES["$file"]="${BASH_REMATCH[1]}"
      GIT_EDIT_DATES["$file"]="${BASH_REMATCH[2]}"
    fi
  fi
}

git_staleness() {
  local target="$1" source="$2"
  if [[ -z "${GIT_EDIT_TIMES[$target]:-}" || -z "${GIT_EDIT_TIMES[$source]:-}" ]]; then
    echo unknown
  elif (( GIT_EDIT_TIMES[$target] > GIT_EDIT_TIMES[$source] )); then
    echo stale
  else
    echo current
  fi
}

# Path-prefix match with component boundary (excl is exact or parent of path).
path_is_under() {
  local path="$1"
  local prefix="$2"
  [[ -n "$prefix" ]] || return 1
  [[ "$path" == "$prefix" || "$path" == "$prefix"/* ]]
}

# True if candidate is strictly under root (no .. escape after join).
path_stays_under() {
  local root="$1"
  local candidate="$2"
  local root_abs cand_abs
  # Reject absolute or parent-traversal relatives before joining
  if [[ "$candidate" == /* || "/$candidate/" == */../* ]]; then
    return 1
  fi
  root_abs=$(rk_canonical_path "$root") || return 1
  cand_abs=$(rk_canonical_path "$root/$candidate") || return 1
  [[ "$cand_abs" == "$root_abs" || "$cand_abs" == "$root_abs"/* ]]
}

# Atomic write from stdin → dest (temp sibling, then mv).
# SIDE EFFECT (write): creates the destination directory, writes <dest>.tmp.$$, then
# replaces <dest> atomically via mv; removes the temp file on write failure.
atomic_write() {
  local dest="$1"
  local dir tmp
  dir=$(dirname -- "$dest")
  mkdir -p "$dir" || {
    log "ERROR" "Cannot create directory for atomic write: $dir"
    return 1
  }
  tmp="${dest}.tmp.$$"
  cat >"$tmp" || {
    rm -f "$tmp"
    return 1
  }
  mv -f "$tmp" "$dest"
}

# Extract target_file frontmatter value (quoted or bare).
read_target_file() {
  rk_frontmatter_field "target_file" "$1"
}

# Extract status frontmatter value.
read_status_field() {
  rk_frontmatter_field "status" "$1"
}

# Count placeholder lines throughout the body, including lists, quotes, and
# Notes. Fenced examples, YAML, and HTML comments are not unfinished prose.
count_todo_lines() {
  local doc="$1"
  rk_strip_frontmatter "$doc" | awk '
    /^[[:space:]]*(```|~~~)/ { fence=!fence; next }
    fence { next }
    /<!--/ { comment=1 }
    comment { if (/-->/) comment=0; next }
    /TODO:|Not found:/ { c++ }
    END { print c+0 }
  '
}

# Required sections are the command-reference v1 contract, or the five
# non-command reference pillars. Keep legacy heading aliases readable.
section_states() {
  local doc="$1" command="$2"
  { if [[ -f "$doc" ]]; then rk_strip_frontmatter "$doc"; fi; } | awk -v command="$command" '
    BEGIN {
      n=split(command == "true" \
        ? "overview usage options examples exit_codes reads_and_writes side_effects notes history" \
        : "overview usage reads_and_writes notes history", keys, " ")
    }
    /^[[:space:]]*(```|~~~)/ { fence=!fence; next }
    !fence && /<!--/ { comment=1 }
    comment { if (/-->/) comment=0; next }
    !fence && /^##[[:space:]]+|^######[[:space:]]+CLI Usage/ {
      heading=$0; sub(/^#+[[:space:]]+/, "", heading)
      key=""
      if (heading == "Overview") key="overview"
      if (heading == "Usage" || heading == "CLI Usage") key="usage"
      if (heading == "Options") key="options"
      if (heading == "Examples") key="examples"
      if (heading == "Exit codes") key="exit_codes"
      if (heading == "Reads and writes" || heading == "Environment") key="reads_and_writes"
      if (heading == "Side effects") key="side_effects"
      if (heading == "Notes" || heading ~ /^Necromancer/) key="notes"
      if (heading == "History" || heading == "Ritual History") key="history"
      # Sidecar bodies can contain their own H2s within Notes.
      if (key != "") { section=key; seen[key]=1; next }
      if (section != "notes") section=""
    }
    section != "" && /[^[:space:]]/ {
      if (!fence && /^#+[[:space:]]/) next
      content[section]++
      if (!fence && /TODO:|Not found:/) placeholders[section]++
      if (!fence && ($0 ~ /^No sidecar notes are documented for `/ \
          || $0 ~ /^Not documented in the script help block[.]/ \
          || $0 ~ /Purpose is not documented in the script header[.]/ \
          || $0 ~ /Not documented in the script header[.]/ \
          || $0 ~ /^No side effects are documented in script annotations[.]/ \
          || $0 ~ /^CHANGELOG[.]md is unavailable[.]/)) absent[section]=1
    }
    END {
      for (i=1; i<=n; i++) {
        key=keys[i]
        state=!seen[key] ? "missing" : placeholders[key] ? "placeholder" \
          : absent[key] ? "missing" : content[key] ? "populated" : "empty"
        printf "%s\t%s\t%d\n", key, state, placeholders[key]+0
      }
    }
  '
}

# True if line is a DIP pillar section boundary (not generic ## — soul bodies use those).
is_dip_section_header_line() {
  [[ "$1" =~ ^##[[:space:]]+Environment([[:space:]]|$) ]] \
    || [[ "$1" =~ ^##[[:space:]]+Ritual[[:space:]]+History ]] \
    || [[ "$1" =~ ^##[[:space:]]+Necromancer ]] \
    || [[ "$1" =~ ^##[[:space:]]+(Notes|History)([[:space:]]|$) ]] \
    || [[ "$1" =~ ^##[[:space:]]+(Usage|Reads[[:space:]]and[[:space:]]writes)([[:space:]]|$) ]] \
    || [[ "$1" =~ ^######[[:space:]]+CLI[[:space:]]+Usage ]] \
    || [[ "$1" =~ ^##[[:space:]]+Overview([[:space:]]|$) ]]
}

# Extract body currently stitched under a DIP marker until the next pillar boundary.
extract_marker_body() {
  local doc="$1"
  local marker="$2"
  awk -v marker="$marker" '
    BEGIN { grab=0; n=0 }
    $0 ~ ("<!-- " marker ":") {
      if (grab) exit
      grab=1
      next
    }
    grab {
      # Marker lines, rather than headings alone, are the authoritative
      # boundary.  Authored prose may legitimately contain "## Environment".
      if ($0 ~ /^<!-- DIP-[A-Z0-9-]+-EXTRACTED:/) exit
      body[++n]=$0
    }
    END {
      # A canonical section heading immediately before the next marker is
      # structural scaffolding, not part of the previous pillar body.
      while (n > 0 && body[n] ~ /^[[:space:]]*$/) n--
      if (n > 0 && (body[n] ~ /^##[[:space:]]+Environment([[:space:]]|$)/ \
          || body[n] ~ /^##[[:space:]]+Ritual[[:space:]]+History/ \
          || body[n] ~ /^##[[:space:]]+Necromancer/ \
          || body[n] ~ /^##[[:space:]]+(Notes|History)([[:space:]]|$)/ \
          || body[n] ~ /^##[[:space:]]+(Usage|Reads[[:space:]]and[[:space:]]writes)([[:space:]]|$)/ \
          || body[n] ~ /^######[[:space:]]+CLI[[:space:]]+Usage/ \
          || body[n] ~ /^##[[:space:]]+Overview([[:space:]]|$)/)) n--
      while (n > 0 && body[n] ~ /^[[:space:]]*$/) n--
      for (i=1; i<=n; i++) print body[i]
    }
  ' "$doc"
}

# Normalize whitespace for content comparison (trim trailing space / blank edges).
normalize_body() {
  printf '%s\n' "$1" | sed -e 's/[[:space:]]*$//' | awk '
    { buf[NR]=$0; last=NR }
    END {
      start=0
      for (i=1; i<=last; i++) if (buf[i] ~ /[^[:space:]]/) { start=i; break }
      end=0
      for (i=last; i>=1; i--) if (buf[i] ~ /[^[:space:]]/) { end=i; break }
      if (start==0) exit
      for (i=start; i<=end; i++) print buf[i]
    }
  '
}

# ---
# marker_section_regex: Map pillar marker to its heading regex.
# Inputs: $1 (marker name)
# Outputs: Prints regex for that pillar
# Env: Reads BONES_DIR, DRY_RUN, QUIET, ROOT_DIR, VERBOSE (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
# Map marker name → its section header pattern (for duplicate-section collapse).
marker_section_regex() {
  case "$1" in
    DIP-ENV-EXTRACTED) echo '^##[[:space:]]+(Reads[[:space:]]and[[:space:]]writes|Environment)([[:space:]]|$)' ;;
    DIP-HELP-EXTRACTED) echo '^(##[[:space:]]+Usage([[:space:]]|$)|######[[:space:]]+CLI[[:space:]]+Usage)' ;;
    DIP-HISTORY-EXTRACTED) echo '^##[[:space:]]+(History([[:space:]]|$)|Ritual[[:space:]]+History)' ;;
    DIP-SOUL-EXTRACTED) echo '^##[[:space:]]+(Notes([[:space:]]|$)|Necromancer)' ;;
    *) echo '^$' ;;
  esac
}

# ---
# stitch_pillar: Idempotently rewrite a DIP marker block when body changes.
# Inputs: $1 (doc path), $2 (marker), $3 (new content)
# Outputs: Rewrites doc file via 40-line awk state machine; honors DRY_RUN
# Env: Reads DRY_RUN (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
# Idempotent pillar stitch: rewrite marker block only when content changes
# (or when duplicate markers/sections need collapsing).
stitch_pillar() {
  local doc_path="$1"
  local marker="$2"
  local new_content="$3"

  if [[ ! -f "$doc_path" ]]; then
    return 0
  fi
  if ! grep -q "<!-- ${marker}:" "$doc_path"; then
    return 0
  fi

  local old_body old_norm new_norm marker_count
  old_body=$(extract_marker_body "$doc_path" "$marker" || true)
  old_norm=$(normalize_body "$old_body")
  new_norm=$(normalize_body "$new_content")
  marker_count=$(grep -c "<!-- ${marker}:" "$doc_path" || true)

  if [[ "$old_norm" == "$new_norm" && "$marker_count" -eq 1 ]]; then
    return 0
  fi

  if [[ "${DRY_RUN:-false}" == true ]]; then
    log "DRY-RUN" "Would stitch pillar $marker in $doc_path"
    return 0
  fi

  local tmp_file="${doc_path}.tmp.$$"
  local content_file="${doc_path}.dipcontent.$$"
  local section_re
  section_re=$(marker_section_regex "$marker")
  # Preserve exact body bytes (avoid env size / newline stripping issues)
  printf '%s\n' "$new_content" >"$content_file"
  export DATE_STR
  export MARKER="$marker"
  export SECTION_RE="$section_re"
  export CONTENT_FILE="$content_file"

  # State machine: is_header identifies pillar headings; real_boundary confirms heading+marker pair
  # is the authoritative section boundary; process_line streams input collapsing duplicates and stitching new body.
  awk '
    # is_header: true if line is a DIP pillar heading (Environment/History/Necromancer/CLI/Overview)
    function is_header(line) {
      return line ~ /^##[[:space:]]+Environment([[:space:]]|$)/ \
          || line ~ /^##[[:space:]]+Ritual[[:space:]]+History/ \
          || line ~ /^##[[:space:]]+Necromancer/ \
          || line ~ /^##[[:space:]]+(Notes|History)([[:space:]]|$)/ \
          || line ~ /^##[[:space:]]+(Usage|Reads[[:space:]]and[[:space:]]writes)([[:space:]]|$)/ \
          || line ~ /^######[[:space:]]+CLI[[:space:]]+Usage/ \
          || line ~ /^##[[:space:]]+Overview([[:space:]]|$)/
    }
    # real_boundary: true only when heading is immediately followed by a DIP marker (authored ## Environment alone is not a boundary)
    function real_boundary(i, j) {
      if (!is_header(lines[i])) return 0
      j=i+1
      while (j<=count && lines[j] ~ /^[[:space:]]*$/) j++
      return j<=count && lines[j] ~ /^<!-- DIP-[A-Z0-9-]+-EXTRACTED:/
    }
    # process_line: stream one buffered line handling skip/emit for duplicate collapse and marker replacement
    function process_line(i, line, marker_line, foreign_marker) {
      line=lines[i]
      marker_line=(line ~ ("<!-- " ENVIRON["MARKER"] ":"))
      foreign_marker=(line ~ /^<!-- DIP-[A-Z0-9-]+-EXTRACTED:/ && !marker_line)
      if (skip) {
        if (marker_line) return
        if (real_boundary(i) || foreign_marker) skip=0
        else return
      }
      if (marker_line) {
        if (emitted) { skip=1; return }
        print "<!-- " ENVIRON["MARKER"] ": " ENVIRON["DATE_STR"] " -->"
        print ""
        while ((getline cline < ENVIRON["CONTENT_FILE"]) > 0) print cline
        close(ENVIRON["CONTENT_FILE"])
        emitted=1; skip=1; return
      }
      print line
    }
    BEGIN {
      count=0
      while ((getline line < ARGV[1]) > 0) lines[++count]=line
      close(ARGV[1])
      skip=0; emitted=0
      section_re=ENVIRON["SECTION_RE"]
      for (i=1; i<=count; i++) process_line(i)
      exit
    }
  ' "$doc_path" >"$tmp_file"
  # SIDE EFFECT (delete+write): drops the extracted-content scratch file and replaces the
  # stitched doc in place with the rewritten temp file
  rm -f "$content_file"
  mv -f "$tmp_file" "$doc_path"
}

# ---
# expected_doc_for_core: Map a core file path to its expected doc under DOCS_DIR.
# Inputs: $1 (core-relative path)
# Outputs: Prints expected doc path
# Env: Reads ARCHIVE_DIR, ASSETS_DIR, BOOK_REPORT_DIR, CONTENT_DIR, DOCS_DIR, OUTPUT_DIR ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
expected_doc_for_core() {
  local file="$1"
  local base_no_ext
  base_no_ext=$(get_base_no_ext "$file")
  if [[ "$base_no_ext" == "$file" ]]; then
    echo "${DOCS_DIR}/${file}.md"
  else
    echo "${DOCS_DIR}/${base_no_ext}.md"
  fi
}

declare -A WHITELIST=() EXEMPT_TARGETS=()
WHITELIST_FILE="$CONFIG_DIR/dip-whitelist.txt"
if [[ -f "$WHITELIST_FILE" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    line=$(printf '%s\n' "$line" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')
    [[ -z "$line" || "$line" == \#* ]] && continue
    if [[ "$line" == exempt:* ]]; then
      entry="${line#exempt:}"
      target="${entry%%|*}"
      reason="${entry#*|}"
      target=$(printf '%s\n' "$target" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')
      reason=$(printf '%s\n' "$reason" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')
      if [[ "$entry" != *"|"* || -z "$target" || -z "$reason" ]] \
        || ! path_stays_under "$ROOT_DIR" "$target"; then
        log "WARN" "Ignoring invalid target exemption: $line"
        continue
      fi
      EXEMPT_TARGETS["$target"]="$reason"
    else
      WHITELIST["$ROOT_DIR/$line"]=1
    fi
  done <"$WHITELIST_FILE"
fi

log "INFO" "Starting Document Improvement Project audit..."

# --- 1. File discovery -----------------------------------------------------

AUTOPSY_REPORT="$REPORT_DIR/autopsy-outputs.md"
FSBOOK_CATALOG="$BOOK_REPORT_DIR/rotkeeper-files.md"

declare -A AUTOPSY_EXCLUDES=()

if [[ -f "$AUTOPSY_REPORT" ]]; then
  log "INFO" "Reading autopsy outputs report for artifact exclusions..."
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^\|[[:space:]]+[0-9] ]] || continue
    path_col=$(printf '%s\n' "$line" | awk -F'|' '{print $4}' | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//;s/`//g')
    path_col=$(printf '%s\n' "$path_col" | awk '{print $1}')

    if [[ "$path_col" =~ \(unresolved: ]]; then
      if [[ "$path_col" =~ ^([^[:space:]]+)/\((unresolved:) ]]; then
        known_dir="${BASH_REMATCH[1]}"
        if [[ -n "$known_dir" && ! "$known_dir" =~ ^- ]]; then
          AUTOPSY_EXCLUDES["$known_dir"]=1
        fi
      fi
      continue
    fi

    [[ -z "$path_col" || "$path_col" == "-" ]] && continue
    # Exact artifact path only — do NOT promote first path component
    # (that excluded entire trees like "bones/" incorrectly).
    AUTOPSY_EXCLUDES["$path_col"]=1
    dir_path=$(dirname -- "$path_col")
    if [[ "$dir_path" != "." && ! "$dir_path" =~ ^- && ${#dir_path} -ge 2 ]]; then
      # Only exclude leaf artifact parent dirs under known output-like roots
      case "$dir_path" in
        output|output/*|tmp|tmp/*|bones/tmp|bones/tmp/*|bones/logs|bones/logs/*|bones/reports|bones/reports/*|bones/archive|bones/archive/*|bones/book-reports|bones/book-reports/*|bones/releases|bones/releases/*)
          AUTOPSY_EXCLUDES["$dir_path"]=1
          ;;
      esac
    fi
  done <"$AUTOPSY_REPORT"
else
  DEGRADED_AUTOPSY=true
  log "WARN" "Autopsy report missing at $AUTOPSY_REPORT — artifact exclusion degraded. Run: ./rotkeeper.sh autopsy --all"
fi

# Hard excludes: never treat as core sources for per-file docs
AUTOPSY_EXCLUDES[".git"]=1
AUTOPSY_EXCLUDES[".github"]=1
AUTOPSY_EXCLUDES[".vscode"]=1
AUTOPSY_EXCLUDES[".idea"]=1
if [[ -n "${CONTENT_DIR:-}" ]]; then
  AUTOPSY_EXCLUDES["${CONTENT_DIR#"$ROOT_DIR"/}"]=1
fi
if [[ -n "${ASSETS_DIR:-}" ]]; then
  AUTOPSY_EXCLUDES["${ASSETS_DIR#"$ROOT_DIR"/}"]=1
fi
if [[ -n "${OUTPUT_DIR:-}" ]]; then
  AUTOPSY_EXCLUDES["${OUTPUT_DIR#"$ROOT_DIR"/}"]=1
fi
if [[ -n "${ARCHIVE_DIR:-}" ]]; then
  AUTOPSY_EXCLUDES["${ARCHIVE_DIR#"$ROOT_DIR"/}"]=1
  AUTOPSY_EXCLUDES["${ARCHIVE_DIR#"$ROOT_DIR"/}/releases"]=1
fi
if [[ -n "${TMP_DIR:-}" ]]; then
  AUTOPSY_EXCLUDES["${TMP_DIR#"$ROOT_DIR"/}"]=1
fi
if [[ -n "${LOG_DIR:-}" ]]; then
  AUTOPSY_EXCLUDES["${LOG_DIR#"$ROOT_DIR"/}"]=1
fi
if [[ -n "${REPORT_DIR:-}" ]]; then
  AUTOPSY_EXCLUDES["${REPORT_DIR#"$ROOT_DIR"/}"]=1
fi
if [[ -n "${BOOK_REPORT_DIR:-}" ]]; then
  AUTOPSY_EXCLUDES["${BOOK_REPORT_DIR#"$ROOT_DIR"/}"]=1
fi
if [[ -n "${META_DIR:-}" ]]; then
  AUTOPSY_EXCLUDES["${META_DIR#"$ROOT_DIR"/}"]=1
fi

declare -a BLESSED_PATHS=()
BLESSED_FILE="$ROOT_DIR/.blessed"
if [[ -f "$BLESSED_FILE" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    line=$(printf '%s\n' "$line" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')
    [[ -z "$line" ]] && continue
    # Only treat path-like blessed entries as paths (skip bare version tags)
    if [[ "$line" == */* || "$line" == .* || "$line" == *.* || -e "$ROOT_DIR/$line" ]]; then
      BLESSED_PATHS+=("$line")
      AUTOPSY_EXCLUDES["$line"]=1
    else
      log "DEBUG" "Ignoring non-path .blessed entry: $line"
    fi
  done <"$BLESSED_FILE"
fi

# ---
# is_excluded_core_path: Check if path falls under autopsy excludes.
# Inputs: $1 (relative file path)
# Outputs: Returns 0 if excluded, 1 otherwise
# Env: Reads DRY_RUN, SCRIPT_DIR (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
is_excluded_core_path() {
  local file_path="$1"
  local excl
  for excl in "${!AUTOPSY_EXCLUDES[@]}"; do
    if path_is_under "$file_path" "$excl"; then
      return 0
    fi
  done
  return 1
}

# --- 2. Discover core files from fsbook catalog ----------------------------

CORE_FILES=()
declare -A CORE_FILE_SET=()

if [[ ! -f "$FSBOOK_CATALOG" ]]; then
  log "WARN" "FSBook catalog not found at $FSBOOK_CATALOG. Attempting one-shot generation via rc-book --fsbook..."
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log "DRY-RUN" "Would generate fsbook catalog at $FSBOOK_CATALOG"
  else
    bash "$SCRIPT_DIR/rc-book.sh" --fsbook || log "WARN" "rc-book --fsbook failed"
  fi
fi

if [[ -f "$FSBOOK_CATALOG" ]]; then
  log "INFO" "Reading fsbook catalog for file discovery..."
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^-[[:space:]]+(.*)$ ]]; then
      file_path="${BASH_REMATCH[1]}"
      file_path=$(printf '%s\n' "$file_path" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')
      file_path="${file_path#./}"
      [[ -z "$file_path" ]] && continue

      if is_excluded_core_path "$file_path"; then
        continue
      fi

      # Skip non-source artifacts by extension
      if [[ "$file_path" =~ \.(png|css|jpg|jpeg|gif|svg|ico|woff2?|ttf|map|DS_Store|db)$ ]]; then
        continue
      fi
      # Skip markdown/textile/cooklang tombs themselves (docs are outputs of DIP, not cores)
      if [[ "$file_path" =~ \.(md|textile|cook)$ ]]; then
        continue
      fi

      CORE_FILES+=("$file_path")
      CORE_FILE_SET["$file_path"]=1
    fi
  done <"$FSBOOK_CATALOG"
else
  DEGRADED_FSBOOK=true
  log "WARN" "FSBook catalog still missing — core discovery skipped. Run: ./rotkeeper.sh book --fsbook. Audit will not move/stub based on incomplete inventory."
fi

# Explicit exemptions remain visible even in excluded trees such as .vscode.
# They cannot authorize obsolete moves or generation in a degraded inventory.
for file in "${!EXEMPT_TARGETS[@]}"; do
  if [[ -f "$ROOT_DIR/$file" && -z "${CORE_FILE_SET[$file]:-}" ]]; then
    CORE_FILES+=("$file")
    CORE_FILE_SET["$file"]=1
  fi
done

# Ownership map: expected doc path → core relative path
declare -A EXPECTED_DOCS=()
declare -a OWNERSHIP_COLLISIONS=()

for file in ${CORE_FILES[@]+"${CORE_FILES[@]}"}; do
  doc_path=$(expected_doc_for_core "$file")
  if [[ -n "${EXPECTED_DOCS[$doc_path]:-}" && "${EXPECTED_DOCS[$doc_path]}" != "$file" ]]; then
    prev="${EXPECTED_DOCS[$doc_path]}"
    log "ERROR" "Ownership collision: '$prev' and '$file' both map to doc path '$doc_path'"
    OWNERSHIP_COLLISIONS+=("$doc_path|$prev|$file")
    # Keep first mapping; do not silently overwrite
    continue
  fi
  EXPECTED_DOCS["$doc_path"]="$file"
done

if ((${#OWNERSHIP_COLLISIONS[@]} > 0)); then
  log "WARN" "Detected ${#OWNERSHIP_COLLISIONS[@]} ownership collision(s); first mapping retained, extras reported."
fi

# Soul sidecars inform stitching only — never enter EXPECTED_DOCS (they are not docs).
declare -A SOUL_TARGETS=()
if [[ -d "$META_DIR" ]]; then
  log "INFO" "Indexing structural soul sidecars from metadata registry..."
  # -print0 + read -d '' handles filenames with spaces/newlines safely
  while IFS= read -r -d '' soul_path; do
    rel_meta_path="${soul_path#"$META_DIR"/}"
    target_origin="${rel_meta_path%.soul.md}"
    SOUL_TARGETS["$target_origin"]="$soul_path"
  done < <(find "$META_DIR" -type f -name "*.soul.md" -print0 2>/dev/null || true)
fi

# --- 3. Obsolete-document handling -----------------------------------------

log "INFO" "Checking for obsolete docs..."
# rk_find_content uses -print0 (NUL-delimited) for safe handling of exotic filenames; mapfile -d '' preserves it
mapfile -d '' EXISTING_DOCS < <(
  rk_find_content "$DOCS_DIR" md textile cook
  if [[ -d "$HELP_DIR" ]]; then rk_find_content "$HELP_DIR" md textile cook; fi
)

# ---
# is_blessed_doc: True if doc or its target_file lives under .blessed.
# Inputs: $1 (doc path), $2 (target_file value)
# Outputs: Returns 0 if blessed, 1 otherwise
# Env: Reads DOCS_DIR, ROOT_DIR (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
is_blessed_doc() {
  local doc="$1"
  local rel_doc="${doc#"$ROOT_DIR"/}"
  local target_file_check="$2"
  local blessed_path
  for blessed_path in ${BLESSED_PATHS[@]+"${BLESSED_PATHS[@]}"}; do
    if path_is_under "$rel_doc" "$blessed_path"; then
      return 0
    fi
    if [[ -n "$target_file_check" ]] && path_is_under "$target_file_check" "$blessed_path"; then
      return 0
    fi
  done
  return 1
}

declare -a UNOWNED_DOCS=()
declare -a OBSOLETE_MOVED=()
declare -a AUTHORED_GUIDES=()

# In degraded fsbook mode, refuse obsolete moves (inventory incomplete).
for doc in ${EXISTING_DOCS[@]+"${EXISTING_DOCS[@]}"}; do
  [[ "$doc" == "$MATRIX_FILE" ]] && continue

  target_file_check=""
  if grep -q '^target_file:' "$doc" 2>/dev/null; then
    target_file_check=$(read_target_file "$doc" || true)
  fi
  # Explicit authorship is not a core-target exemption. Guides have their own
  # review/placeholder report, and cannot override an expected core reference.
  if [[ -z "$target_file_check" && -z "${EXPECTED_DOCS[$doc]:-}" \
    && "$(rk_frontmatter_field doc_type "$doc")" == guide ]]; then
    AUTHORED_GUIDES+=("$doc")
    continue
  fi
  [[ -n "${WHITELIST[$doc]:-}" ]] && continue
  if [[ -n "$target_file_check" && -n "${EXEMPT_TARGETS[$target_file_check]:-}" ]]; then
    continue
  fi

  if is_blessed_doc "$doc" "$target_file_check"; then
    continue
  fi

  # Already mapped as the expected doc for a live core file
  if [[ -n "${EXPECTED_DOCS[$doc]:-}" ]]; then
    continue
  fi

  # Strong evidence required to move:
  #   explicit target_file frontmatter AND that target is not a current core file.
  # No target_file → authored/uncertain → unowned, never move.
  if [[ -z "$target_file_check" ]]; then
    UNOWNED_DOCS+=("$doc")
    continue
  fi

  if [[ -n "${CORE_FILE_SET[$target_file_check]:-}" ]]; then
    # Target still core, but doc path is not the expected mirror path → misplaced, not obsolete
    UNOWNED_DOCS+=("$doc")
    log "WARN" "Misplaced doc (target still core, unexpected path): $doc → target_file=$target_file_check"
    continue
  fi

  if [[ "$DEGRADED_FSBOOK" == true ]]; then
    log "WARN" "Skipping obsolete move (fsbook degraded, inventory incomplete): $doc"
    UNOWNED_DOCS+=("$doc")
    continue
  fi

  # Strong evidence: generated-style reference with target_file no longer in core set
  REL_PATH="${doc#"$DOCS_DIR"/}"
  if [[ "$REL_PATH" == "$doc" ]]; then
    UNOWNED_DOCS+=("$doc")
    log "WARN" "Keeping doc outside DOCS_DIR; ownership needs review: $doc"
    continue
  fi
  if [[ "$REL_PATH" == /* || "$REL_PATH" == *".."* ]]; then
    log "ERROR" "Refuse obsolete move — unsafe relative path: $REL_PATH"
    continue
  fi
  if ! path_stays_under "$OBSOLETE_DIR" "$REL_PATH"; then
    # path_stays_under needs parent dirs to exist for cd; fall back to string check
    DEST_PROBE="${OBSOLETE_DIR}/${REL_PATH}"
    case "$DEST_PROBE" in
      "${OBSOLETE_DIR}"/*) ;;
      *)
        log "ERROR" "Refuse obsolete move — destination would escape OBSOLETE_DIR: $DEST_PROBE"
        continue
        ;;
    esac
  fi

  DEST_PATH="${OBSOLETE_DIR}/${REL_PATH}"
  DEST_DIR=$(dirname -- "$DEST_PATH")

  if [[ "${DRY_RUN:-false}" == true ]]; then
    log "DRY-RUN" "Would whisk obsolete doc: $doc -> $DEST_PATH"
    OBSOLETE_MOVED+=("$REL_PATH")
  else
    # SIDE EFFECT (delete/move): relocates an obsolete doc under bones/obsolete (source is
    # consumed by the move); never clobbers an existing destination
    if ! mkdir -p "$DEST_DIR"; then
      log "ERROR" "Cannot create obsolete dest dir (move aborted, source kept): $DEST_DIR"
      continue
    fi
    if ! mv -n "$doc" "$DEST_PATH" 2>/dev/null; then
      # -n may be unsupported; try without clobber semantics after existence check
      if [[ -e "$DEST_PATH" ]]; then
        log "ERROR" "Obsolete dest already exists (move aborted, source kept): $DEST_PATH"
        continue
      fi
      if ! mv "$doc" "$DEST_PATH"; then
        log "ERROR" "Failed to move obsolete doc (source kept): $doc"
        continue
      fi
    fi
    # mv -n exits 0 without moving when the destination exists (GNU and BSD);
    # verify the source is actually gone before reporting the move.
    if [[ -e "$doc" ]]; then
      log "ERROR" "Obsolete dest already exists (move aborted, source kept): $DEST_PATH"
      continue
    fi
    log "INFO" "Whisked obsolete doc: $REL_PATH (target_file=$target_file_check no longer core)"
    OBSOLETE_MOVED+=("$REL_PATH")
  fi
done

# --- pillar content builders -----------------------------------------------

# ---
# rel_path: Make path relative to ROOT_DIR when possible.
# Inputs: $1 (absolute or ROOT_DIR-relative path)
# Outputs: Prints relative path or "." for ROOT_DIR itself
# Env: Reads ARCHIVE_DIR, ASSETS_DIR, BONES_DIR, BOOK_REPORT_DIR, CONFIG_DIR, CONTENT_DIR ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
# Emit a path relative to ROOT_DIR when possible so stitched docs and the
# reports that bind them stay machine-independent (no host-specific absolutes).
rel_path() {
  local path="${1:-}"
  if [[ -n "$path" && "$path" == "$ROOT_DIR" ]]; then
    echo "."
  elif [[ -n "$path" && "$path" == "$ROOT_DIR"/* ]]; then
    echo "${path#"$ROOT_DIR"/}"
  else
    echo "$path"
  fi
}

# ---
# build_history_content: Read whole matching CHANGELOG bullets with release headings.
# Inputs: $1 (script basename)
# Outputs: Prints bullet list or Not-found placeholder
# Env: Reads BONES_DIR, DOCS_DIR, DRY_RUN, QUIET, ROOT_DIR, VERBOSE (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
build_history_content() {
  if [[ ! -f "$ROOT_DIR/CHANGELOG.md" ]]; then
    printf 'CHANGELOG.md is unavailable.\n'
    return
  fi
  awk -v script="$1" '
    function emit() {
      if (index(tolower(bullet), tolower(script))) {
        if (heading != previous) {
          print "#" heading "\n"; previous=heading
        }
        printf "%s\n", bullet; found=1
      }
      bullet=""
    }
    /^## / { emit(); heading=$0; next }
    /^#/ { emit(); next }
    /^[-*+] / { emit(); bullet=$0 "\n"; next }
    bullet != "" && /^[[:space:]]+[^[:space:]]/ {
      bullet=bullet $0 "\n"; next
    }
    /^[[:space:]]*$/ { next }
    { emit() }
    END {
      emit()
      if (!found) print "No matching entries in CHANGELOG.md."
    }
  ' "$ROOT_DIR/CHANGELOG.md"
}

# ---
# build_soul_content: Read soul sidecar body, stripping recursive DIP tail.
# Inputs: $1 (core-relative target file)
# Outputs: Prints sidecar prose or Not-found placeholder
# Env: Reads DRY_RUN (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
build_soul_content() {
  local target_file="$1"
  local soulbody target_origin sidecar
  soulbody=$(read_meta_sidecar_body "$target_file" || true)
  # On platforms without both realpath -m and readlink -f, the shared
  # resolver can return an empty body even though the metadata registry has
  # already indexed the exact sidecar path. Use that indexed path directly;
  # never synthesize soul content when neither source exists.
  if [[ -z "${soulbody//[[:space:]]/}" ]]; then
    target_origin=$(get_base_no_ext "$target_file")
    sidecar="${SOUL_TARGETS[$target_origin]:-}"
    if [[ -n "$sidecar" && -f "$sidecar" ]]; then
      soulbody=$(sed "1{/^---$/!q;}; 1,/^---$/d" "$sidecar")  # strip leading YAML frontmatter (--- ... ---) if present
    fi
  fi
  # Sidecars can themselves have been stitched.  Strip only the recursive
  # generated tail, retaining all authored prose before that marker.
  if [[ "$soulbody" == *"<!-- DIP-"* ]]; then
    soulbody=$(printf '%s\n' "$soulbody" | awk '  # awk truncates at first stitched DIP marker and trims trailing scaffolding

      { lines[NR]=$0 }
      END {
        stop=0
        for (i=1; i<=NR; i++) if (lines[i] ~ /^<!-- DIP-[A-Z0-9-]+-EXTRACTED:/) { stop=i-1; break }
        if (stop==0) stop=NR
        while (stop>0 && lines[stop] ~ /^[[:space:]]*$/) stop--
        if (stop>0 && lines[stop] ~ /^##[[:space:]]+(Notes([[:space:]]|$)|Necromancer)/) stop--
        while (stop>0 && lines[stop] ~ /^[[:space:]]*$/) stop--
        for (i=1; i<=stop; i++) print lines[i]
      }
    ')
  fi
  if [[ -z "${soulbody//[[:space:]]/}" ]]; then
    printf '%s\n' "No sidecar notes are documented for \`$target_file\`."
  else
    printf '%s\n' "$soulbody"
  fi
}

# Read an annotated header field and its indented comment continuation lines.
script_header_field() {
  awk -v field="$2" '
    $0 ~ ("^#[[:space:]]+" field "[[:space:]]*:") {
      sub("^#[[:space:]]+" field "[[:space:]]*:[[:space:]]*", "")
      print; grab=1; next
    }
    grab && /^#[[:space:]][[:space:]][[:space:]]+[^[:space:]]/ {
      sub(/^#[[:space:]]+/, ""); print; next
    }
    grab { exit }
  ' "$ROOT_DIR/$1"
}

# Read static help without executing the script. Additional help sections are
# kept under Options, including Flags, Modes, Arguments, and shared options.
script_help_section() {
  awk -v section="$2" -v version="$VERSION" '
    /^# @HELP[[:space:]]*$/ { help=1; next }
    /^# @END-HELP[[:space:]]*$/ { exit }
    help {
      sub(/^#[[:space:]]?/, "")
      if ($0 ~ /^[A-Za-z][A-Za-z \/-]*:$/) {
        name=substr($0, 1, length($0)-1)
        selected=(name == section)
        if (section == "Options") {
          selected=(name !~ /^(Usage|Description|Examples|Exit codes)$/)
          if (selected && name != "Options") print name ":"
        }
        next
      }
      if (selected) {
        sub(/^  /, ""); gsub(/\{VERSION\}/, version); print
      }
    }
  ' "$ROOT_DIR/$1"
}

# Command-reference v1 (#326): rebuild owned script references from source.
build_command_reference() {
  local target_file="$1"
  local script_name purpose section content label field
  script_name=$(basename -- "$target_file")
  purpose=$(script_header_field "$target_file" Purpose)
  [[ -n "${purpose//[[:space:]]/}" ]] || purpose="Purpose is not documented in the script header."

  printf '%s\n' '---'
  RK_REF_TARGET="$target_file" RK_REF_TITLE="$script_name" \
    RK_REF_PURPOSE="$purpose" RK_REF_VERSION="$VERSION" yq -n '
      .reference_contract = "rotkeeper.command-reference.v1" |
      .title = strenv(RK_REF_TITLE) |
      .slug = (strenv(RK_REF_TITLE) | sub("\.sh$"; "")) |
      .target_file = strenv(RK_REF_TARGET) |
      .template = "rotkeeper-doc.html" |
      .status = "active" |
      .version = strenv(RK_REF_VERSION) |
      .author = "Rotkeeper DIP" |
      .project = "Rotkeeper" |
      .description = strenv(RK_REF_PURPOSE)' || return 1
  printf '%s\n\n' '---' "# $script_name" '## Overview'
  printf '%s\n\n' "$purpose"
  printf "Source: \`%s\`.\n\n" "$target_file"

  for section in Usage Options Examples 'Exit codes'; do
    content=$(script_help_section "$target_file" "$section") || return 1
    content=$(normalize_body "$content")
    printf '## %s\n\n' "$section"
    if [[ -n "${content//[[:space:]]/}" ]]; then
      case "$section" in
        Usage|Examples) printf "\`\`\`bash\n%s\n\`\`\`\n\n" "$content" ;;
        *) printf "\`\`\`text\n%s\n\`\`\`\n\n" "$content" ;;
      esac
    else
      printf 'Not documented in the script help block. Consult the source; no command behavior is inferred.\n\n'
    fi
  done

  printf '## Reads and writes\n\n'
  for field in 'Env assumptions' 'CWD assumptions' 'Input/Output contracts'; do
    case "$field" in
      'Env assumptions') label=Environment ;;
      'CWD assumptions') label='Working directory' ;;
      *) label='Inputs and outputs' ;;
    esac
    content=$(script_header_field "$target_file" "$field")
    [[ -n "${content//[[:space:]]/}" ]] || content="Not documented in the script header."
    printf '**%s:** %s\n\n' "$label" "$content"
  done
  printf '## Side effects\n\n'
  awk '
    /^[[:space:]]*# SIDE EFFECT \(/ {
      sub(/^[[:space:]]*# SIDE EFFECT \(/, "- **")
      sub(/\):[[:space:]]*/, ":** ")
      print; found=1; grab=1; next
    }
    grab && /^[[:space:]]*#[[:space:]]+[^[:space:]]/ {
      sub(/^[[:space:]]*#[[:space:]]*/, ""); print "  " $0; next
    }
    { grab=0 }
    END { if (!found) print "No side effects are documented in script annotations." }
  ' "$ROOT_DIR/$target_file"
  printf '\n## Notes\n<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->\n\n'
  content=$(build_soul_content "$target_file")
  # Older sidecars use H2 body headings. Nest those under Notes without
  # modifying the sidecar sources being reviewed separately in #329.
  content=$(printf '%s\n' "$content" | awk '
    /^```/ { fence=!fence }
    !fence && /^## / { sub(/^## /, "### ") }
    { print }
  ')
  normalize_body "$content"
  printf '\n## History\n<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->\n\n'
  build_history_content "$script_name"
}

# Read the dispatcher, never execute command scripts to discover mappings.
# Aliases share a case arm; removed commands have no script mapping.
build_command_index() {
  local rows command target description doc
  rows=$(awk '
    /^# @HELP$/ { help=1; next }
    /^# @END-HELP$/ { help=0; next }
    help {
      line=$0; sub(/^#[[:space:]]?/, "", line)
      if (line ~ /^[A-Za-z][A-Za-z ]*:$/) { commands=(line == "Commands:"); next }
      if (commands && line ~ /^[[:space:]]+[a-z][a-z0-9-]*[[:space:]]/) {
        sub(/^[[:space:]]+/, "", line)
        cmd=line; sub(/[[:space:]].*$/, "", cmd)
        desc=line; sub(/^[^[:space:]]+[[:space:]]+/, "", desc)
        sub(/^<[^>]+>[[:space:]]+/, "", desc)
        if (cmd in descriptions) bad=1
        order[++n]=cmd; descriptions[cmd]=desc
      }
      next
    }
    /^case "\$command" in$/ { dispatch=1; next }
    dispatch && /^[[:space:]]*[a-z][a-z0-9|-]*\)$/ {
      arm=$0; gsub(/^[[:space:]]+|\)$/, "", arm); next
    }
    dispatch && /^[[:space:]]*;;$/ { arm=""; next }
    dispatch && arm != "" && match($0, /"\$BONES\/rc-[a-z0-9-]+\.sh"/) {
      target=substr($0, RSTART+1, RLENGTH-2); sub(/^\$BONES\//, "bones/scripts/", target)
      split(arm, aliases, "|")
      for (i in aliases) targets[aliases[i]]=target
      arms[arm]=target
    }
    END {
      if (!n || bad) exit 1
      for (a in arms) {
        found=0; split(a, aliases, "|")
        for (i in aliases) if (aliases[i] in descriptions) found=1
        if (!found) exit 1
      }
      for (i=1; i<=n; i++) {
        cmd=order[i]
        if (!(cmd in targets)) exit 1
        print cmd "\t" targets[cmd] "\t" descriptions[cmd]
      }
    }
  ' "$ROOT_DIR/rotkeeper.sh") || {
    log "ERROR" "Dispatcher commands and help disagree; cannot generate the command index."
    return 1
  }
  printf '%s\n' '| Command | Purpose | Reference |' '| --- | --- | --- |'
  while IFS=$'\t' read -r command target description; do
    [[ -f "$ROOT_DIR/$target" ]] || return 1
    doc=$(expected_doc_for_core "$target")
    doc="${doc#"$DOCS_DIR"/}"
    description="${description//|/\\|}"
    printf "| \`%s\` | %s | [%s](%s) |\n" "$command" "$description" \
      "${target##*/}" "${doc%.md}.html"
  done <<< "$rows"
}

# Only the explicitly marked block belongs to DIP; surrounding authored prose
# stays unchanged. An absent index or unmarked page is not created or replaced.
refresh_command_index() {
  local doc="$DOCS_DIR/index.md" content updated
  [[ -f "$doc" ]] || return 0
  grep -q '<!-- DIP-COMMAND-INDEX-' "$doc" || return 0
  if ! awk '
    /^<!-- DIP-COMMAND-INDEX-START -->$/ { starts++; if (ends) bad=1 }
    /^<!-- DIP-COMMAND-INDEX-END -->$/ { ends++; if (!starts) bad=1 }
    END { exit !(starts == 1 && ends == 1 && !bad) }
  ' "$doc"; then
    log "ERROR" "Invalid command-index markers: $doc"
    return 1
  fi
  content=$(build_command_index) || return 1
  updated=$(RK_COMMAND_INDEX="$content" awk '
    /^<!-- DIP-COMMAND-INDEX-START -->$/ { print; print ENVIRON["RK_COMMAND_INDEX"]; block=1; next }
    /^<!-- DIP-COMMAND-INDEX-END -->$/ { block=0 }
    !block { print }
  ' "$doc") || return 1
  if [[ "$updated" != "$(cat "$doc")" ]]; then
    if [[ "${DRY_RUN:-false}" == true ]]; then
      log "DRY-RUN" "Would refresh dispatcher command index: $doc"
    else
      printf '%s\n' "$updated" | atomic_write "$doc"
    fi
  fi
}

# Ensure required marker scaffolding exists without clobbering authored body.
ensure_dip_markers() {
  local doc_path="$1"
  local needs=()

  grep -q '<!-- DIP-ENV-EXTRACTED:' "$doc_path" 2>/dev/null || needs+=("env")
  grep -q '<!-- DIP-HELP-EXTRACTED:' "$doc_path" 2>/dev/null || needs+=("help")
  grep -q '<!-- DIP-HISTORY-EXTRACTED:' "$doc_path" 2>/dev/null || needs+=("history")
  grep -q '<!-- DIP-SOUL-EXTRACTED:' "$doc_path" 2>/dev/null || needs+=("soul")

  if ((${#needs[@]} == 0)); then
    return 0
  fi

  if [[ "${DRY_RUN:-false}" == true ]]; then
    local needs_csv
    needs_csv=$(IFS=','; echo "${needs[*]}")
    log "DRY-RUN" "Would append missing DIP markers (${needs_csv}) to $doc_path"
    return 0
  fi

  local append=""
  for n in "${needs[@]}"; do
    case "$n" in
      env)
        append+=$'\n## Reads and writes\n<!-- DIP-ENV-EXTRACTED: 0000-00-00T00:00:00Z -->\n*Not found: contracts not yet stitched.*\n'
        ;;
      help)
        append+=$'\n## Usage\n<!-- DIP-HELP-EXTRACTED: 0000-00-00T00:00:00Z -->\n*Not found: help not yet stitched.*\n'
        ;;
      history)
        append+=$'\n## History\n<!-- DIP-HISTORY-EXTRACTED: 0000-00-00T00:00:00Z -->\n*Not found: history not yet stitched.*\n'
        ;;
      soul)
        append+=$'\n## Notes\n<!-- DIP-SOUL-EXTRACTED: 0000-00-00T00:00:00Z -->\n*Not found: notes not yet stitched.*\n'
        ;;
    esac
  done
  # Append the scaffolding through the shared atomic writer so an
  # interruption cannot leave a half-written document.
  {
    cat "$doc_path"
    printf '%s' "$append"
  } | atomic_write "$doc_path"
}

# Rename only marker-owned headings. A task guide with an authored heading
# that happens to use the same words must remain byte-identical.
migrate_pillar_names() {
  local doc="$1" migrated
  [[ -f "$doc" ]] || return 0
  migrated=$(awk '
    { lines[NR]=$0 }
    END {
      for (i=1; i<=NR; i++) {
        if (lines[i] ~ /^(```|~~~)/) {
          fence=!fence; print lines[i]; continue
        }
        if (fence) { print lines[i]; continue }
        j=i+1
        while (j<=NR && lines[j] ~ /^[[:space:]]*$/) j++
        # Older stubs sometimes lost their help marker. Remove only this
        # exact generated placeholder, not an authored CLI Usage section.
        if (lines[i] ~ /^######[[:space:]]+CLI[[:space:]]+Usage/ &&
            lines[j] == "TODO: Stitch extracted help block.") {
          i=j; continue
        }
        if (lines[j] ~ /^<!-- DIP-SOUL-EXTRACTED:/ &&
            lines[i] ~ /^##[[:space:]]+Necromancer/) lines[i]="## Notes"
        if (lines[j] ~ /^<!-- DIP-HISTORY-EXTRACTED:/ &&
            lines[i] ~ /^##[[:space:]]+Ritual[[:space:]]+History/) lines[i]="## History"
        if (lines[j] ~ /^<!-- DIP-ENV-EXTRACTED:/ &&
            lines[i] ~ /^##[[:space:]]+Environment([[:space:]]|$)/) lines[i]="## Reads and writes"
        if (lines[j] ~ /^<!-- DIP-HELP-EXTRACTED:/ &&
            lines[i] ~ /^######[[:space:]]+CLI[[:space:]]+Usage/) lines[i]="## Usage"
        print lines[i]
      }
    }
  ' "$doc")
  if [[ "$migrated" != "$(cat "$doc")" ]]; then
    if [[ "${DRY_RUN:-false}" == true ]]; then
      log "DRY-RUN" "Would migrate DIP headings: $doc"
    else
      printf '%s\n' "$migrated" | atomic_write "$doc"
    fi
  fi
}

for doc in ${EXISTING_DOCS[@]+"${EXISTING_DOCS[@]}"}; do
  [[ -f "$doc" ]] || continue
  tf=$(read_target_file "$doc")
  [[ -z "$tf" || -z "${EXEMPT_TARGETS[$tf]:-}" ]] || continue
  migrate_pillar_names "$doc"
  # Remove the old command-only dumps from non-command mirrors as well,
  # including whitelisted generated pages outside the current core inventory.
  if [[ -n "$tf" && "$tf" != *.sh ]]; then
    stitch_pillar "$doc" "DIP-ENV-EXTRACTED" "This file is not a script; no script environment contract applies."
    stitch_pillar "$doc" "DIP-HELP-EXTRACTED" "This file has no command-line interface."
    history_content=$(build_history_content "$(basename -- "$tf")")
    stitch_pillar "$doc" "DIP-HISTORY-EXTRACTED" "$history_content"
  fi
done

# --- 4. Stub missing or empty docs ------------------------------------------
#  Stub policy (#241): a doc page is stub-eligible only when it does not exist
#  or carries no content at all (whitespace-only counts as empty). Any
#  non-empty file is treated as authored/generated content and is never
#  overwritten here; stub-marked docs are updated by pillar stitching instead.

log "INFO" "Checking for missing docs..."
for doc_path in "${!EXPECTED_DOCS[@]}"; do
  target_file="${EXPECTED_DOCS[$doc_path]}"
  [[ -z "${EXEMPT_TARGETS[$target_file]:-}" ]] || continue
  rel_expected="${doc_path#"$ROOT_DIR"/}"
  if [[ "$doc_path" != "$DOCS_DIR"/* ]] || ! path_stays_under "$ROOT_DIR" "$rel_expected"; then
    log "ERROR" "Refusing unsafe generated doc path outside ROOT_DIR/DOCS_DIR: $doc_path"
    continue
  fi
  if [[ -f "$doc_path" ]]; then
    if [[ -n "$(tr -d '[:space:]' <"$doc_path")" ]]; then
      continue
    fi
    log "INFO" "Doc exists but is empty — restubbing: $doc_path"
  fi

  if [[ "${DRY_RUN:-false}" == true ]]; then
    log "DRY-RUN" "Would stub missing doc: $doc_path (target_file=$target_file)"
    continue
  fi

  if [[ "$target_file" == *.sh && -f "$ROOT_DIR/$target_file" ]]; then
    reference_content=$(build_command_reference "$target_file")
    printf '%s\n' "$reference_content" | atomic_write "$doc_path"
    log "INFO" "Generated command reference: $doc_path"
    continue
  fi

  # SIDE EFFECT (write): creates the doc directory and writes a stub doc in place
  mkdir -p "$(dirname -- "$doc_path")"
  TITLE=$(basename -- "$doc_path" .md)
  stub_tmp="${doc_path}.tmp.$$"
  cat <<STUB >"$stub_tmp"
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

## Usage
<!-- DIP-HELP-EXTRACTED: 0000-00-00T00:00:00Z -->
TODO: Stitch extracted help block.

## Reads and writes
<!-- DIP-ENV-EXTRACTED: 0000-00-00T00:00:00Z -->
TODO: Stitch environment variables.

## History
<!-- DIP-HISTORY-EXTRACTED: 0000-00-00T00:00:00Z -->
TODO: Stitch history.

## Notes
<!-- DIP-SOUL-EXTRACTED: 0000-00-00T00:00:00Z -->
TODO: Stitch notes.
STUB
  mv -f "$stub_tmp" "$doc_path"
  log "INFO" "Stubbed missing doc: $doc_path"
done

# --- 5. Generate script references and stitch non-command reference pillars --

log "INFO" "Generating source-driven command references and reference pillars..."

for doc_path in "${!EXPECTED_DOCS[@]}"; do
  target_file="${EXPECTED_DOCS[$doc_path]}"
  [[ -z "${EXEMPT_TARGETS[$target_file]:-}" ]] || continue
  [[ -f "$doc_path" ]] || continue
  rel_expected="${doc_path#"$ROOT_DIR"/}"
  if [[ "$doc_path" != "$DOCS_DIR"/* ]] || ! path_stays_under "$ROOT_DIR" "$rel_expected"; then
    log "ERROR" "Refusing unsafe generated doc path outside ROOT_DIR/DOCS_DIR: $doc_path"
    continue
  fi
  target_file="${EXPECTED_DOCS[$doc_path]}"
  script_name=$(basename -- "$target_file")

  if [[ "$target_file" == *.sh ]]; then
    if [[ -f "$ROOT_DIR/$target_file" \
      && "$(read_target_file "$doc_path")" == "$target_file" ]]; then
      reference_content=$(build_command_reference "$target_file")
      if [[ "$reference_content" != "$(cat "$doc_path")" ]]; then
        if [[ "${DRY_RUN:-false}" == true ]]; then
          log "DRY-RUN" "Would regenerate command reference: $doc_path"
        else
          printf '%s\n' "$reference_content" | atomic_write "$doc_path"
        fi
      fi
    fi
    # An unowned script page is not a non-command mirror. Preserve it
    # instead of inserting false no-script/no-CLI fallback claims.
    continue
  fi

  # Only stitch generated reference docs that already carry DIP markers,
  # or stubs we just created. Do not inject markers into pure authored docs
  # that happen to share a path key (should not happen for EXPECTED_DOCS).
  if ! grep -qE '<!-- DIP-(ENV|HELP|HISTORY|SOUL)-EXTRACTED:' "$doc_path" 2>/dev/null; then
    # If status is stub or target_file matches, scaffold markers once
    local_status=$(read_status_field "$doc_path" || true)
    tf=$(read_target_file "$doc_path" || true)
    if [[ "${local_status,,}" == "stub" || "$tf" == "$target_file" ]]; then
      ensure_dip_markers "$doc_path"
    else
      continue
    fi
  else
    ensure_dip_markers "$doc_path"
  fi

  history_content=$(build_history_content "$script_name")
  soul_content=$(build_soul_content "$target_file")

  stitch_pillar "$doc_path" "DIP-ENV-EXTRACTED" "This file is not a script; no script environment contract applies."
  stitch_pillar "$doc_path" "DIP-HELP-EXTRACTED" "This file has no command-line interface."
  stitch_pillar "$doc_path" "DIP-HISTORY-EXTRACTED" "$history_content"
  stitch_pillar "$doc_path" "DIP-SOUL-EXTRACTED" "$soul_content"
done

refresh_command_index

# Identify reachable sidecars using the three existing lookup rules. A
# target_file inside a sidecar is descriptive, not an alternative lookup path.
declare -A SIDECAR_CONSUMERS=() EXEMPT_SIDECARS=()
for file in ${CORE_FILES[@]+"${CORE_FILES[@]}"}; do
  origin=$(get_base_no_ext "$file")
  sidecar="${SOUL_TARGETS[$origin]:-}"
  [[ -n "$sidecar" ]] || continue
  if [[ -n "${EXEMPT_TARGETS[$file]:-}" ]]; then
    EXEMPT_SIDECARS["$sidecar"]=1
  else
    SIDECAR_CONSUMERS["$sidecar"]="dip"
  fi
done
if [[ -d "$CONTENT_DIR" ]]; then
  while IFS= read -r -d '' dir; do
    origin="${dir#"$CONTENT_DIR"/}"
    [[ "$dir" != "$CONTENT_DIR" ]] || origin=rotkeeper
    sidecar="${SOUL_TARGETS[$origin]:-}"
    [[ -n "$sidecar" ]] || continue
    SIDECAR_CONSUMERS["$sidecar"]="${SIDECAR_CONSUMERS[$sidecar]:+${SIDECAR_CONSUMERS[$sidecar]},}glue"
  done < <(find "$CONTENT_DIR" -type d -print0)
  while IFS= read -r -d '' page; do
    origin=$(get_base_no_ext "${page#"$CONTENT_DIR"/}")
    sidecar="${SOUL_TARGETS[$origin]:-}"
    [[ -n "$sidecar" ]] || continue
    # Coverage is reachability, independent of render_system_docs selection.
    SIDECAR_CONSUMERS["$sidecar"]="${SIDECAR_CONSUMERS[$sidecar]:+${SIDECAR_CONSUMERS[$sidecar]},}render"
  done < <(rk_find_content "$CONTENT_DIR" md textile cook)
fi
declare -a ORPHANED_SIDECARS=()
for origin in "${!SOUL_TARGETS[@]}"; do
  sidecar="${SOUL_TARGETS[$origin]}"
  if [[ -z "${SIDECAR_CONSUMERS[$sidecar]:-}" && -z "${EXEMPT_SIDECARS[$sidecar]:-}" ]]; then
    ORPHANED_SIDECARS+=("${sidecar#"$ROOT_DIR"/}")
  fi
done
if ((${#ORPHANED_SIDECARS[@]} > 0)); then
  mapfile -t ORPHANED_SIDECARS < <(printf '%s\n' "${ORPHANED_SIDECARS[@]}" | LC_ALL=C sort)
fi

# --- 6. Matrix generation --------------------------------------------------

log "INFO" "Generating DIP Matrix at $MATRIX_FILE..."

declare -A STAT_COUNTS=(
  ["OK"]=0
  ["Stub"]=0
  ["Missing"]=0
  ["Stale"]=0
  ["Unowned"]=0
  ["Exempt"]=0
)
declare -A COVERAGE_COUNTS=([present]=0 [missing]=0 [exempt]=0)
PLACEHOLDER_COUNT=0
PLACEHOLDER_PAGES=0
STALE_KNOWN=0
STALE_UNKNOWN=0
STALE_DOCS=0
STALE_SIDECARS=0
declare -a GUIDE_ROWS=() GUIDE_PATHS=() GUIDE_STATES=() GUIDE_DATES=() GUIDE_PLACEHOLDERS=()

if ((${#AUTHORED_GUIDES[@]} > 0)); then
  mapfile -t AUTHORED_GUIDES < <(printf '%s\n' "${AUTHORED_GUIDES[@]}" | LC_ALL=C sort)
fi
for doc in ${AUTHORED_GUIDES[@]+"${AUTHORED_GUIDES[@]}"}; do
  reviewed=$(rk_frontmatter_field reviewed "$doc")
  todo_count=$(count_todo_lines "$doc")
  record_git_edit "$doc"
  guide_state="Needs review"
  if [[ "$reviewed" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ \
    && ! "$reviewed" > "${DATE_STR%%T*}" \
    && ( "${GIT_EDIT_DATES[$doc]}" == unknown || ! "${GIT_EDIT_DATES[$doc]}" > "$reviewed" ) ]]; then
    guide_state="Reviewed"
  fi
  ((todo_count == 0)) || guide_state="Incomplete"
  PLACEHOLDER_COUNT=$((PLACEHOLDER_COUNT + todo_count))
  ((todo_count == 0)) || PLACEHOLDER_PAGES=$((PLACEHOLDER_PAGES + 1))
  rel_guide="${doc#"$CONTENT_DIR"/}"
  GUIDE_ROWS+=("| [$rel_guide](../$rel_guide) | ${reviewed:-Not recorded} | $guide_state | $todo_count |")
  GUIDE_PATHS+=("${doc#"$ROOT_DIR"/}")
  GUIDE_STATES+=("$guide_state")
  GUIDE_DATES+=("$reviewed")
  GUIDE_PLACEHOLDERS+=("$todo_count")
done

declare -a MATRIX_ROWS=()

# Parallel row capture for --json emission (order mirrors MATRIX_ROWS)
declare -a J_TARGETS=() J_DOCS=() J_CODE_DATES=() J_DOC_DATES=() J_STATUSES=()
declare -a J_SECTIONS=() J_PLACEHOLDERS=() J_SIDECARS=() J_COVERAGE=() \
  J_STALE=() J_DOC_STALE=() J_SOUL_STALE=() J_SOUL_DATES=() J_REASONS=()

collect_section_states() {
  local doc="$1" command="$2" override="${3:-}" key state count data sep=""
  data=$(section_states "$doc" "$command") || return 1
  SECTIONS_JSON="{"
  SECTIONS_TEXT=""
  SECTION_GAPS=0
  while IFS=$'\t' read -r key state count; do
    [[ -z "$override" ]] || state="$override"
    [[ "$state" == populated || "$state" == exempt ]] || SECTION_GAPS=$((SECTION_GAPS + 1))
    SECTIONS_JSON+="${sep}\"$key\":{\"state\":\"$state\",\"placeholders\":$count}"
    SECTIONS_TEXT+="${SECTIONS_TEXT:+; }${key//_/ }: $state"
    sep=","
  done <<< "$data"
  SECTIONS_JSON+="}"
}

# Stable iteration for deterministic matrix output
mapfile -t SORTED_DOC_PATHS < <(printf '%s\n' "${!EXPECTED_DOCS[@]}" | LC_ALL=C sort)

for doc_path in ${SORTED_DOC_PATHS[@]+"${SORTED_DOC_PATHS[@]}"}; do
  target_file="${EXPECTED_DOCS[$doc_path]}"
  status="Missing"
  base_stat="Missing"
  record_git_edit "$ROOT_DIR/$target_file"
  record_git_edit "$doc_path"
  code_date="${GIT_EDIT_DATES[$ROOT_DIR/$target_file]}"
  doc_date="${GIT_EDIT_DATES[$doc_path]}"
  doc_stale=$(git_staleness "$ROOT_DIR/$target_file" "$doc_path")
  origin=$(get_base_no_ext "$target_file")
  sidecar="${SOUL_TARGETS[$origin]:-}"
  soul_date="Missing"
  soul_stale="unknown"
  coverage="missing"
  if [[ -n "$sidecar" ]]; then
    coverage="present"
    record_git_edit "$sidecar"
    soul_date="${GIT_EDIT_DATES[$sidecar]}"
    soul_stale=$(git_staleness "$ROOT_DIR/$target_file" "$sidecar")
  fi
  stale="current"
  if [[ "$doc_stale" == unknown || "$soul_stale" == unknown ]]; then
    stale="unknown"
  elif [[ "$doc_stale" == stale || "$soul_stale" == stale ]]; then
    stale="stale"
  fi
  command=false
  [[ "$target_file" != *.sh ]] || command=true
  todo_count=0
  reason="${EXEMPT_TARGETS[$target_file]:-}"
  if [[ -n "$reason" ]]; then
    status="Exempt"; base_stat="Exempt"; coverage="exempt"
    stale="exempt"; doc_stale="exempt"; soul_stale="exempt"
    collect_section_states /dev/null "$command" exempt
  else
    collect_section_states "$doc_path" "$command"
    if [[ -f "$doc_path" ]]; then
      todo_count=$(count_todo_lines "$doc_path")
      status_field=$(read_status_field "$doc_path" || true)
      if ((todo_count > 0 || SECTION_GAPS > 0)) || [[ "${status_field,,}" == stub ]]; then
        status="Stub"; base_stat="Stub"
      elif [[ "${status_field,,}" == missing ]]; then
        status="Missing"; base_stat="Missing"
      elif [[ "$stale" == stale ]]; then
        status="Stale"; base_stat="Stale"
      else
        status="OK"; base_stat="OK"
      fi
    fi
    PLACEHOLDER_COUNT=$((PLACEHOLDER_COUNT + todo_count))
    ((todo_count == 0)) || PLACEHOLDER_PAGES=$((PLACEHOLDER_PAGES + 1))
    [[ "$doc_stale" != stale ]] || STALE_DOCS=$((STALE_DOCS + 1))
    [[ "$soul_stale" != stale ]] || STALE_SIDECARS=$((STALE_SIDECARS + 1))
    [[ "$stale" != stale ]] || STALE_KNOWN=$((STALE_KNOWN + 1))
    [[ "$stale" != unknown ]] || STALE_UNKNOWN=$((STALE_UNKNOWN + 1))
  fi

  COVERAGE_COUNTS["$coverage"]=$((COVERAGE_COUNTS[$coverage] + 1))
  STAT_COUNTS["$base_stat"]=$((${STAT_COUNTS[$base_stat]:-0} + 1))
  rel_doc="${doc_path#"$DOCS_DIR"/}"
  if [[ "$base_stat" == "Missing" || "$base_stat" == "Exempt" ]]; then
    doc_ref="\`$rel_doc\`"
  else
    doc_ref="[$rel_doc]($rel_doc)"
  fi
  MATRIX_ROWS+=("| \`$target_file\` | $doc_ref | $code_date | $doc_date | $status | $todo_count | $SECTIONS_TEXT | $coverage | doc: $doc_stale; sidecar: $soul_stale |")
  J_TARGETS+=("$target_file")
  J_DOCS+=("$rel_doc")
  J_CODE_DATES+=("$code_date")
  J_DOC_DATES+=("$doc_date")
  J_STATUSES+=("$status")
  J_SECTIONS+=("$SECTIONS_JSON")
  J_PLACEHOLDERS+=("$todo_count")
  J_SIDECARS+=("${sidecar#"$ROOT_DIR"/}")
  J_COVERAGE+=("$coverage")
  J_STALE+=("$stale")
  J_DOC_STALE+=("$doc_stale")
  J_SOUL_STALE+=("$soul_stale")
  J_SOUL_DATES+=("$soul_date")
  J_REASONS+=("$reason")
done

if ((${#UNOWNED_DOCS[@]} > 0)); then
  mapfile -t SORTED_UNOWNED < <(printf '%s\n' ${UNOWNED_DOCS[@]+"${UNOWNED_DOCS[@]}"} | LC_ALL=C sort -u)
else
  mapfile -t SORTED_UNOWNED < /dev/null
fi
for doc_path in ${SORTED_UNOWNED[@]+"${SORTED_UNOWNED[@]}"}; do
  rel_doc="${doc_path#"$DOCS_DIR"/}"
  if [[ "$rel_doc" == "$doc_path" ]]; then
    rel_doc="../${doc_path#"$CONTENT_DIR"/}"
  fi
  record_git_edit "$doc_path"
  doc_date="${GIT_EDIT_DATES[$doc_path]}"
  status="Unowned"
  todo_count=$(count_todo_lines "$doc_path")
  PLACEHOLDER_COUNT=$((PLACEHOLDER_COUNT + todo_count))
  ((todo_count == 0)) || PLACEHOLDER_PAGES=$((PLACEHOLDER_PAGES + 1))
  STAT_COUNTS["Unowned"]=$((STAT_COUNTS["Unowned"] + 1))
  MATRIX_ROWS+=("| \`Unknown\` | [$rel_doc]($rel_doc) | Missing | $doc_date | $status | $todo_count | Not a core reference | Not applicable | unknown |")
  J_TARGETS+=("Unknown")
  J_DOCS+=("$rel_doc")
  J_CODE_DATES+=("Missing")
  J_DOC_DATES+=("$doc_date")
  J_STATUSES+=("$status")
  J_SECTIONS+=("{}")
  J_PLACEHOLDERS+=("$todo_count")
  J_SIDECARS+=("")
  J_COVERAGE+=("not_applicable")
  J_STALE+=("unknown")
  J_DOC_STALE+=("unknown")
  J_SOUL_STALE+=("unknown")
  J_SOUL_DATES+=("Missing")
  J_REASONS+=("")
done

total_rows=${#MATRIX_ROWS[@]}
stale_state="known"
if [[ "$GIT_HISTORY" != complete ]] || ((STALE_UNKNOWN > 0)); then
  stale_state="unknown"
fi
totals_line="**Totals:** OK: ${STAT_COUNTS[OK]} | Stub: ${STAT_COUNTS[Stub]} | Missing: ${STAT_COUNTS[Missing]} | Stale rows: ${STAT_COUNTS[Stale]} | Unowned: ${STAT_COUNTS[Unowned]} | Exempt: ${STAT_COUNTS[Exempt]} | Rows: ${total_rows}"
coverage_line="**Sidecar coverage (targets):** present: ${COVERAGE_COUNTS[present]} | missing: ${COVERAGE_COUNTS[missing]} | exempt: ${COVERAGE_COUNTS[exempt]} | orphaned sidecars: ${#ORPHANED_SIDECARS[@]}"
staleness_line="**Staleness:** $stale_state | known stale targets: $STALE_KNOWN | unknown targets: $STALE_UNKNOWN | stale docs: $STALE_DOCS | stale sidecars: $STALE_SIDECARS"

# --- 6b. Machine-readable stdout (--json) -----------------------------------
# --json mirrors the published matrix as a single schema-tagged JSON object on
# fd 3 (visible even in quiet mode). Matrix publication, the MARKER summary,
# and exit codes are unchanged. Under --dry-run the computed audit result is
# still emitted and nothing is written.
if [[ "$JSON_MODE" == true ]]; then
  if ! command -v jq >/dev/null 2>&1; then
    log "ERROR" "dip --json requires jq."
    exit 1
  fi

  mkdir -p "$TMP_DIR"

  rows_json="[]"
  if ((${#J_TARGETS[@]} > 0)); then
    rows_json=$(
      for i in "${!J_TARGETS[@]}"; do
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
          "${J_TARGETS[$i]}" "${J_DOCS[$i]}" "${J_CODE_DATES[$i]}" "${J_DOC_DATES[$i]}" "${J_STATUSES[$i]}" \
          "${J_SECTIONS[$i]}" "${J_PLACEHOLDERS[$i]}" "${J_SIDECARS[$i]}" "${J_COVERAGE[$i]}" \
          "${J_STALE[$i]}" "${J_DOC_STALE[$i]}" "${J_SOUL_STALE[$i]}" "${J_SOUL_DATES[$i]}" "${J_REASONS[$i]}"
      done | jq -Rn '
        [inputs | select(length > 0) | split("\t")]
        | map({target_file: .[0], doc: .[1], last_code_edit: .[2], last_doc_edit: .[3], status: .[4],
            sections: (.[5] | fromjson), placeholder_count: (.[6] | tonumber),
            sidecar: {path: ((.[7] | select(length > 0)) // null), state: .[8],
              last_edit: .[12], stale: .[11]},
            stale: (if .[9] == "stale" then true elif .[9] == "current" then false else .[9] end),
            staleness: {doc: .[10], sidecar: .[11]}, exemption_reason: .[13]})
      '
    )
  fi

  collisions_json="[]"
  if ((${#OWNERSHIP_COLLISIONS[@]} > 0)); then
    collisions_json=$(
      printf '%s\n' "${OWNERSHIP_COLLISIONS[@]}" | LC_ALL=C sort |
        jq -Rn '[inputs | select(length > 0) | split("|")] | map({doc: .[0], claims: [.[1], .[2]]})'
    )
  fi

  obsolete_json="[]"
  if ((${#OBSOLETE_MOVED[@]} > 0)); then
    obsolete_json=$(printf '%s\n' "${OBSOLETE_MOVED[@]}" | jq -R -s 'split("\n") | map(select(length > 0))')
  fi
  orphans_json="[]"
  if ((${#ORPHANED_SIDECARS[@]} > 0)); then
    orphans_json=$(printf '%s\n' "${ORPHANED_SIDECARS[@]}" | jq -R -s 'split("\n") | map(select(length > 0))')
  fi

  matrix_rel="${MATRIX_FILE#"$ROOT_DIR"/}"
  guides_json="[]"
  if ((${#GUIDE_PATHS[@]} > 0)); then
    guides_json=$(
      for i in "${!GUIDE_PATHS[@]}"; do
        printf '%s\t%s\t%s\t%s\n' "${GUIDE_PATHS[$i]}" "${GUIDE_STATES[$i]}" \
          "${GUIDE_DATES[$i]}" "${GUIDE_PLACEHOLDERS[$i]}"
      done | jq -Rn '[inputs | split("\t")] | map({
        doc: .[0], status: .[1], reviewed: .[2], placeholder_count: (.[3] | tonumber)})'
    )
  fi

  # SIDE EFFECT (write): creates a bones/tmp scratch file for stdout JSON assembly
  json_out="$TMP_DIR/dip-json-stdout.$$"
  {
    echo "{"
    printf '  "schema": "rotkeeper.dip-matrix.v1",\n'
    printf '  "generated_at": "%s",\n' "$DATE_STR"
    printf '  "matrix_file": %s,\n' "$(printf '%s' "$matrix_rel" | jq -R .)"
    printf '  "totals": {"ok": %d, "stub": %d, "missing": %d, "stale": %d, "unowned": %d, "rows": %d, "exempt": %d, "placeholders": %d, "placeholder_pages": %d},\n' \
      "${STAT_COUNTS[OK]}" "${STAT_COUNTS[Stub]}" "${STAT_COUNTS[Missing]}" "${STAT_COUNTS[Stale]}" "${STAT_COUNTS[Unowned]}" "$total_rows" \
      "${STAT_COUNTS[Exempt]}" "$PLACEHOLDER_COUNT" "$PLACEHOLDER_PAGES"
    printf '  "sidecar_coverage": {"present": %d, "missing": %d, "exempt": %d, "orphaned": %d},\n' \
      "${COVERAGE_COUNTS[present]}" "${COVERAGE_COUNTS[missing]}" "${COVERAGE_COUNTS[exempt]}" "${#ORPHANED_SIDECARS[@]}"
    printf '  "orphaned_sidecars": %s,\n' "$orphans_json"
    printf '  "staleness": {"state": "%s", "git_history": "%s", "stale": %d, "unknown": %d, "docs": %d, "sidecars": %d},\n' \
      "$stale_state" "$GIT_HISTORY" "$STALE_KNOWN" "$STALE_UNKNOWN" "$STALE_DOCS" "$STALE_SIDECARS"
    printf '  "rows": %s,\n' "$rows_json"
    printf '  "authored_guides": %s,\n' "$guides_json"
    printf '  "ownership_collisions": %s,\n' "$collisions_json"
    printf '  "obsolete_moved": %s,\n' "$obsolete_json"
    printf '  "degraded": {"autopsy_report": %s, "fsbook_catalog": %s, "help_input": %s}\n' \
      "$( [[ "$DEGRADED_AUTOPSY" == true ]] && echo true || echo false )" \
      "$( [[ "$DEGRADED_FSBOOK" == true ]] && echo true || echo false )" \
      "$( [[ "$DEGRADED_HELP" == true ]] && echo true || echo false )"
    echo "}"
  } > "$json_out"

  # Fail closed on malformed JSON rather than shipping it to CI consumers.
  if ! jq empty "$json_out" >/dev/null 2>&1; then
    log "ERROR" "dip --json generated invalid JSON; scratch copy kept at $json_out"
    cat "$json_out" >&2
    exit 1
  fi

  # SIDE EFFECT (write): appends the stdout JSON object to the per-run log
  if [[ -n "${LOG_FILE:-}" ]]; then
    cat "$json_out" >> "$LOG_FILE"
  fi
  cat "$json_out" >&3 2>/dev/null || cat "$json_out"
  # SIDE EFFECT (delete): removes the stdout JSON scratch file after emit
  rm -f "$json_out"
fi

if [[ "${DRY_RUN:-false}" == true ]]; then
  log "DRY-RUN" "Would generate DIP matrix at $MATRIX_FILE (${#MATRIX_ROWS[@]} rows)"
else
  matrix_tmp="${MATRIX_FILE}.tmp.$$"
  {
    cat <<MATRIX
---
title: "Document Improvement Project (DIP) Matrix"
date: "$DATE_STR"
template: "rotkeeper-doc.html"
---

# Document Improvement Project Matrix

This page tracks the documentation status of core project files.

OK requires populated sections and no prose placeholders, including Notes.
Fenced examples, YAML frontmatter, and HTML comments are excluded from placeholder counts.
Dates are last git commit dates, not checkout times. Staleness is unknown in shallow
repositories or without path history. Stale row totals count only known Stale statuses;
incomplete pages remain Stub even when their sources are stale.
Sidecar coverage counts targets; orphaned sidecars have no DIP, glue-directory, or render-page consumer.

| Target File | Doc Page | Last Code Edit | Last Doc Edit | Status | Placeholders | Sections | Sidecar | Staleness |
|-------------|----------|----------------|---------------|--------|--------------|----------|---------|-----------|
MATRIX
    printf '%s\n' ${MATRIX_ROWS[@]+"${MATRIX_ROWS[@]}"}
    echo ""
    echo "$totals_line"
    echo ""
    echo "**Placeholders:** $PLACEHOLDER_COUNT lines in $PLACEHOLDER_PAGES pages."
    echo ""
    echo "$coverage_line"
    echo ""
    echo "$staleness_line"
    if ((${#GUIDE_ROWS[@]} > 0)); then
      printf '\n## Authored task guides\n\n'
      printf '%s\n\n' "These pages declare \`doc_type: guide\`, have no core \`target_file\`, and are maintained by authors, not stitched as command references. Review dates and prose placeholders remain visible; declaration alone does not mean completion."
      printf '%s\n' '| Guide | Reviewed | Status | Placeholders |' '| --- | --- | --- | --- |'
      printf '%s\n' "${GUIDE_ROWS[@]}"
    fi
    if ((${#EXEMPT_TARGETS[@]} > 0)); then
      echo ""
      echo "## Target exemptions"
      echo ""
      while IFS= read -r file; do
        echo "- \`$file\`: ${EXEMPT_TARGETS[$file]}"
      done < <(printf '%s\n' "${!EXEMPT_TARGETS[@]}" | LC_ALL=C sort)
    fi
    if ((${#ORPHANED_SIDECARS[@]} > 0)); then
      echo ""
      echo "## Orphaned sidecars"
      echo ""
      printf -- "- \`%s\`\n" "${ORPHANED_SIDECARS[@]}"
      [[ "$DEGRADED_FSBOOK" != true ]] || echo "Core inventory is incomplete; these orphan findings are provisional."
    fi
    if ((${#OWNERSHIP_COLLISIONS[@]} > 0)); then
      echo ""
      echo "## Ownership collisions"
      echo ""
      for c in "${OWNERSHIP_COLLISIONS[@]}"; do
        IFS='|' read -r dpath a b <<<"$c"
        echo "- \`$dpath\`: \`$a\` vs \`$b\`"
      done
    fi
    if [[ "$DEGRADED_AUTOPSY" == true || "$DEGRADED_FSBOOK" == true || "$DEGRADED_HELP" == true ]]; then
      echo ""
      echo "## Degraded inputs"
      echo ""
      [[ "$DEGRADED_AUTOPSY" == true ]] && echo "- Autopsy report missing — artifact excludes incomplete."
      [[ "$DEGRADED_FSBOOK" == true ]] && echo "- FSBook catalog missing — core inventory incomplete; obsolete moves skipped."
      [[ "$DEGRADED_HELP" == true ]] && echo "- Help input missing (bones/reports/autopsy-help.md); command references read static help directly from scripts."
    fi
  } >"$matrix_tmp"

  # Idempotent matrix write: if only the date frontmatter would change, keep prior file.
  if [[ -f "$MATRIX_FILE" ]]; then
    old_norm=$(grep -v '^date: ' "$MATRIX_FILE" || true)
    new_norm=$(grep -v '^date: ' "$matrix_tmp" || true)
    if [[ "$old_norm" == "$new_norm" ]]; then
      # SIDE EFFECT (delete): discards the identical matrix scratch copy
      rm -f "$matrix_tmp"
      log "INFO" "DIP matrix unchanged (content identical); preserving existing file."
    else
      mv -f "$matrix_tmp" "$MATRIX_FILE"
      log "INFO" "DIP audit complete. See $MATRIX_FILE for details."
    fi
  else
    mv -f "$matrix_tmp" "$MATRIX_FILE"
    log "INFO" "DIP audit complete. See $MATRIX_FILE for details."
  fi
fi

if ((${#OWNERSHIP_COLLISIONS[@]} > 0)); then
  log "WARN" "Ownership collisions remain unresolved (see matrix / logs)."
fi

SUMMARY="DIP finished. OK=${STAT_COUNTS[OK]} Stub=${STAT_COUNTS[Stub]} Missing=${STAT_COUNTS[Missing]} Stale=$stale_state (known=$STALE_KNOWN unknown=$STALE_UNKNOWN) Unowned=${STAT_COUNTS[Unowned]} Exempt=${STAT_COUNTS[Exempt]} Placeholders=$PLACEHOLDER_COUNT Sidecars=${COVERAGE_COUNTS[present]}/${COVERAGE_COUNTS[missing]} Orphans=${#ORPHANED_SIDECARS[@]} Collisions=${#OWNERSHIP_COLLISIONS[@]} ObsoleteActions=${#OBSOLETE_MOVED[@]}"
log "INFO" "$SUMMARY"
log "MARKER" "$SUMMARY"
