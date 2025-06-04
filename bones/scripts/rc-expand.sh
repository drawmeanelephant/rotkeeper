#!/usr/bin/env bash
# Source shared Rotkeeper helpers
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
# Load environment variables from rc-env.sh if available
ENV_PATH="$(dirname "${BASH_SOURCE[0]}")/rc-env.sh"
if [[ -f "$ENV_PATH" ]]; then
  source "$ENV_PATH"
fi
# Fallback: set SCRIPTDIR and PROJ_ROOT if not defined by rc-env.sh
: "${SCRIPTDIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
: "${PROJ_ROOT:=$(cd "$SCRIPTDIR/../.." && pwd)}"
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-expand.sh
# Purpose: Generate markdown, config, and skeleton files from a BOM definition
# Version: 0.2.5-pre
# Updated: 2025-06-02
# -----------------------------------------
set -euo pipefail
IFS=$'\n\t'

# Trap errors for debugging
trap 'trap_err ${LINENO}' ERR

# Parse common flags
parse_flags "$@"
if [[ "$HELP" == true ]]; then
  show_help
fi

main() {
    require_bins yq
    require_yq_version
    log "INFO" "Running rc-expand.sh."

    # Lint tomb manifests and content frontmatter
    run bash "$SCRIPTDIR/rc-lint.sh"

    DRY_RUN=false
    FORCE=false
    for arg in "$@"; do
      [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
      [[ "$arg" == "--force" ]] && FORCE=true
    done

    # SCRIPTDIR and PROJ_ROOT are now set via rc-env.sh or fallback above
    # Determine BOM path, allowing for different layouts
    SCRIPT_BOM="$SCRIPTDIR/road-to-bones/rotkeeper-bom.yaml"
    BOM_CANDIDATE="$PROJ_ROOT/road-to-bones/rotkeeper-bom.yaml"
    ALT_CANDIDATE="$PROJ_ROOT/bones/road-to-bones/rotkeeper-bom.yaml"
    if [[ -f "$SCRIPT_BOM" ]]; then
      BOM="$SCRIPT_BOM"
    elif [[ -f "$BOM_CANDIDATE" ]]; then
      BOM="$BOM_CANDIDATE"
    elif [[ -f "$ALT_CANDIDATE" ]]; then
      BOM="$ALT_CANDIDATE"
    else
      run echo "ERROR Buildout file not found: tried $SCRIPT_BOM, $BOM_CANDIDATE, and $ALT_CANDIDATE"
      exit 1
    fi
    HOME_DIR="home"
    if [[ "$DRY_RUN" == true ]]; then
        run echo "[DRY RUN] Would create directory $HOME_DIR"
    else
        run mkdir -p "$HOME_DIR"
    fi

    run echo "🧬 Expanding from buildout: $BOM"

    # (yq check removed, handled by require_bins)

    # Sanity check for BOM path
    if [[ ! -f "$BOM" ]]; then
      run echo "❌ ERROR: Buildout file not found: $BOM"
      run echo "🧬 Expected at path: $BOM"
      exit 1
    fi

    # Loop through each content item in the BOM
    page_count=$(yq e '.content | length' "$BOM")

    CREATED=0
    SKIPPED=0
    for i in $(seq 0 $((page_count - 1))); do
      FILENAME=$(yq e ".content[$i].filename" "$BOM")
      TITLE=$(yq e ".content[$i].title" "$BOM")
      TEMPLATE=$(yq e ".content[$i].template" "$BOM")
      SUBTITLE=$(yq e ".content[$i].subtitle" "$BOM")
      BODY=$(yq e ".content[$i].body" "$BOM")

      OUTFILE="$HOME_DIR/$FILENAME"

      # Check for draft status in content
      STATUS=$(yq e ".content[$i].status // \"\"" "$BOM")
      if [[ "$STATUS" == "draft" ]]; then
        run echo "⏳ Skipping draft content: $FILENAME"
        ((SKIPPED++))
        continue
      fi

      if [[ -f "$OUTFILE" && "$FORCE" != true ]]; then
        run echo "⚠️  Skipping $OUTFILE (already exists)"
        ((SKIPPED++))
        continue
      fi

      run echo "📄 Generating: $OUTFILE"
      if [[ "$DRY_RUN" == true ]]; then
          run echo "[DRY RUN] Would write to $OUTFILE"
      else
          {
            echo "---"
            echo "title: \"$TITLE\""
            echo "template: $TEMPLATE"
            [[ -n "$SUBTITLE" && "$SUBTITLE" != "null" ]] && echo "subtitle: \"$SUBTITLE\""
            echo "---"
            echo ""
            echo "$BODY"
          } > "$OUTFILE"
          ((CREATED++))
      fi
    done

    run echo "✅ Expansion complete."
    run echo "📈 Created: $CREATED"
    run echo "⚠️ Skipped: $SKIPPED"

    # === SCRIPTS ===
    # === SELF REPLICATION ===
    SELF_DEST="bones/scripts/rc-expand.sh"
    if [[ "$SELF_DEST" == "$SELF_DEST" ]]; then
      if [[ "$DRY_RUN" == true ]]; then
          run echo "[DRY RUN] Would create directory $(dirname "$SELF_DEST")"
          run echo "[DRY RUN] Would copy rc-expand.sh to $SELF_DEST"
          run echo "[DRY RUN] Would chmod +x $SELF_DEST"
      else
          run echo "🔄 Copying rc-expand.sh to $SELF_DEST"
          run mkdir -p "$(dirname "$SELF_DEST")"
          run cp "$0" "$SELF_DEST"
          run chmod +x "$SELF_DEST"
      fi
    fi

    SCRIPT_NAME=$(basename "$0")

    script_count=$(yq e '.scripts | length' "$BOM")
    for i in $(seq 0 $((script_count - 1))); do
      SCRIPT_PATH=$(yq e ".scripts[$i].path" "$BOM")
      # Skip stubbing the expand script itself
      if [[ "$(basename "$SCRIPT_PATH")" == "$SCRIPT_NAME" ]]; then
        continue
      fi
      HEADER=$(yq e ".scripts[$i].header" "$BOM")
      STUB=$(yq e ".scripts[$i].stub" "$BOM")
      if [[ "$STUB" != "true" ]]; then
        run echo "⚠️  Skipping $SCRIPT_PATH (stub: false)"
        continue
      fi
      if [[ ! -f "$SCRIPT_PATH" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            run echo "[DRY RUN] Would create directory $(dirname "$SCRIPT_PATH")"
            run echo "[DRY RUN] Would create script: $SCRIPT_PATH"
            run echo "[DRY RUN] Would chmod +x $SCRIPT_PATH"
        else
            run echo "⚙️  Creating script: $SCRIPT_PATH"
            run mkdir -p "$(dirname "$SCRIPT_PATH")"
            {
              echo "#!/usr/bin/env bash"
              [[ "$HEADER" != "null" ]] && echo "# $HEADER"
              echo "# TODO"
            } > "$SCRIPT_PATH"
            run chmod +x "$SCRIPT_PATH"
        fi
      fi
    done

    # === CONFIG FILES ===
    config_count=$(yq e '.config | length' "$BOM")
    for i in $(seq 0 $((config_count - 1))); do
      CONFIG_PATH=$(yq e ".config[$i].path" "$BOM")
      if [[ ! -f "$CONFIG_PATH" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            run echo "[DRY RUN] Would create directory $(dirname "$CONFIG_PATH")"
            run echo "[DRY RUN] Would touch config file: $CONFIG_PATH and write headers"
        else
            run echo "📄 Touching config file: $CONFIG_PATH"
            run mkdir -p "$(dirname "$CONFIG_PATH")"
            {
              echo "# 🔮 Generated by rc-expand.sh"
              echo "# ☠️ Do not edit unless you are bone-certified."
            } > "$CONFIG_PATH"
        fi
      fi
    done

    # === TEMPLATES ===
    template_count=$(yq e '.templates | length' "$BOM")
    for i in $(seq 0 $((template_count - 1))); do
      TEMPLATE_PATH=$(yq e ".templates[$i].path" "$BOM")
      SKELETON=$(yq e ".templates[$i].skeleton" "$BOM")
      if [[ ! -f "$TEMPLATE_PATH" && "$SKELETON" == "true" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            run echo "[DRY RUN] Would create directory $(dirname "$TEMPLATE_PATH")"
            run echo "[DRY RUN] Would create template skeleton: $TEMPLATE_PATH"
        else
            run echo "🧱 Creating template skeleton: $TEMPLATE_PATH"
            run mkdir -p "$(dirname "$TEMPLATE_PATH")"
            {
              echo "<!-- 🔮 Skeleton generated by rc-expand.sh -->"
              echo "<!DOCTYPE html>"
              echo "<html><head><title>\$title\$</title></head><body>"
              echo "\$body\$"
              echo "</body></html>"
            } > "$TEMPLATE_PATH"
        fi
      fi
    done

    # === FOLDERS ===
    folder_count=$(yq e '.folders | length' "$BOM")
    for i in $(seq 0 $((folder_count - 1))); do
      DIR=$(yq e ".folders[$i].path" "$BOM")
      run echo "📁 Ensuring folder exists: $DIR"
      if [[ "$DRY_RUN" == true ]]; then
          run echo "[DRY RUN] Would create directory $DIR"
          run echo "[DRY RUN] Would touch $DIR/.keep"
      else
          run mkdir -p "$DIR"
          run touch "$DIR/.keep"
      fi
    done


    run echo "🧾 Expand complete. Home content lives in: $HOME_DIR/"

    # === DUMP ENTIRE SCRIPT ENVIRONMENT ===
    run echo "💾 Dumping all scripts to bones/scripts/"
    if [[ "$DRY_RUN" == true ]]; then
        run echo "[DRY RUN] Would create directory bones/scripts"
    else
        run mkdir -p bones/scripts
    fi
    for script in *.sh; do
      if [[ "$DRY_RUN" == true ]]; then
          run echo "[DRY RUN] Would copy $script to bones/scripts/"
          run echo "[DRY RUN] Would chmod +x bones/scripts/$script"
      else
          run echo "🔄 Copying $script to bones/scripts/"
          run cp "$script" "bones/scripts/$script"
          run chmod +x "bones/scripts/$script"
      fi
    done

    # === COPY ROTKEEPER BOM ===
    run echo "📦 Copying BOM for environment replication"
    if [[ "$DRY_RUN" == true ]]; then
        run echo "[DRY RUN] Would create directory bones/scripts/road-to-bones"
        run echo "[DRY RUN] Would copy $BOM to bones/scripts/road-to-bones/rotkeeper-bom.yaml"
    else
        run mkdir -p bones/scripts/road-to-bones
        run cp "$BOM" bones/scripts/road-to-bones/rotkeeper-bom.yaml
    fi
    run echo "INFO rc-expand.sh completed successfully."
}

main "$@"
