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

rk_init_script rc-dip "$@"

OBSOLETE_DIR="${CONTENT_DIR}/obsolete/docs"
MATRIX_FILE="${DOCS_DIR}/dip-matrix.md"
DATE_STR=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

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
        
        # Add the exact path or its prefix
        if [[ ! "$path_col" =~ \(unresolved: ]]; then
            AUTOPSY_EXCLUDES["$path_col"]=1
            first_dir=$(echo "$path_col" | cut -d/ -f1)
            if [[ -n "$first_dir" ]] && [[ ! "$first_dir" =~ ^- ]]; then
                AUTOPSY_EXCLUDES["$first_dir"]=1
            fi
            dir_path=$(dirname "$path_col")
            if [[ "$dir_path" != "." ]] && [[ ! "$dir_path" =~ ^- ]]; then
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
AUTOPSY_EXCLUDES["output"]=1
AUTOPSY_EXCLUDES["bones/asset-manifest.yaml"]=1

# 2. Discover Core Files from fsbook catalog
CORE_FILES=()
if [[ -f "$FSBOOK_CATALOG" ]]; then
    log "INFO" "Reading fsbook catalog for file discovery..."
    while IFS= read -r line; do
        if [[ "$line" =~ ^-[[:space:]]+([^\\]+) ]]; then
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
                    if [[ "$file_path" =~ ^[A-Z]+\.md$ ]]; then
                        CORE_FILES+=("$file_path")
                    fi
                else
                    CORE_FILES+=("$file_path")
                fi
            fi
        fi
    done < "$FSBOOK_CATALOG"
else
    log "WARN" "FSBook catalog not found at $FSBOOK_CATALOG. File discovery cannot proceed. Run rc-book.sh --fsbook first."
    return 1
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

for doc in "${EXISTING_DOCS[@]}"; do
    [[ "$doc" == "$MATRIX_FILE" ]] && continue

    if [[ -z "${EXPECTED_DOCS["$doc"]:-}" ]]; then
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

## Details
<!-- DIP-GENERATED-MARKER: Details -->
TODO: Provide technical details, usage instructions, or context.
STUB
            log "INFO" "Stubbed missing doc: $doc_path"
        fi
    fi
done

# 5. Check Formatting & Generate Matrix
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

get_fs_date() {
    local file=$1
    if [ -f "$file" ]; then
        date -r "$file" "+%Y-%m-%d"
    else
        echo "Missing"
    fi
}

for doc_path in "${!EXPECTED_DOCS[@]}"; do
    target_file="${EXPECTED_DOCS["$doc_path"]}"
    
    # Read status from doc frontmatter
    status="unknown"
    if [ -f "$doc_path" ]; then
        # Check if file has frontmatter
        if grep -q "^---$" "$doc_path"; then
            status=$(awk -F': ' '/^status:/{gsub(/"/, "", $2); print $2; exit}' "$doc_path")
        fi
    else
        status="missing"
    fi
    [[ -z "$status" ]] && status="unknown"

    code_date=$(get_fs_date "$ROOT_DIR/$target_file")
    doc_date=$(get_fs_date "$doc_path")

    # Format paths relative to ROOT_DIR for matrix display
    rel_doc="${doc_path#"$ROOT_DIR"/}"
    
    if [[ "${DRY_RUN:-false}" == false ]]; then
        echo "| \`$target_file\` | [$rel_doc]($rel_doc) | $code_date | $doc_date | $status |" >> "$MATRIX_FILE"
    fi
done

if [[ "${DRY_RUN:-false}" == false ]]; then
    log "INFO" "DIP audit complete. See $MATRIX_FILE for details."
fi
