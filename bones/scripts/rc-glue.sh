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
#  Version : 0.4.0
# ------------------------------------------------------------

set -euo pipefail
FORCE_GLUE=false

# shellcheck disable=SC2034


source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
VERSION="${ROTKEEPER_VERSION:-0.3.1.4}"

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
