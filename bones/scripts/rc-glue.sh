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
# Env assumptions: reads BONES_DIR, CONFIG_DIR, CONTENT_DIR, DOCS_DIR, DRY_RUN, LOG_DIR, META_DIR, QUIET, ROOT_DIR, SCRIPT_DIR, TMP_DIR, VERBOSE (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.
# CWD assumptions: No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.
# Input/Output contracts: CLI args and env vars in; files and stdout/stderr out; respects --dry-run (no writes) and --verbose.
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-glue.sh
#  Purpose : Generate navigation glue (index.md) for unindexed directories
#  Version : 0.5.1
# ------------------------------------------------------------

set -euo pipefail
FORCE_GLUE=false

# ---
# show_help: Print glue usage and exit.
# Inputs: none
# Outputs: Prints help to stdout and exits 0
# Env: Reads BONES_DIR, CONFIG_DIR, CONTENT_DIR, DOCS_DIR, DRY_RUN, LOG_DIR ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
show_help() {
  cat <<'EOF'
rc-glue.sh — Generate navigation glue for unindexed content directories

Usage: rotkeeper.sh glue [options]

Options:
  --path DIR       Limit glue to a directory under home/content/
  --force          Refresh existing auto-generated indexes
  --dry-run        Preview changes without writing
  --verbose        Show detailed logs
  --help, -h       Show this help message
EOF
  exit 0
}
TARGET_DIR=""

# shellcheck disable=SC2034



SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
rk_init_script "rc-glue" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR CONTENT_DIR DOCS_DIR
require_yq_version
require_gawk_version

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE_GLUE=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --verbose) VERBOSE=true; QUIET=false; shift ;;
    --help|-h) show_help ;;
    --path)
      TARGET_DIR="$2"
      shift 2
      ;;
    *) shift ;;
  esac
done

# ---
# main: Generate or refresh navigation glue indexes under CONTENT_DIR.
# Inputs: none (reads CONTENT_DIR, TARGET_DIR, FORCE_GLUE, DRY_RUN)
# Outputs: Creates/updates index.md files with navigation blocks
# Env: Reads CONFIG_DIR, CONTENT_DIR, DRY_RUN, FORCE_GLUE, META_DIR, TARGET_DIR (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
main() {
  # DEFENSIVE ARCHITECTURE: If shipping without a home directory, breathe it into existence
  if [[ ! -d "$CONTENT_DIR" ]]; then
    log "WARN" "👻 Content catacomb missing. Generating sterile home environment dynamically."
    run mkdir -p "$CONTENT_DIR"
  fi

  if [[ -n "$TARGET_DIR" ]]; then
    if [[ "$TARGET_DIR" == /* ]]; then
      TARGET_DIR=$(rk_canonical_path "$TARGET_DIR" 2>/dev/null || true)
    else
      TARGET_DIR=$(rk_canonical_path "$CONTENT_DIR/$TARGET_DIR" 2>/dev/null || true)
    fi
    if [[ -z "$TARGET_DIR" || ( "$TARGET_DIR" != "$CONTENT_DIR" && "$TARGET_DIR" != "$CONTENT_DIR/"* ) ]]; then
      log "ERROR" "--path must resolve under CONTENT_DIR: $TARGET_DIR"
      exit 1
    fi
  else
    TARGET_DIR="$CONTENT_DIR"
  fi

  log "INFO" "Applying navigation glue to unindexed tombs in $TARGET_DIR..."

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
            if [[ "$DRY_RUN" == true ]]; then
              log "DRY-RUN" "Would overwrite auto-glued index: $INDEX_FILE"
              continue
            fi
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
    DEFAULT_TEMPLATE=$(yq eval '.default_template // "theme-spooky-dark.html"' "$CONFIG_DIR/rotkeeper.yaml" 2>/dev/null || echo "theme-spooky-dark.html")
    SAFE_TEMPLATE="${DEFAULT_TEMPLATE//\"/\\\"}"
    DEFAULT_YAML="title: \"Index of $SAFE_TITLE\"
template: \"$SAFE_TEMPLATE\"
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
      RAW_NAME=$(basename "$FILE")
      case "$RAW_NAME" in
        *.md) FILE_NAME="${RAW_NAME%.md}" ;;
        *.textile) FILE_NAME="${RAW_NAME%.textile}" ;;
        *.cook) FILE_NAME="${RAW_NAME%.cook}" ;;
        *) FILE_NAME="$RAW_NAME" ;;
      esac
      GLUE_CONTENT+=$'
'"- [$FILE_NAME](<$FILE_NAME.html>)"
    done < <(find "$DIR" -maxdepth 1 -mindepth 1 -type f \( -name "*.md" -o -name "*.textile" -o -name "*.cook" \) ! -name "index.md" -print0 2>/dev/null | sort -z)
    GLUE_CONTENT+=$'
'"<!-- ROTKEEPER-GLUE-END -->"

    # Inject the structural mapping data into the target index file
    if [[ "$DRY_RUN" == true ]]; then
        if [[ "$IS_EXISTING_CUSTOM" == true ]]; then
            log "DRY-RUN" "Would refresh navigation glue in $INDEX_FILE"
        else
            log "DRY-RUN" "Would create navigation index: $INDEX_FILE"
        fi
        continue
    fi
    if [[ "$IS_EXISTING_CUSTOM" == true ]]; then
        # gawk: count glue markers — exactly one START and one END in order means replaceable block
        if gawk 'BEGIN { start=0; end=0; ok=0 } /<!-- ROTKEEPER-GLUE-START -->/ { start++ } /<!-- ROTKEEPER-GLUE-END -->/ { end++; if(start == 1) ok=1 } END { if (start == 1 && end == 1 && ok == 1) exit 0; else exit 1 }' "$INDEX_FILE"; then
            glue_tmp="${INDEX_FILE}.tmp.$$"
            # gawk: replace existing glue block — print new glue at START, suppress old block until END, pass through rest
            if GLUE_CONTENT="$GLUE_CONTENT" gawk 'BEGIN { p=1 } /<!-- ROTKEEPER-GLUE-START -->/ { print ENVIRON["GLUE_CONTENT"]; p=0 } /<!-- ROTKEEPER-GLUE-END -->/ { p=1; next } p { print }' "$INDEX_FILE" > "$glue_tmp"; then
                mv "$glue_tmp" "$INDEX_FILE"
            else
                rm -f "$glue_tmp"
                log "WARN" "Glue rewrite failed for $INDEX_FILE — leaving existing content untouched."
            fi
        else
            printf '\n%s\n' "$GLUE_CONTENT" >> "$INDEX_FILE"
        fi
    else
        printf '%s\n\n# %s\n\n%s\n' "$FRONTMATTER" "$SOUL_TITLE" "$GLUE_CONTENT" > "$INDEX_FILE"
    fi
  done < <(find "$TARGET_DIR" -type d -print0)
  if [[ "$DRY_RUN" == true ]]; then
    log "MARKER" "Navigation glue dry-run complete under $TARGET_DIR."
  else
    log "MARKER" "Navigation glue applied successfully under $TARGET_DIR."
  fi
}

main "$@"
