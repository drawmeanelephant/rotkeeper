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
        continue
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

    cat <<CAT_EOF > "$INDEX_FILE"
${FRONTMATTER}

# $SOUL_TITLE

CAT_EOF

    # List subdirectories
    find "$DIR" -maxdepth 1 -mindepth 1 -type d -print0 | sort -z | while IFS= read -r -d '' SUBDIR; do
      SUBDIR_NAME=$(basename "$SUBDIR")
      echo "- [$SUBDIR_NAME/]($SUBDIR_NAME/index.html)" >> "$INDEX_FILE"
    done

    # List immediate markdown files (excluding index.md which we just created)
    find "$DIR" -maxdepth 1 -mindepth 1 -type f -name "*.md" ! -name "index.md" -print0 | sort -z | while IFS= read -r -d '' FILE; do
      FILE_NAME=$(basename "$FILE" .md)
      echo "- [$FILE_NAME]($FILE_NAME.html)" >> "$INDEX_FILE"
    done

    log "INFO" "Created/Updated structured tomb index: $INDEX_FILE"
  done

  log "INFO" "Navigation glue applied successfully."
}

main "$@"
