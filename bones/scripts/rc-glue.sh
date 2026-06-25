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
#  Version : 0.3.1.4
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
  find "$CONTENT_DIR" -type d | while read -r DIR; do
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

    log "INFO" "Generating glue for $DIR_NAME..."

    cat <<EOF > "$INDEX_FILE"
---
title: "Index of $DIR_NAME"
template: rotkeeper-blog.html
rotkeeper_glued: true
---

# Index of $DIR_NAME

EOF

    # List subdirectories
    find "$DIR" -maxdepth 1 -mindepth 1 -type d | sort | while read -r SUBDIR; do
      SUBDIR_NAME=$(basename "$SUBDIR")
      echo "- [$SUBDIR_NAME/]($SUBDIR_NAME/index.html)" >> "$INDEX_FILE"
    done

    # List immediate markdown files (excluding index.md which we just created)
    find "$DIR" -maxdepth 1 -mindepth 1 -type f -name "*.md" ! -name "index.md" | sort | while read -r FILE; do
      FILE_NAME=$(basename "$FILE" .md)
      echo "- [$FILE_NAME]($FILE_NAME.html)" >> "$INDEX_FILE"
    done

    log "INFO" "Created/Updated $INDEX_FILE"
  done

  log "INFO" "Navigation glue applied successfully."
}

main "$@"
