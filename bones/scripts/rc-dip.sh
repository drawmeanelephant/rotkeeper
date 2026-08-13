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

show_help() {
  cat <<'HELP_EOF'
rc-dip.sh — Document Improvement Project audit

Scans documentation coverage, ownership, staleness, and obsolete
references. Reads source scripts and generated books critically.

Options:
  --dry-run      Preview actions without moving or writing docs
  --verbose      Detailed output
  --quiet        Suppress informational output
  --help, -h     Show help
  --version, -v  Show version and quit
HELP_EOF
}

rk_init_script rc-dip "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR CONTENT_DIR DOCS_DIR REPORT_DIR BOOK_REPORT_DIR META_DIR

# Surface dry-run actions even when QUIET defaults true
if [[ "${DRY_RUN:-false}" == true ]]; then
  QUIET=false
fi

OBSOLETE_DIR="${ROOT_DIR}/home/obsolete/docs"
MATRIX_FILE="${DOCS_DIR}/dip-matrix.md"
DATE_STR=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
DEGRADED_AUTOPSY=false
DEGRADED_FSBOOK=false

# --- helpers ---------------------------------------------------------------

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
  local doc="$1"
  awk '
    BEGIN { in_fm=0 }
    NR==1 && /^---[[:space:]]*$/ { in_fm=1; next }
    in_fm && /^---[[:space:]]*$/ { exit }
    in_fm && /^target_file:[[:space:]]*/ {
      sub(/^target_file:[[:space:]]*/, "")
      gsub(/^["'\'']|["'\'']$/, "")
      gsub(/[[:space:]]+$/, "")
      print
      exit
    }
  ' "$doc"
}

# Extract status frontmatter value.
read_status_field() {
  local doc="$1"
  awk '
    BEGIN { in_fm=0 }
    NR==1 && /^---[[:space:]]*$/ { in_fm=1; next }
    in_fm && /^---[[:space:]]*$/ { exit }
    in_fm && /^status:[[:space:]]*/ {
      sub(/^status:[[:space:]]*/, "")
      gsub(/^["'\'']|["'\'']$/, "")
      gsub(/[[:space:]]+$/, "")
      print
      exit
    }
  ' "$doc"
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

  awk '
    function is_header(line) {
      return line ~ /^##[[:space:]]+Environment([[:space:]]|$)/ \
          || line ~ /^##[[:space:]]+Ritual[[:space:]]+History/ \
          || line ~ /^##[[:space:]]+Necromancer/ \
          || line ~ /^######[[:space:]]+CLI[[:space:]]+Usage/ \
          || line ~ /^##[[:space:]]+Overview([[:space:]]|$)/
    }
    function real_boundary(i, j) {
      if (!is_header(lines[i])) return 0
      j=i+1
      while (j<=count && lines[j] ~ /^[[:space:]]*$/) j++
      return j<=count && lines[j] ~ /^<!-- DIP-[A-Z0-9-]+-EXTRACTED:/
    }
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
  rm -f "$content_file"
  mv -f "$tmp_file" "$doc_path"
}

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
AUTOPSY_EXCLUDES["home/content"]=1
AUTOPSY_EXCLUDES["home/assets"]=1
AUTOPSY_EXCLUDES["tmp"]=1
AUTOPSY_EXCLUDES["output"]=1
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
      # Skip markdown/textile tombs themselves (docs are outputs of DIP, not cores)
      if [[ "$file_path" =~ \.(md|textile)$ ]]; then
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
  while IFS= read -r -d '' soul_path; do
    rel_meta_path="${soul_path#"$META_DIR"/}"
    target_origin="${rel_meta_path%.soul.md}"
    SOUL_TARGETS["$target_origin"]="$soul_path"
  done < <(find "$META_DIR" -type f -name "*.soul.md" -print0 2>/dev/null || true)
fi

# --- 3. Obsolete-document handling -----------------------------------------

log "INFO" "Checking for obsolete docs..."
mapfile -d '' EXISTING_DOCS < <(find "$DOCS_DIR" -type f \( -name "*.md" -o -name "*.textile" \) -print0 2>/dev/null || true)

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

build_help_content() {
  local target_script="$1"
  local help_report="$REPORT_DIR/autopsy-help.md"
  local script_name help_content

  script_name=$(basename -- "$target_script")
  if [[ ! -f "$help_report" ]]; then
    printf '%s\n' "*Not found: autopsy help report missing (\`$(rel_path "$help_report")\`). Run: ./rotkeeper.sh autopsy --help-report*"
    return 0
  fi

  help_content=$(sed -n "/^## ${script_name}\$/,/^## /{ /^## /d; p; }" "$help_report" 2>/dev/null \
    | sed -e '1{/^$/d;}' -e '${/^$/d;}' || true)

  if [[ -z "${help_content//[[:space:]]/}" ]]; then
    printf '%s\n' "*Not found: no help block for \`$script_name\` in autopsy help report.*"
  else
    printf '%s\n' "$help_content"
  fi
}

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
      soulbody=$(sed "1{/^---$/!q;}; 1,/^---$/d" "$sidecar")
    fi
  fi
  # Sidecars can themselves have been stitched.  Strip only the recursive
  # generated tail, retaining all authored prose before that marker.
  if [[ "$soulbody" == *"<!-- DIP-"* ]]; then
    soulbody=$(printf '%s\n' "$soulbody" | awk '
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

# --- 4. Stub missing docs --------------------------------------------------

log "INFO" "Checking for missing docs..."
for doc_path in "${!EXPECTED_DOCS[@]}"; do
  target_file="${EXPECTED_DOCS[$doc_path]}"
  rel_expected="${doc_path#"$ROOT_DIR"/}"
  if [[ "$doc_path" != "$DOCS_DIR"/* ]] || ! path_stays_under "$ROOT_DIR" "$rel_expected"; then
    log "ERROR" "Refusing unsafe generated doc path outside ROOT_DIR/DOCS_DIR: $doc_path"
    continue
  fi
  if [[ -f "$doc_path" ]]; then
    continue
  fi

  if [[ "${DRY_RUN:-false}" == true ]]; then
    log "DRY-RUN" "Would stub missing doc: $doc_path (target_file=$target_file)"
    continue
  fi

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
done

  total_rows=$((${STAT_COUNTS[OK]:-0} + ${STAT_COUNTS[Stub]:-0} + ${STAT_COUNTS[Missing]:-0} + ${STAT_COUNTS[Stale]:-0} + ${STAT_COUNTS[Unowned]:-0}))
totals_line="**Totals:** OK: ${STAT_COUNTS[OK]:-0} | Stub: ${STAT_COUNTS[Stub]:-0} | Missing: ${STAT_COUNTS[Missing]:-0} | Stale: ${STAT_COUNTS[Stale]:-0} | Unowned: ${STAT_COUNTS[Unowned]:-0} | Rows: ${total_rows}"

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
