#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-audit.sh
# Purpose: Audit markdown files for valid asset-meta frontmatter blocks from manifest list
# Version: 0.1.9.9
# Updated: 2025-05-27
# -----------------------------------------
set -euo pipefail
VERBOSE=false
DRY_RUN=false
FIX_MODE=false
REPORT_DIR="$REPORT_DIR"
REPORT_JSON="$REPORT_DIR/asset-audit.json"
REPORT_MD="$REPORT_DIR/asset-audit.md"
MANIFEST="$CONFIG_DIR/asset-manifest.yaml"
LOG_FILE="$LOG_DIR/rc-audit-$(date +%Y-%m-%d_%H%M).log"
mkdir -p "$(dirname "$LOG_FILE")" "$REPORT_DIR"
IFS=$'\n\t'

init_log "rc-audit"

main() {
    check_dependencies
    log "INFO" "Running rc-audit.sh."
# rc-audit.sh — Rotkeeper Asset-Meta Audit
#
# Purpose:
#   - Verify every file listed in asset-manifest.yaml contains a proper asset-meta block.
#   - Detect missing or malformed front-matter metadata.
#
# Gameplan / Workflow Steps:
#   1. Setup & Configuration
#      - Define manifest path, report/log directories, CLI flags (dry-run, verbose, fix mode).
#
#   2. Load Manifest Entries
#      - Parse asset-manifest.yaml to extract file paths into an array.
#
#   3. Iterate Over Files
#      For each path in manifest:
#        a. Check existence of the file.
#        b. Open file and search for 'asset-meta:' at the start of front-matter.
#        c. If missing or malformed, record an error.
#        d. If --fix flag is enabled, inject a metadata template stub.
#
#   4. Reporting
#      - Collect all errors and optionally fixes.
#      - Write JSON report and/or Markdown report to reports directory.
#
#   5. Exit Codes
#      - 0: all files passed audit or fixes applied.
#      - 1: errors found (missing/malformed metadata).
#      - 2: missing manifest file or critical failures.
#
# Next Steps:
#   - Implement CLI parsing (dry-run, verbose, fix).
#   - Flesh out each step with actual Bash logic.
#   - Add detailed logging for CI integration.
#
# --- Step 1: Parse CLI Flags ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --verbose) VERBOSE=true; shift ;;
    --fix) FIX_MODE=true; shift ;;
    --help|-h)
      echo "Usage: rc-audit.sh [--dry-run] [--verbose] [--fix]"
      exit 0
      ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

# --- Step 2: Load Manifest Entries ---
if [[ ! -f "$MANIFEST" ]]; then
  log "ERROR" "Missing asset manifest at: $MANIFEST"
  exit 2
fi

mapfile -t FILE_LIST < <(yq e '.[].path' "$MANIFEST" | grep -v '^null$')
log "INFO" "Loaded ${#FILE_LIST[@]} files from manifest."

  # --- Step 3: Iterate Over Files ---
  TEMPLATE_CONFIG="$CONFIG_DIR/audit-meta.yaml"
  TODAY=$(date +%F)

  # Load the YAML stub block using yq and convert it to a string
  STUB_FRONTMATTER=$(yq e '.defaults' "$TEMPLATE_CONFIG" | sed "s/{{today}}/$TODAY/g")
  if [[ "$VERBOSE" == true ]]; then
    echo "-----[ Parsed Stub Frontmatter ]-----"
    echo "$STUB_FRONTMATTER"
    echo "-------------------------------------"
  fi

  PASSED=0
  FAILED=0
  FIXED=0
  SKIPPED=0
  MISSING=0

  for REL_PATH in "${FILE_LIST[@]}"; do
    FILE="$ASSETS_DIR/$REL_PATH"
    if [[ ! -f "$FILE" ]]; then
      log "ERROR" "Missing file: $REL_PATH"
      ((MISSING++))
      continue
    fi

    if [[ "$FILE" != *.md ]]; then
      log "SKIP" "Not a markdown file: $REL_PATH"
      continue
    fi

    if ! grep -q '^---' "$FILE"; then
      log "ERROR" "No frontmatter in $REL_PATH"
      if [[ "$FIX_MODE" == true ]]; then
        log "FIX" "Injecting stub frontmatter into $REL_PATH"
        echo -e "---\n$STUB_FRONTMATTER\n---\n$(cat "$FILE")" > "$FILE"
      fi
      continue
    fi

    if ! yq e '.asset-meta' "$FILE" &>/dev/null; then
      log "ERROR" "Missing asset-meta block in $REL_PATH"
      if [[ "$FIX_MODE" == true ]]; then
        log "FIX" "Adding asset-meta to frontmatter in $REL_PATH"
        TMPFILE=$(mktemp)
        awk '/^---$/ && ++c==2 { print "---\n'"$STUB_FRONTMATTER"'\n---"; next } 1' "$FILE" > "$TMPFILE"
        mv "$TMPFILE" "$FILE"
      fi
    else
      log "PASS" "Valid asset-meta in $REL_PATH"
    fi
  done

  # --- Step 4: Reporting ---

  for LINE in "${LOG_ENTRIES[@]}"; do
    if [[ "$LINE" == *"PASS"* ]]; then
      ((PASSED++))
    elif [[ "$LINE" == *"FIX"* ]]; then
      ((FIXED++))
    elif [[ "$LINE" == *"ERROR"* ]]; then
      ((FAILED++))
    elif [[ "$LINE" == *"SKIP"* ]]; then
      ((SKIPPED++))
    fi
  done

  echo "# Asset Audit Report – $(date +%F)" > "$REPORT_MD"
  echo "- Total Files: ${#FILE_LIST[@]}" >> "$REPORT_MD"
  echo "- Passed: $PASSED" >> "$REPORT_MD"
  echo "- Fixed: $FIXED" >> "$REPORT_MD"
  echo "- Failed: $FAILED" >> "$REPORT_MD"
  echo "- Skipped: $SKIPPED" >> "$REPORT_MD"
  echo "- Missing: $MISSING" >> "$REPORT_MD"
  echo "" >> "$REPORT_MD"
  printf '%s\n' "${LOG_ENTRIES[@]}" >> "$REPORT_MD"

  jq -n --arg date "$(date +%F)" \
        --argjson total ${#FILE_LIST[@]} \
        --argjson passed $PASSED \
        --argjson fixed $FIXED \
        --argjson failed $FAILED \
        --argjson skipped $SKIPPED \
        --argjson missing $MISSING \
        '{date: $date, total: $total, passed: $passed, fixed: $fixed, failed: $failed, skipped: $skipped, missing: $missing}' > "$REPORT_JSON"

  # --- Step 5: Exit with appropriate code ---
  if (( MISSING > 0 || FAILED > 0 )); then
    log "INFO" "Audit completed with $FAILED failed and $MISSING missing file(s)."
    exit 1
  else
    log "INFO" "Audit successful: all files passed or were fixed."
    exit 0
  fi
}

main "$@"
