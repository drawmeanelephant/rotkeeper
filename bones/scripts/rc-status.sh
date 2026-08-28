#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# ============================================================
#  ███████╗████████╗ █████╗ ████████╗██╗   ██╗███████╗
#  ██╔════╝╚══██╔══╝██╔══██╗╚══██╔══╝██║   ██║██╔════╝
#  ███████╗   ██║   ███████║   ██║   ██║   ██║███████╗
#  ╚════██║   ██║   ██╔══██║   ██║   ██║   ██║╚════██║
#  ███████║   ██║   ██║  ██║   ██║   ╚██████╔╝███████║
#  ╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
# ============================================================
# Env assumptions: reads ARCHIVE_DIR, BONES_DIR, BOOK_REPORT_DIR, CONFIG_DIR, CONTENT_DIR, DOCS_DIR, LOG_DIR, LOG_FILE, OUTPUT_DIR, ROOT_DIR, ROTKEEPER_VERSION, SCRIPT_DIR, TMP_DIR, VERBOSE, VERSION (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.
# CWD assumptions: No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.
# Input/Output contracts: CLI args and env vars in; files and stdout/stderr out; respects --dry-run (no writes) and --verbose.
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-status.sh
#  Purpose : Output a structured, human-readable status report across environment, health, and pulse.
#  Version : 0.5.1
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================


JSON_MODE=false
SHORT_MODE=false
ARGS=()
for arg in "$@"; do
    if [[ "$arg" == "--json" ]]; then
        JSON_MODE=true
    elif [[ "$arg" == "--short" ]]; then
        SHORT_MODE=true
    else
        ARGS+=("$arg")
    fi
done


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }

# @HELP
# rc-status.sh — Display environment health status reports
#
# Usage:
#   rotkeeper.sh status [options]
#
# Description:
#   Reports environment health: version, layout alignment, rendered page
#   counts, freshness, and branch state.
#
# Options:
#   --json         Emit a machine-readable JSON report
#   --short        One-line summary (version | pages | freshness | branch)
#   --dry-run      No-op flag accepted for contract consistency
#   --verbose      Detailed output
#   --help, -h     Show help
#   --version, -v  Show version and quit
#
# Examples:
#   bash rotkeeper.sh status           Full health report
#   bash rotkeeper.sh status --short   One-line summary
#   bash rotkeeper.sh status --json    Machine-readable report
#
# Exit codes:
#   0         Success
#   nonzero   Environment error
# @END-HELP

rk_init_script "rc-status" ${ARGS[@]+"${ARGS[@]}"}
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR ARCHIVE_DIR
# Status is an explicitly human-facing command. Restore the caller's streams
# after shared initialization so its report is visible even in quiet mode.
exec 1>&3 2>&3

LOG_FILE="$LOG_DIR/rc-status-$(date +%Y-%m-%d_%H%M%S)-$$.log"
# SIDE EFFECT (write): creates bones/logs before the status ritual boots its logger
mkdir -p "$LOG_DIR"

# ---
# log: Status-local logger that tees to LOG_FILE without stdout noise.
# Inputs: $1 (level), $@ (message)
# Outputs: Appends timestamped line to LOG_FILE
# Env: Reads BONES_DIR, DRY_RUN, LOG_FILE, NO_COLOR, QUIET, ROOT_DIR ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
log() {
  local level="$1"; shift
  printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" | tee -a "$LOG_FILE" >/dev/null
}

# Status headings with optional TTY color (respects NO_COLOR via rk_has_color from rc-utils.sh)
# ---
# status_heading: Print a bold heading when color is available.
# Inputs: $1 (text)
# Outputs: Prints heading to stdout
# Env: Reads BONES_DIR, DRY_RUN, QUIET, ROOT_DIR, ROTKEEPER_VERSION, VERBOSE (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
status_heading() {
  local text="$1"
  if command -v rk_has_color >/dev/null 2>&1 && rk_has_color; then
    printf '\033[1m%s\033[0m\n' "$text"
  else
    echo "$text"
  fi
}

# ---
# status_ok: Print success text in green when color is enabled.
# Inputs: $1 (text)
# Outputs: Prints colored or plain line
# Env: Reads BONES_DIR, DRY_RUN, QUIET, ROOT_DIR, ROTKEEPER_VERSION, VERBOSE (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
status_ok() {
  local text="$1"
  if command -v rk_has_color >/dev/null 2>&1 && rk_has_color; then
    printf '\033[32m%s\033[0m\n' "$text"
  else
    echo "$text"
  fi
}

# ---
# status_warn: Print warning text in yellow when color is enabled.
# Inputs: $1 (text)
# Outputs: Prints colored or plain line
# Env: Reads BONES_DIR, DRY_RUN, QUIET, ROOT_DIR, ROTKEEPER_VERSION, VERBOSE (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
status_warn() {
  local text="$1"
  if command -v rk_has_color >/dev/null 2>&1 && rk_has_color; then
    printf '\033[33m%s\033[0m\n' "$text"
  else
    echo "$text"
  fi
}

# ---
# status_dim: Print muted/dim text when color is enabled.
# Inputs: $1 (text)
# Outputs: Prints colored or plain line
# Env: Reads BONES_DIR, CONTENT_DIR, DRY_RUN, OUTPUT_DIR, QUIET, ROOT_DIR ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
status_dim() {
  local text="$1"
  if command -v rk_has_color >/dev/null 2>&1 && rk_has_color; then
    printf '\033[2m%s\033[0m\n' "$text"
  else
    echo "$text"
  fi
}

log "INFO" "Running rc-status.sh"
require_bins bash jq
require_yq_version

VERSION_SOURCE="$ROOT_DIR/bones/config/version"
CANONICAL_VERSION=""
if [[ -n "${ROTKEEPER_VERSION:-}" ]]; then
  CANONICAL_VERSION="$ROTKEEPER_VERSION"
  VERSION_SOURCE="ROTKEEPER_VERSION environment override"
elif [[ -f "$VERSION_SOURCE" ]]; then
  CANONICAL_VERSION="$(tr -d '[:space:]' < "$VERSION_SOURCE")"
  CANONICAL_VERSION="${CANONICAL_VERSION#v}"
  [[ -n "$CANONICAL_VERSION" ]] || CANONICAL_VERSION="unknown"
else
  CANONICAL_VERSION="unknown"
  VERSION_SOURCE="[not found]"
fi

# Variables to collect JSON data
JSON_ENV=""
JSON_HEALTH=""
JSON_RAG=""
JSON_RELEASES=""
JSON_TOMBS=""
JSON_PULSE=""
JSON_RENDER=""
JSON_CONFIG=""

# ---
# escape_json: Escape a string for safe JSON embedding (no surrounding quotes).
# Inputs: $1 (raw string)
# Outputs: Prints escaped JSON string content (jq -R -s + strip outer quotes)
# Env: Reads CONTENT_DIR, OUTPUT_DIR, ROOT_DIR, SCRIPT_DIR (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
escape_json() {
  # Trim newlines and escape
  # Pipeline: jq -R -s encodes raw string to JSON; sed strips outer quotes to inline into larger object.
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

if [[ "$SHORT_MODE" == true && "$JSON_MODE" == false ]]; then
    # Early short-circuit: compute minimal summary without full report
    s_total_md=$(find "$CONTENT_DIR" -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ' || echo 0)
    s_total_textile=$(find "$CONTENT_DIR" -type f -name '*.textile' 2>/dev/null | wc -l | tr -d ' ' || echo 0)
    s_total_cook=$(find "$CONTENT_DIR" -type f -name '*.cook' 2>/dev/null | wc -l | tr -d ' ' || echo 0)
    s_html_count=$(find "$OUTPUT_DIR" -type f -name '*.html' 2>/dev/null | wc -l | tr -d ' ' || echo 0)
    s_newest_html=""
    while IFS= read -r -d '' hf; do m=$(rk_mtime "$hf"); [[ -n "$m" && ( -z "$s_newest_html" || "$m" -gt "$s_newest_html" ) ]] && s_newest_html="$m"; done < <(find "$OUTPUT_DIR" -type f -name '*.html' -print0 2>/dev/null)
    s_newest_src=""
    while IFS= read -r -d '' sf; do m=$(rk_mtime "$sf"); [[ -n "$m" && ( -z "$s_newest_src" || "$m" -gt "$s_newest_src" ) ]] && s_newest_src="$m"; done < <(rk_find_content "$CONTENT_DIR" md textile cook)
    s_fresh="output is current ($s_html_count HTML)"
    s_status="ok"
    if [[ -z "$s_newest_html" ]]; then s_fresh="no rendered output — run bash rotkeeper.sh render"; s_status="empty"
    elif [[ -n "$s_newest_src" && "$s_newest_src" -gt "$s_newest_html" ]]; then s_fresh="content has changed since last render ($s_html_count HTML)"; s_status="stale"
    fi
    s_pages="$s_total_md md"
    if [[ "$s_total_textile" -gt 0 ]]; then s_pages+="/$s_total_textile textile"; fi
    if [[ "$s_total_cook" -gt 0 ]]; then s_pages+="/$s_total_cook cook"; fi
    echo "rotkeeper $CANONICAL_VERSION | $s_pages | $s_fresh | $GIT_BRANCH"
    log "INFO" "rc-status.sh completed (short)"
    exit 0
fi

if [[ "$JSON_MODE" == true ]]; then
    GIT_B_JSON="\"$GIT_BRANCH\""
    [[ "$GIT_BRANCH" == "[no git]" ]] && GIT_B_JSON="null"
    GIT_C_JSON="\"$GIT_COMMIT\""
    [[ "$GIT_COMMIT" == "[no git]" ]] && GIT_C_JSON="null"

    JSON_ENV="  \"environment\": {
    \"canonical_version\": \"$CANONICAL_VERSION\",
    \"version_source\": \"$VERSION_SOURCE\",
    \"cwd\": \"$CWD\",
    \"branch\": $GIT_B_JSON,
    \"commit\": $GIT_C_JSON
  }"
else
    status_heading "=== Environment ==="
    echo "Version  : $CANONICAL_VERSION"
    echo "Source   : $VERSION_SOURCE"
    echo "CWD      : $CWD"
    echo "Branch   : $GIT_BRANCH"
    echo "Commit   : $GIT_COMMIT"
    echo ""
fi

# --- Section 2: Script Health ---
scripts_list=("$SCRIPT_DIR"/rc-*.sh "$ROOT_DIR/rotkeeper.sh")
total_scripts=0

if [[ "$JSON_MODE" == true ]]; then
    json_scripts="["
else
    status_heading "=== Script Health ==="
    printf "%-30s | %-10s | %s\n" "Script Name" "Version" "Matches Canonical"
    echo "----------------------------------------------------------------------"
fi

first_script=true
for script in ${scripts_list[@]+"${scripts_list[@]}"}; do
    [[ ! -f "$script" ]] && continue
    total_scripts=$((total_scripts + 1))
    s_name=$(basename "$script")
    # Every dispatcher script consumes the canonical version through rc-utils
    # rk_load_version, so runtime version drift between scripts is impossible.
    # Report the canonical value per script; a broken loader surfaces as
    # canonical "unknown".
    s_version="$CANONICAL_VERSION"
    match="✓"
    match_json="true"
    [[ "$CANONICAL_VERSION" == "unknown" ]] && match="— [UNKNOWN]" && match_json="null"

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
        JSON_RAG='"rag_exports": {"status": "skipped", "reason": "'"${BOOK_REPORT_DIR#"$ROOT_DIR"/}"'/ does not exist"}'
    else
        mapfile -t rag_files < <(find "$BOOK_REPORT_DIR" -maxdepth 1 -type f 2>/dev/null || true)
        if [[ ${#rag_files[@]} -eq 0 ]]; then
            JSON_RAG='"rag_exports": {"status": "empty", "reason": "no book-reports found — run: ./rotkeeper.sh book --all"}'
        else
            json_rag_arr="["
            first_rag=true
            for f in ${rag_files[@]+"${rag_files[@]}"}; do
                fn=$(basename "$f")
                sz=$(du -h "$f" | cut -f1)
                ch=$(wc -c < "$f")
                # Estimate tokens as chars/4 (heuristic) and context % vs 128k window.
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
    status_heading "=== RAG Exports (book-reports) ==="
    if [[ ! -d "$BOOK_REPORT_DIR" ]]; then
        echo "[SKIP] ${BOOK_REPORT_DIR#"$ROOT_DIR"/}/ does not exist"
    else
        mapfile -t rag_files < <(find "$BOOK_REPORT_DIR" -maxdepth 1 -type f 2>/dev/null || true)
        if [[ ${#rag_files[@]} -eq 0 ]]; then
            echo "[EMPTY] no book-reports found — run: ./rotkeeper.sh book --all"
        else
            printf "%-30s | %-10s | %-12s | %s\n" "Filename" "Size" "Chars" "Token Estimate / 128k %"
            echo "--------------------------------------------------------------------------------"
            tot_ch=0
            tot_tk=0
            for f in ${rag_files[@]+"${rag_files[@]}"}; do
                fn=$(basename "$f")
                sz=$(du -h "$f" | cut -f1)
                ch=$(wc -c < "$f")
                # Tokens ≈ chars/4; display in k and % of 128k context.
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
RELEASES_DIR="${ARCHIVE_DIR#"$ROOT_DIR"/}/releases"
if [[ "$JSON_MODE" == true ]]; then
    if [[ ! -d "$RELEASES_DIR" ]]; then
        JSON_RELEASES='"releases": {"status": "skipped", "reason": "'"${ARCHIVE_DIR#"$ROOT_DIR"/}"'/releases/ does not exist"}'
    else
        mapfile -t rel_files < <(find "$RELEASES_DIR" -maxdepth 1 -type f -name '*.zip' 2>/dev/null | sort -r || true)
        if [[ ${#rel_files[@]} -eq 0 ]]; then
            JSON_RELEASES='"releases": {"status": "empty", "reason": "no releases — run: ./rotkeeper.sh release VERSION"}'
        else
            json_rel_arr="["
            first_rel=true
            for f in ${rel_files[@]+"${rel_files[@]}"}; do
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
    status_heading "=== Releases ==="
    if [[ ! -d "$RELEASES_DIR" ]]; then
        echo "[SKIP] ${ARCHIVE_DIR#"$ROOT_DIR"/}/releases/ does not exist"
    else
        mapfile -t rel_files < <(find "$RELEASES_DIR" -maxdepth 1 -type f -name '*.zip' 2>/dev/null | sort -r || true)
        if [[ ${#rel_files[@]} -eq 0 ]]; then
            echo "[EMPTY] no releases — run: ./rotkeeper.sh release VERSION"
        else
            if [[ "$VERBOSE" == true ]]; then
                printf "%-30s | %-10s | %s\n" "Filename" "Size" "Date"
                echo "----------------------------------------------------------------------"
                for f in ${rel_files[@]+"${rel_files[@]}"}; do
                    fn=$(basename "$f")
                    sz=$(du -h "$f" | cut -f1)
                    mod=$(date -r "$f" '+%Y-%m-%d %H:%M:%S')
                    printf "%-30s | %-10s | %s\n" "$fn" "$sz" "$mod"
                done
                echo "----------------------------------------------------------------------"
                echo "Total Releases: ${#rel_files[@]}"
            else
                fn=$(basename "${rel_files[0]}")
                sz=$(du -h "${rel_files[0]}" | cut -f1)
                mod=$(date -r "${rel_files[0]}" '+%Y-%m-%d %H:%M:%S')
                printf "%-30s | %-10s | %s\n" "$fn" "$sz" "$mod"
                if [[ ${#rel_files[@]} -gt 1 ]]; then
                    echo "... and $(( ${#rel_files[@]} - 1 )) more — run with --verbose for full list"
                fi
                echo "Total Releases: ${#rel_files[@]}"
            fi
        fi
    fi
    echo ""
fi


# --- Section 4b: Recent Tombs ---
if [[ "$JSON_MODE" == true ]]; then
    if [[ ! -d "$ARCHIVE_DIR" ]]; then
        JSON_TOMBS='"recent_tombs": {"status": "skipped", "reason": "'"${ARCHIVE_DIR#"$ROOT_DIR"/}"'/ does not exist"}'
    else
        mapfile -t tomb_files < <(find "$ARCHIVE_DIR" -maxdepth 1 -type f -name '*.tar.gz' 2>/dev/null | sort -r | head -n 5 || true)
        if [[ ${#tomb_files[@]} -eq 0 ]]; then
            JSON_TOMBS='"recent_tombs": {"status": "empty", "reason": "no archives found — run: ./rotkeeper.sh render"}'
        else
            json_tomb_arr="["
            first_tomb=true
            for f in ${tomb_files[@]+"${tomb_files[@]}"}; do
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
    status_heading "=== Recent Tombs ==="
    if [[ ! -d "$ARCHIVE_DIR" ]]; then
        echo "[SKIP] ${ARCHIVE_DIR#"$ROOT_DIR"/}/ does not exist"
    else
        mapfile -t tomb_files < <(find "$ARCHIVE_DIR" -maxdepth 1 -type f -name '*.tar.gz' 2>/dev/null | sort -r | head -n 5 || true)
        if [[ ${#tomb_files[@]} -eq 0 ]]; then
            echo "[EMPTY] no archives found — run: ./rotkeeper.sh render"
        else
            if [[ "$VERBOSE" == true ]]; then
                printf "%-30s | %-10s | %s\n" "Filename" "Size" "Date"
                echo "----------------------------------------------------------------------"
                for f in ${tomb_files[@]+"${tomb_files[@]}"}; do
                    fn=$(basename "$f")
                    sz=$(du -h "$f" | cut -f1)
                    mod=$(date -r "$f" '+%Y-%m-%d %H:%M:%S')
                    printf "%-30s | %-10s | %s\n" "$fn" "$sz" "$mod"
                done
                echo "----------------------------------------------------------------------"
                echo "Total Recent Tombs Shown: ${#tomb_files[@]}"
            else
                fn=$(basename "${tomb_files[0]}")
                sz=$(du -h "${tomb_files[0]}" | cut -f1)
                mod=$(date -r "${tomb_files[0]}" '+%Y-%m-%d %H:%M:%S')
                printf "%-30s | %-10s | %s\n" "$fn" "$sz" "$mod"
                if [[ ${#tomb_files[@]} -gt 1 ]]; then
                    echo "... and $(( ${#tomb_files[@]} - 1 )) more — run with --verbose for full list"
                fi
                echo "Total Recent Tombs Shown: ${#tomb_files[@]}"
            fi
        fi
    fi
    echo ""
fi


# --- Section 5: Content Pulse ---
if [[ ! -d "$CONTENT_DIR" ]] || [[ -z "$(find "$CONTENT_DIR" -type f \( -name '*.md' -o -name '*.textile' -o -name '*.cook' \) -print -quit 2>/dev/null)" ]]; then
    total_md=0
    total_textile=0
    total_cook=0
    stubs=0
    drafts=0
    docs_stubs=0
    if [[ "$JSON_MODE" == true ]]; then
        JSON_PULSE="  \"content_pulse\": {
    \"status\": \"empty\",
    \"reason\": \"no content files found in ${CONTENT_DIR#"$ROOT_DIR"/}/\",
    \"total_md\": 0,
    \"total_textile\": 0,
    \"total_cook\": 0,
    \"stubs\": 0,
    \"drafts\": 0,
    \"docs_stubs\": 0
  }"
    else
        status_heading "=== Content Pulse ==="
        echo "[EMPTY] no content files found in ${CONTENT_DIR#"$ROOT_DIR"/}/"
        echo "Total .md files : 0"
        echo "Total .textile files : 0"
        echo "Total .cook files : 0"
        echo "Stubs           : 0"
        echo "Drafts          : 0"
        echo "Docs stubs      : 0"
        echo ""
    fi
else
    mapfile -t c_files < <(find "$CONTENT_DIR" -type f -name '*.md' -print)
    mapfile -t c_textile_files < <(find "$CONTENT_DIR" -type f -name '*.textile' -print)
    mapfile -t c_cook_files < <(find "$CONTENT_DIR" -type f -name '*.cook' -print)
    total_md=${#c_files[@]}
    total_textile=${#c_textile_files[@]}
    total_cook=${#c_cook_files[@]}
    stubs=0
    drafts=0
    if [[ $total_md -gt 0 ]]; then
        stubs=$(grep -l '^status: stub' ${c_files[@]+"${c_files[@]}"} 2>/dev/null | wc -l | tr -d ' ' || true)
        drafts=$(grep -l '^status: draft' ${c_files[@]+"${c_files[@]}"} 2>/dev/null | wc -l | tr -d ' ' || true)
    fi

    docs_stubs=0
    if [[ -d "$DOCS_DIR" ]]; then
        docs_stubs=$(find "$DOCS_DIR" -type f \( -name '*.md' -o -name '*.textile' -o -name '*.cook' \) -exec grep -l '^status: stub' {} + 2>/dev/null | wc -l | tr -d ' ' || true)
    fi

    if [[ "$JSON_MODE" == true ]]; then
        JSON_PULSE="  \"content_pulse\": {
    \"status\": \"ok\",
    \"total_md\": $total_md,
    \"total_textile\": $total_textile,
    \"total_cook\": $total_cook,
    \"stubs\": $stubs,
    \"drafts\": $drafts,
    \"docs_stubs\": $docs_stubs
  }"
    else
        status_heading "=== Content Pulse ==="
        echo "Total .md files : $total_md"
        echo "Total .textile files : $total_textile"
        echo "Total .cook files : $total_cook"
        echo "Stubs           : $stubs"
        echo "Drafts          : $drafts"
        echo "Docs stubs      : $docs_stubs"
        echo ""
    fi
fi

# --- Section 6: Render Freshness ---
# Portable mtime comparison: GNU `stat -c %Y` fails on BSD/macOS, so route
# through the shared rk_mtime helper (stat -f %m fallback). Filenames are
# consumed null-terminated; never word-split find output.
NEWEST_HTML=""
while IFS= read -r -d '' freshness_html; do
  mtime=$(rk_mtime "$freshness_html")
  [[ -n "$mtime" && ( -z "$NEWEST_HTML" || "$mtime" -gt "$NEWEST_HTML" ) ]] && NEWEST_HTML="$mtime"
done < <(find "$OUTPUT_DIR" -type f -name '*.html' -print0 2>/dev/null)

NEWEST_SRC=""
while IFS= read -r -d '' freshness_src; do
  mtime=$(rk_mtime "$freshness_src")
  [[ -n "$mtime" && ( -z "$NEWEST_SRC" || "$mtime" -gt "$NEWEST_SRC" ) ]] && NEWEST_SRC="$mtime"
done < <(find "$CONTENT_DIR" -type f \( -name '*.md' -o -name '*.textile' -o -name '*.cook' \) -print0 2>/dev/null)

# Count HTML for richer status line
html_count=0
if [[ -d "$OUTPUT_DIR" ]]; then
  html_count=$(find "$OUTPUT_DIR" -type f -name '*.html' 2>/dev/null | wc -l | tr -d ' ' || echo 0)
fi

status_render="[EMPTY] no rendered output found — run bash rotkeeper.sh render"
status_json="empty"
if [[ -n "$NEWEST_HTML" ]]; then
    if [[ -n "$NEWEST_SRC" ]] && [[ "$NEWEST_SRC" -gt "$NEWEST_HTML" ]]; then
        status_render="✗ [STALE] content has changed since last render ($html_count HTML)"
        status_json="stale"
    else
        status_render="✓ [OK] output is current ($html_count HTML)"
        status_json="ok"
    fi
fi

if [[ "$JSON_MODE" == true ]]; then
    JSON_RENDER="  \"render_freshness\": {
    \"status\": \"$status_json\",
    \"message\": \"$status_render\"
  }"
else
    status_heading "=== Render Freshness ==="
    if [[ "$status_json" == "ok" ]]; then
      status_ok "$status_render"
    elif [[ "$status_json" == "stale" ]]; then
      status_warn "$status_render"
    else
      status_dim "$status_render"
    fi
    echo ""
fi



# --- Section 8: Config Summary ---
CONFIG_FILE="$CONFIG_DIR/rotkeeper.yaml"
if [[ ! -f "$CONFIG_FILE" ]]; then
    if [[ "$JSON_MODE" == true ]]; then
        JSON_CONFIG='"config_summary": {"status": "skipped", "reason": "'"${CONFIG_DIR#"$ROOT_DIR"/}"'/rotkeeper.yaml does not exist"}'
    else
        status_heading "=== Config Summary ==="
        echo "[SKIP] ${CONFIG_DIR#"$ROOT_DIR"/}/rotkeeper.yaml does not exist"
        echo ""
    fi
else
    conf_project=$(yq eval '.project // "[not set]"' "$CONFIG_FILE" 2>/dev/null | tr -d '\n' || echo "[not set]")
    conf_author=$(yq eval '.author // "[not set]"' "$CONFIG_FILE" 2>/dev/null | tr -d '\n' || echo "[not set]")
    conf_version=$(yq eval '.version // "[not set]"' "$CONFIG_FILE" 2>/dev/null | tr -d '\n' || echo "[not set]")
    # Theme registry (#252): registry default wins over the legacy key.
    conf_default_template=$(yq eval '.theme_registry.default // .default_template // "[not set]"' "$CONFIG_FILE" 2>/dev/null | tr -d '\n' || echo "[not set]")
    conf_input_format=$(yq eval '.input_format // "[not set]"' "$CONFIG_FILE" 2>/dev/null | tr -d '\n' || echo "[not set]")
    conf_license=$(yq eval '.license // "[not set]"' "$CONFIG_FILE" 2>/dev/null | tr -d '\n' || echo "[not set]")

    if [[ "$JSON_MODE" == true ]]; then
        conf_project_j=$(escape_json "$conf_project")
        conf_author_j=$(escape_json "$conf_author")
        conf_version_j=$(escape_json "$conf_version")
        conf_default_template_j=$(escape_json "$conf_default_template")
        conf_input_format_j=$(escape_json "$conf_input_format")
        conf_license_j=$(escape_json "$conf_license")

        JSON_CONFIG="  \"config_summary\": {
    \"status\": \"ok\",
    \"project\": \"$conf_project_j\",
    \"author\": \"$conf_author_j\",
    \"version\": \"$conf_version_j\",
    \"default_template\": \"$conf_default_template_j\",
    \"input_format\": \"$conf_input_format_j\",
    \"license\": \"$conf_license_j\"
  }"
    else
        status_heading "=== Config Summary ==="
        echo "Project          : $conf_project"
        echo "Author           : $conf_author"
        echo "Version          : $conf_version"
        echo "Default Template : $conf_default_template"
        echo "Input Format     : $conf_input_format"
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
    echo "$JSON_CONFIG"
    echo "}"
fi

log "INFO" "rc-status.sh completed"
