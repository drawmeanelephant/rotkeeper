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
# Input/Output contracts: CLI args and env vars in; files and stdout/stderr out; respects --dry-run (no writes) and --verbose.
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
#  - stub      : generated doc still carrying TODO placeholders / status stub
#  - stale     : code mtime newer than doc mtime
#  - obsolete  : generated reference whose target_file is no longer a core
#                file — moved only with strong evidence (explicit target_file)
#  - unowned   : present under DOCS_DIR with uncertain ownership; reported,
#                never silently discarded
# ============================================================


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }

# ---
# show_help: Display DIP audit usage.
# Inputs: none
# Outputs: Prints help to stdout
# Env: Reads BONES_DIR, BOOK_REPORT_DIR, CONFIG_DIR, CONTENT_DIR, DOCS_DIR, DRY_RUN ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
show_help() {
  cat <<'HELP_EOF'
rc-dip.sh — Document Improvement Project audit

Usage:
  rotkeeper.sh dip [options]

Description:
  Scans documentation coverage, ownership, staleness, and obsolete
  references; publishes the dip-matrix report. Reads source scripts
  and generated books critically. Moves an obsolete doc only with
  strong evidence; ambiguous docs are reported as unowned.

Options:
  --dry-run      Preview actions without moving or writing docs
  --verbose      Detailed output
  --quiet        Suppress informational output
  --json         Emit a machine-readable DIP matrix JSON on stdout
  --help, -h     Show help
  --version, -v  Show version and quit

Examples:
  bash rotkeeper.sh dip --dry-run     Audit without moving or writing docs
  bash rotkeeper.sh dip               Full audit and matrix publication
  bash rotkeeper.sh dip --json | jq . Machine-readable matrix output

Exit codes:
  0         Audit completed (findings live in the matrix report)
  nonzero   Audit could not complete
HELP_EOF
}

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

# --- helpers ---------------------------------------------------------------

# ---
# get_fs_date: Format file mtime as YYYY-MM-DD (UTC) or Missing.
# Inputs: $1 (file path)
# Outputs: Prints date string
# Env: Reads BONES_DIR, DRY_RUN, QUIET, ROOT_DIR, VERBOSE (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
get_fs_date() {
  local file=$1
  if [[ -f "$file" ]]; then
    if stat --version >/dev/null 2>&1; then
      date -u -d "@$(stat -c %Y "$file")" "+%Y-%m-%d"
    else
      TZ=UTC stat -f "%Sm" -t "%Y-%m-%d" "$file"
    fi
  else
    echo "Missing"
  fi
}

# ---
# get_fs_iso: Format file mtime as ISO-8601 UTC or zero-date.
# Inputs: $1 (file path)
# Outputs: Prints ISO timestamp
# Env: No env vars (pure args/stdin)
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
get_fs_iso() {
  local file=$1
  if [[ -f "$file" ]]; then
    if stat --version >/dev/null 2>&1; then
      date -u -d "@$(stat -c %Y "$file")" "+%Y-%m-%dT%H:%M:%SZ"
    else
      TZ=UTC stat -f "%Sm" -t "%Y-%m-%dT%H:%M:%SZ" "$file"
    fi
  else
    echo "0000-00-00T00:00:00Z"
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

# Count TODO: lines outside fenced code blocks.
count_todo_lines() {
  local doc="$1"
  awk '
    BEGIN { fence=0; soul=0; c=0 }
    /^```/ { fence = !fence; next }
    /^##[[:space:]]+Necromancer/ { soul=1; next }
    soul && /^##[[:space:]]+/ { soul=0 }
    !fence && !soul && !/^>[[:space:]]*TODO:/ && /^TODO:/ { c++ }
    END { print c+0 }
  ' "$doc"
}

# True if line is a DIP pillar section boundary (not generic ## — soul bodies use those).
is_dip_section_header_line() {
  [[ "$1" =~ ^##[[:space:]]+Environment([[:space:]]|$) ]] \
    || [[ "$1" =~ ^##[[:space:]]+Ritual[[:space:]]+History ]] \
    || [[ "$1" =~ ^##[[:space:]]+Necromancer ]] \
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
    DIP-ENV-EXTRACTED) echo '^##[[:space:]]+Environment([[:space:]]|$)' ;;
    DIP-HELP-EXTRACTED) echo '^######[[:space:]]+CLI[[:space:]]+Usage' ;;
    DIP-HISTORY-EXTRACTED) echo '^##[[:space:]]+Ritual[[:space:]]+History' ;;
    DIP-SOUL-EXTRACTED) echo '^##[[:space:]]+Necromancer' ;;
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
mapfile -d '' EXISTING_DOCS < <(rk_find_content "$DOCS_DIR" md textile cook)

declare -A WHITELIST=()
WHITELIST_FILE="$CONFIG_DIR/dip-whitelist.txt"
if [[ -f "$WHITELIST_FILE" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    line=$(printf '%s\n' "$line" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//')
    [[ -z "$line" ]] && continue
    WHITELIST["$ROOT_DIR/$line"]=1
  done <"$WHITELIST_FILE"
fi

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

# In degraded fsbook mode, refuse obsolete moves (inventory incomplete).
for doc in ${EXISTING_DOCS[@]+"${EXISTING_DOCS[@]}"}; do
  [[ "$doc" == "$MATRIX_FILE" ]] && continue
  [[ -n "${WHITELIST[$doc]:-}" ]] && continue

  target_file_check=""
  if grep -q '^target_file:' "$doc" 2>/dev/null; then
    target_file_check=$(read_target_file "$doc" || true)
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
    log "ERROR" "Refuse obsolete move — doc not under DOCS_DIR: $doc"
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
# build_env_list: Render environment variable bullet list for stitching.
# Inputs: none; reads ROOT_DIR and derived env vars
# Outputs: Prints markdown list
# Env: Reads ARCHIVE_DIR, ASSETS_DIR, BONES_DIR, BOOK_REPORT_DIR, CONFIG_DIR, CONTENT_DIR ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
build_env_list() {
  cat <<INNER_EOF
- **\$ROOT_DIR**: $(rel_path "$ROOT_DIR")
- **\$OUTPUT_DIR**: $(rel_path "${OUTPUT_DIR:-}")
- **\$CONTENT_DIR**: $(rel_path "$CONTENT_DIR")
- **\$ASSETS_DIR**: $(rel_path "${ASSETS_DIR:-}")
- **\$DOCS_DIR**: $(rel_path "$DOCS_DIR")
- **\$HELP_DIR**: $(rel_path "${HELP_DIR:-}")
- **\$BONES_DIR**: $(rel_path "$BONES_DIR")
- **\$SCRIPT_DIR**: $(rel_path "$SCRIPT_DIR")
- **\$CONFIG_DIR**: $(rel_path "$CONFIG_DIR")
- **\$LOG_DIR**: $(rel_path "$LOG_DIR")
- **\$TMP_DIR**: $(rel_path "$TMP_DIR")
- **\$ARCHIVE_DIR**: $(rel_path "${ARCHIVE_DIR:-}")
- **\$REPORT_DIR**: $(rel_path "$REPORT_DIR")
- **\$BOOK_REPORT_DIR**: $(rel_path "$BOOK_REPORT_DIR")
- **\$TEMPLATE_DIR**: $(rel_path "${TEMPLATE_DIR:-}")
- **\$META_DIR**: $(rel_path "$META_DIR")
- **\$WEB_DIR**: $(rel_path "${WEB_DIR:-}")
INNER_EOF
}

# ---
# build_help_content: Extract help block for a script from autopsy-help.md.
# Inputs: $1 (target script path)
# Outputs: Prints help markdown or Not-found placeholder
# Env: Reads BONES_DIR, DOCS_DIR, DRY_RUN, QUIET, REPORT_DIR, ROOT_DIR ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
build_help_content() {
  local target_script="$1"
  local help_report="$REPORT_DIR/autopsy-help.md"
  local script_name help_content

  script_name=$(basename -- "$target_script")
  if [[ ! -f "$help_report" ]]; then
    printf '%s\n' "*Not found: autopsy help report missing (\`$(rel_path "$help_report")\`). Run: ./rotkeeper.sh autopsy --help-report*"
    return 0
  fi

  # sed range extracts the ## <script> section; second sed trims leading/trailing blank lines
  help_content=$(sed -n "/^## ${script_name}\$/,/^## /{ /^## /d; p; }" "$help_report" 2>/dev/null \
    | sed -e '1{/^$/d;}' -e '${/^$/d;}' || true)

  if [[ -z "${help_content//[[:space:]]/}" ]]; then
    printf '%s\n' "*Not found: no help block for \`$script_name\` in autopsy help report.*"
  else
    printf '%s\n' "$help_content"
  fi
}

# ---
# build_history_content: Search CHANGELOG and road-to-bones for script history.
# Inputs: $1 (script basename)
# Outputs: Prints bullet list or Not-found placeholder
# Env: Reads BONES_DIR, DOCS_DIR, DRY_RUN, QUIET, ROOT_DIR, VERBOSE (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
build_history_content() {
  local script_name="$1"
  local history_content="" matches
  local log_file

  for log_file in "$ROOT_DIR/CHANGELOG.md" "$DOCS_DIR/road-to-bones/index.md"; do
    if [[ -f "$log_file" ]]; then
      matches=$(grep -i -- "$script_name" "$log_file" | sed 's/^/- /' || true)
      if [[ -n "$matches" ]]; then
        history_content+="$matches"$'\n'
      fi
    fi
  done
  history_content=$(printf '%s' "$history_content" | grep -v '^$' || true)
  if [[ -z "${history_content//[[:space:]]/}" ]]; then
    printf '%s\n' "*Not found: no changelog/history entries matching \`$script_name\`.*"
  else
    printf '%s\n' "$history_content"
  fi
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
        if (stop>0 && lines[stop] ~ /^##[[:space:]]+Necromancer/) stop--
        while (stop>0 && lines[stop] ~ /^[[:space:]]*$/) stop--
        for (i=1; i<=stop; i++) print lines[i]
      }
    ')
  fi
  if [[ -z "${soulbody//[[:space:]]/}" ]]; then
    printf '%s\n' "*Not found: no soul sidecar for \`$target_file\`.*"
  else
    printf '%s\n' "$soulbody"
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
        append+=$'\n## Environment\n<!-- DIP-ENV-EXTRACTED: 0000-00-00T00:00:00Z -->\n*Not found: environment not yet stitched.*\n'
        ;;
      help)
        append+=$'\n###### CLI Usage\n<!-- DIP-HELP-EXTRACTED: 0000-00-00T00:00:00Z -->\n*Not found: help not yet stitched.*\n'
        ;;
      history)
        append+=$'\n## Ritual History\n<!-- DIP-HISTORY-EXTRACTED: 0000-00-00T00:00:00Z -->\n*Not found: history not yet stitched.*\n'
        ;;
      soul)
        append+=$'\n## Necromancer'\''s Notes\n<!-- DIP-SOUL-EXTRACTED: 0000-00-00T00:00:00Z -->\n*Not found: soul not yet stitched.*\n'
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

# --- 4. Stub missing or empty docs ------------------------------------------
#  Stub policy (#241): a doc page is stub-eligible only when it does not exist
#  or carries no content at all (whitespace-only counts as empty). Any
#  non-empty file is treated as authored/generated content and is never
#  overwritten here; stub-marked docs are updated by pillar stitching instead.

log "INFO" "Checking for missing docs..."
for doc_path in "${!EXPECTED_DOCS[@]}"; do
  target_file="${EXPECTED_DOCS[$doc_path]}"
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

###### CLI Usage
<!-- DIP-HELP-EXTRACTED: 0000-00-00T00:00:00Z -->
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
  mv -f "$stub_tmp" "$doc_path"
  log "INFO" "Stubbed missing doc: $doc_path"
done

# --- 5. Stitch Frankenstein pillars ----------------------------------------

log "INFO" "Stitching dynamic content into Frankenstein pillars..."

ENV_LIST_CONTENT=$(build_env_list)

for doc_path in "${!EXPECTED_DOCS[@]}"; do
  [[ -f "$doc_path" ]] || continue
  rel_expected="${doc_path#"$ROOT_DIR"/}"
  if [[ "$doc_path" != "$DOCS_DIR"/* ]] || ! path_stays_under "$ROOT_DIR" "$rel_expected"; then
    log "ERROR" "Refusing unsafe generated doc path outside ROOT_DIR/DOCS_DIR: $doc_path"
    continue
  fi
  target_file="${EXPECTED_DOCS[$doc_path]}"
  script_name=$(basename -- "$target_file")

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

  help_content=$(build_help_content "$target_file")
  history_content=$(build_history_content "$script_name")
  soul_content=$(build_soul_content "$target_file")

  stitch_pillar "$doc_path" "DIP-ENV-EXTRACTED" "$ENV_LIST_CONTENT"
  stitch_pillar "$doc_path" "DIP-HELP-EXTRACTED" "$help_content"
  stitch_pillar "$doc_path" "DIP-HISTORY-EXTRACTED" "$history_content"
  stitch_pillar "$doc_path" "DIP-SOUL-EXTRACTED" "$soul_content"
done

# --- 6. Matrix generation --------------------------------------------------

log "INFO" "Generating DIP Matrix at $MATRIX_FILE..."

declare -A STAT_COUNTS=(
  ["OK"]=0
  ["Stub"]=0
  ["Missing"]=0
  ["Stale"]=0
  ["Unowned"]=0
)

declare -a MATRIX_ROWS=()

# Parallel row capture for --json emission (order mirrors MATRIX_ROWS)
declare -a J_TARGETS=() J_DOCS=() J_CODE_DATES=() J_DOC_DATES=() J_STATUSES=()

# Stable iteration for deterministic matrix output
mapfile -t SORTED_DOC_PATHS < <(printf '%s\n' "${!EXPECTED_DOCS[@]}" | LC_ALL=C sort)

for doc_path in ${SORTED_DOC_PATHS[@]+"${SORTED_DOC_PATHS[@]}"}; do
  target_file="${EXPECTED_DOCS[$doc_path]}"
  status="Missing"
  base_stat="Missing"

  if [[ -f "$doc_path" ]]; then
    status=$(read_status_field "$doc_path" || true)
    [[ -z "$status" ]] && status="unknown"

    # Normalize known status labels
    case "${status,,}" in
      stub) status="Stub"; base_stat="Stub" ;;
      missing) status="Missing"; base_stat="Missing" ;;
      stale) status="Stale"; base_stat="Stale" ;;
      complete|ok) status="OK"; base_stat="OK" ;;
      *)
        # Heuristic: still a stub if DIP placeholders remain
        if grep -qE '^TODO: (Provide a brief overview|Stitch )' "$doc_path" 2>/dev/null \
          || grep -q 'status: "stub"' "$doc_path" 2>/dev/null \
          || grep -q '^status: stub' "$doc_path" 2>/dev/null; then
          status="Stub"
          base_stat="Stub"
        else
          status="OK"
          base_stat="OK"
        fi
        ;;
    esac

    code_date=$(get_fs_date "$ROOT_DIR/$target_file")
    doc_date=$(get_fs_date "$doc_path")

    if [[ "$code_date" != "Missing" && "$doc_date" != "Missing" && "$code_date" > "$doc_date" ]]; then
      status="Stale"
      base_stat="Stale"
    fi

    if [[ "$base_stat" == "OK" ]]; then
      todo_count=$(count_todo_lines "$doc_path")
      if [[ "$todo_count" -gt 0 ]]; then
        status="OK, ${todo_count} TODOs remain"
        base_stat="OK"
      fi
    fi
  else
    code_date=$(get_fs_date "$ROOT_DIR/$target_file")
    doc_date="Missing"
    status="Missing"
    base_stat="Missing"
  fi

  STAT_COUNTS["$base_stat"]=$((${STAT_COUNTS[$base_stat]:-0} + 1))
  rel_doc="${doc_path#"$DOCS_DIR"/}"
  if [[ "$base_stat" == "Missing" ]]; then
    doc_ref="\`$rel_doc\`"
  else
    doc_ref="[$rel_doc]($rel_doc)"
  fi
  MATRIX_ROWS+=("| \`$target_file\` | $doc_ref | $code_date | $doc_date | $status |")
  J_TARGETS+=("$target_file")
  J_DOCS+=("$rel_doc")
  J_CODE_DATES+=("$code_date")
  J_DOC_DATES+=("$doc_date")
  J_STATUSES+=("$status")
done

if ((${#UNOWNED_DOCS[@]} > 0)); then
  mapfile -t SORTED_UNOWNED < <(printf '%s\n' ${UNOWNED_DOCS[@]+"${UNOWNED_DOCS[@]}"} | LC_ALL=C sort -u)
else
  mapfile -t SORTED_UNOWNED < /dev/null
fi
for doc_path in ${SORTED_UNOWNED[@]+"${SORTED_UNOWNED[@]}"}; do
  rel_doc="${doc_path#"$DOCS_DIR"/}"
  doc_date=$(get_fs_date "$doc_path")
  status="Unowned"
  STAT_COUNTS["Unowned"]=$((STAT_COUNTS["Unowned"] + 1))
  MATRIX_ROWS+=("| \`Unknown\` | [$rel_doc]($rel_doc) | Missing | $doc_date | $status |")
  J_TARGETS+=("Unknown")
  J_DOCS+=("$rel_doc")
  J_CODE_DATES+=("Missing")
  J_DOC_DATES+=("$doc_date")
  J_STATUSES+=("$status")
done

  total_rows=$((${STAT_COUNTS[OK]:-0} + ${STAT_COUNTS[Stub]:-0} + ${STAT_COUNTS[Missing]:-0} + ${STAT_COUNTS[Stale]:-0} + ${STAT_COUNTS[Unowned]:-0}))
totals_line="**Totals:** OK: ${STAT_COUNTS[OK]:-0} | Stub: ${STAT_COUNTS[Stub]:-0} | Missing: ${STAT_COUNTS[Missing]:-0} | Stale: ${STAT_COUNTS[Stale]:-0} | Unowned: ${STAT_COUNTS[Unowned]:-0} | Rows: ${total_rows}"

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
        printf '%s\t%s\t%s\t%s\t%s\n' \
          "${J_TARGETS[$i]}" "${J_DOCS[$i]}" "${J_CODE_DATES[$i]}" "${J_DOC_DATES[$i]}" "${J_STATUSES[$i]}"
      done | jq -Rn '
        [inputs | select(length > 0) | split("\t")]
        | map({target_file: .[0], doc: .[1], last_code_edit: .[2], last_doc_edit: .[3], status: .[4]})
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

  matrix_rel="${MATRIX_FILE#"$ROOT_DIR"/}"

  # SIDE EFFECT (write): creates a bones/tmp scratch file for stdout JSON assembly
  json_out="$TMP_DIR/dip-json-stdout.$$"
  {
    echo "{"
    printf '  "schema": "rotkeeper.dip-matrix.v1",\n'
    printf '  "generated_at": "%s",\n' "$DATE_STR"
    printf '  "matrix_file": %s,\n' "$(printf '%s' "$matrix_rel" | jq -R .)"
    printf '  "totals": {"ok": %d, "stub": %d, "missing": %d, "stale": %d, "unowned": %d, "rows": %d},\n' \
      "${STAT_COUNTS[OK]:-0}" "${STAT_COUNTS[Stub]:-0}" "${STAT_COUNTS[Missing]:-0}" "${STAT_COUNTS[Stale]:-0}" "${STAT_COUNTS[Unowned]:-0}" "$total_rows"
    printf '  "rows": %s,\n' "$rows_json"
    printf '  "ownership_collisions": %s,\n' "$collisions_json"
    printf '  "obsolete_moved": %s,\n' "$obsolete_json"
    printf '  "degraded": {"autopsy_report": %s, "fsbook_catalog": %s}\n' \
      "$( [[ "$DEGRADED_AUTOPSY" == true ]] && echo true || echo false )" \
      "$( [[ "$DEGRADED_FSBOOK" == true ]] && echo true || echo false )"
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

| Target File | Doc Page | Last Code Edit | Last Doc Edit | Status |
|-------------|----------|----------------|---------------|--------|
MATRIX
    printf '%s\n' ${MATRIX_ROWS[@]+"${MATRIX_ROWS[@]}"}
    echo ""
    echo "$totals_line"
    if ((${#OWNERSHIP_COLLISIONS[@]} > 0)); then
      echo ""
      echo "## Ownership collisions"
      echo ""
      for c in "${OWNERSHIP_COLLISIONS[@]}"; do
        IFS='|' read -r dpath a b <<<"$c"
        echo "- \`$dpath\`: \`$a\` vs \`$b\`"
      done
    fi
    if [[ "$DEGRADED_AUTOPSY" == true || "$DEGRADED_FSBOOK" == true ]]; then
      echo ""
      echo "## Degraded inputs"
      echo ""
      [[ "$DEGRADED_AUTOPSY" == true ]] && echo "- Autopsy report missing — artifact excludes incomplete."
      [[ "$DEGRADED_FSBOOK" == true ]] && echo "- FSBook catalog missing — core inventory incomplete; obsolete moves skipped."
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

SUMMARY="DIP finished. OK=${STAT_COUNTS[OK]:-0} Stub=${STAT_COUNTS[Stub]:-0} Missing=${STAT_COUNTS[Missing]:-0} Stale=${STAT_COUNTS[Stale]:-0} Unowned=${STAT_COUNTS[Unowned]:-0} Collisions=${#OWNERSHIP_COLLISIONS[@]} ObsoleteActions=${#OBSOLETE_MOVED[@]}"
log "INFO" "$SUMMARY"
log "MARKER" "$SUMMARY"
