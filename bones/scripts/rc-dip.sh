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
#  Version : 0.3.1.4
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

VERSION="${ROTKEEPER_VERSION:-0.3.1.4}"

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
    BASE_NO_EXT="${file%.*}"
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
    MESSAGES_DIR="$CONTENT_DIR/messages"
    if [[ -d "$MESSAGES_DIR" ]]; then
        notes_content=""
        notes_mtime="0000-00-00"
        for msg_file in "$MESSAGES_DIR"/*.md; do
            [[ -f "$msg_file" ]] || continue
            if grep -q "report_type: \"necromancer-notes\"" "$msg_file" && grep -q "subject_script: \"$script_name\"" "$msg_file"; then
                fm_mtime=$(get_fs_iso "$msg_file")
                [[ "$fm_mtime" > "$notes_mtime" ]] && notes_mtime="$fm_mtime"
                body=$(sed '1{/^---$/!q;}; 1,/^---$/d' "$msg_file")
                notes_content+="$body"$'\n\n'
            fi
        done
        notes_content=$(echo "$notes_content" | grep -v '^$' || true)
        if [[ -n "$notes_content" ]]; then
            stitch_pillar "$doc_path" "DIP-SOUL-EXTRACTED" "$notes_content" "$notes_mtime"
        fi
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
