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
#  Version : 0.3.1.4
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

rk_init_script "rc-status" "${ARGS[@]}"
set -euo pipefail
IFS=$'\n\t'

VERSION="0.3.1.4"
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
            if [[ "$VERBOSE" == true ]]; then
                printf "%-30s | %-10s | %-12s | %s\n" "Filename" "Size" "Chars" "Token Estimate / 128k %"
                echo "--------------------------------------------------------------------------------"
            fi
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

            if [[ "$VERBOSE" == true ]]; then
                echo "--------------------------------------------------------------------------------"
            fi
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
        mapfile -t rel_files < <(find "$RELEASES_DIR" -maxdepth 1 -type f -name '*.zip' -printf '%T@\t%p\n' 2>/dev/null | sort -nr | cut -f2- || true)
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
        mapfile -t rel_files < <(find "$RELEASES_DIR" -maxdepth 1 -type f -name '*.zip' -printf '%T@\t%p\n' 2>/dev/null | sort -nr | cut -f2- || true)
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
    mapfile -t c_files < <(find "$CONTENT_DIR" -type d \( -path "*/docs" -o -path "*/obsolete" \) -prune -o -type f -name '*.md' -print)
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
NEWEST_MD=$(find "$CONTENT_DIR" -type d -path "*/docs" -prune -o -type f -name '*.md' -exec stat -c %Y {} + 2>/dev/null | sort -nr | head -n 1 || echo "")

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
    echo "$JSON_PULSE,"
    echo "$JSON_RENDER,"
    echo "$JSON_INBOX,"
    echo "$JSON_CONFIG"
    echo "}"
fi

log "INFO" "rc-status.sh completed"
