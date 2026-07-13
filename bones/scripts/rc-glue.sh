#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
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
#  Version : 0.4.0.3
# ------------------------------------------------------------

set -euo pipefail
FORCE_GLUE=false

# shellcheck disable=SC2034


VERSION="${ROTKEEPER_VERSION:-0.4.0.3}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
rk_init_script "rc-glue" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR CONTENT_DIR DOCS_DIR

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE_GLUE=true; shift ;;
    *) shift ;;
  esac
done

main() {
  # DEFENSIVE ARCHITECTURE: If shipping without a home directory, breathe it into existence
  if [[ ! -d "$CONTENT_DIR" ]]; then
    log "WARN" "👻 Content catacomb missing. Generating sterile home environment dynamically."
    run mkdir -p "$CONTENT_DIR"
  fi

  log "INFO" "Applying navigation glue to unindexed tombs in $CONTENT_DIR..."

  # Process bottom-up to ensure nested directory chains inherit properties cleanly
  while IFS= read -r -d '' DIR; do
    INDEX_FILE="$DIR/index.md"

    # Absolute path safety bounds checking
    if [[ ! -d "$DIR" ]]; then
      log "ERROR" "Directory vanished during runtime sequence: $DIR"
      continue
    fi

    IS_EXISTING_CUSTOM=false
    if [[ -f "$INDEX_FILE" ]]; then
      if grep -q "rotkeeper_glued: true" "$INDEX_FILE"; then
        if [[ "$FORCE_GLUE" == true ]]; then
            log "INFO" "Overwriting existing auto-glued index with --force: $INDEX_FILE"
            rm "$INDEX_FILE"
        else
            log "WARN" "Auto-glued index exists at $INDEX_FILE. Skipping."
            continue
        fi
      else
        IS_EXISTING_CUSTOM=true
      fi
    fi

    DIR_NAME=$(basename "$DIR")
    [[ "$DIR" == "$CONTENT_DIR" ]] && DIR_NAME="Root Index"

    # --- Path-Mirrored Folder Soul Ingestion ---
    REL_DIR_PATH="${DIR#"$CONTENT_DIR"/}"

    # FIX: Explicitly resolve sidecar lookup formatting from the centralized meta crypt
    if [[ -z "$REL_DIR_PATH" || "$REL_DIR_PATH" == "$DIR" ]]; then
        SOUL_FILE="$META_DIR/rotkeeper.soul.md"
    else
        SOUL_FILE="$META_DIR/${REL_DIR_PATH}.soul.md"
    fi

    # Initialize frontmatter template baseline mappings
    SAFE_TITLE="${DIR_NAME//\"/\\\"}"
    DEFAULT_YAML="title: \"Index of $SAFE_TITLE\"
template: \"rotkeeper-doc.html\"
rotkeeper_glued: true"

    if [[ -f "$SOUL_FILE" ]]; then
        log "INFO" "💀 Synchronizing folder soul alignment: $SOUL_FILE"
        # DIP SEPARATION: Surgically merge sidecar metadata block via yq array mapping
        MERGED_YAML=$(yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' <(echo "$DEFAULT_YAML") <(yq eval --front-matter="extract" '.' "$SOUL_FILE" 2>/dev/null || echo "{}"))
        SOUL_TITLE=$(echo "$MERGED_YAML" | yq eval '.title // ""' -)
        [[ -z "$SOUL_TITLE" ]] && SOUL_TITLE="Index of $DIR_NAME"
        FRONTMATTER="---
${MERGED_YAML}
---"
    else
        SOUL_TITLE="Index of $DIR_NAME"
        FRONTMATTER="---
${DEFAULT_YAML}
---"
    fi

    # Build dynamic navigation payload
    GLUE_CONTENT="<!-- ROTKEEPER-GLUE-START -->"
    while IFS= read -r -d '' SUBDIR; do
      SUBDIR_NAME=$(basename "$SUBDIR")
      GLUE_CONTENT+=$'
'"- [$SUBDIR_NAME/](<$SUBDIR_NAME/index.html>)"
    done < <(find "$DIR" -maxdepth 1 -mindepth 1 -type d -print0 2>/dev/null | sort -z)

    while IFS= read -r -d '' FILE; do
      FILE_NAME=$(basename "$FILE" .md)
      GLUE_CONTENT+=$'
'"- [$FILE_NAME](<$FILE_NAME.html>)"
    done < <(find "$DIR" -maxdepth 1 -mindepth 1 -type f -name "*.md" ! -name "index.md" -print0 2>/dev/null | sort -z)
    GLUE_CONTENT+=$'
'"<!-- ROTKEEPER-GLUE-END -->"

    # Inject the structural mapping data into the target index file
    if [[ "$IS_EXISTING_CUSTOM" == true ]]; then
        if gawk 'BEGIN { start=0; end=0; ok=0 } /<!-- ROTKEEPER-GLUE-START -->/ { start++ } /<!-- ROTKEEPER-GLUE-END -->/ { end++; if(start == 1) ok=1 } END { if (start == 1 && end == 1 && ok == 1) exit 0; else exit 1 }' "$INDEX_FILE"; then
            GLUE_CONTENT="$GLUE_CONTENT" gawk 'BEGIN { p=1 } /<!-- ROTKEEPER-GLUE-START -->/ { print ENVIRON["GLUE_CONTENT"]; p=0 } /<!-- ROTKEEPER-GLUE-END -->/ { p=1; next } p { print }' "$INDEX_FILE" > "${INDEX_FILE}.tmp"
            mv "${INDEX_FILE}.tmp" "$INDEX_FILE"
        else
            printf '\n%s\n' "$GLUE_CONTENT" >> "$INDEX_FILE"
        fi
    else
        printf '%s\n\n# %s\n\n%s\n' "$FRONTMATTER" "$SOUL_TITLE" "$GLUE_CONTENT" > "$INDEX_FILE"
    fi
  done < <(find "$CONTENT_DIR" -type d -print0)
  log "INFO" "Navigation glue applied successfully."
}

main "$@"
