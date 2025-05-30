#!/usr/bin/env bash
# Source shared Rotkeeper helpers
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-scan.sh
# Purpose: Audit files vs manifest, classify orphans, and write digest reports
# Version: 0.2.1
# Updated: 2025-05-29
# -----------------------------------------
set -euo pipefail
# Initialize arrays for manifest and disk entries to avoid unbound variable under set -u
manifest_list=()
disk_list=()
IFS=$'\n\t'

# --- Flag Parsing & Helpers ---
DRY_RUN=false
VERBOSE=false
HELP=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)   DRY_RUN=true; shift ;;
    --verbose)   VERBOSE=true; shift ;;
    --help|-h)   HELP=true; shift ;;
    *) break ;;
  esac
done

show_help() {
  cat << EOF
rc-scan.sh — Audit manifest and scan environment for file reports (v0.2.1)

Usage: rc-scan.sh [options]

Options:
  --help, -h        Show this help message and exit
  --dry-run         Preview actions without writing reports
  --verbose         Print detailed logs during scanning
EOF
  exit 0
}

if [[ "$HELP" == true ]]; then
  show_help
fi

log() {
  local level="$1"; shift
  printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*"
}

run() {
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "$*"
  else
    eval "$*"
  fi
}

if [ -z "${BASH_VERSION:-}" ]; then
    echo "🚨 rc-scan.sh requires bash. Please run with: bash ./rc-scan.sh" >&2
    exit 1
fi

LOG_FILE="bones/logs/rc-scan-$(date +%Y-%m-%d_%H%M).log"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
    local level="$1"; shift
    printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" | tee -a "$LOG_FILE"
}

cleanup() {
    log "INFO" "Cleaning up after rc-scan.sh."
    # Add cleanup commands here
}
trap cleanup EXIT INT TERM

check_deps() {
    local deps=(git rsync ssh pandoc date)
    for cmd in "${deps[@]}"; do
        command -v "$cmd" >/dev/null 2>&1 || {
            log "ERROR" "$cmd required but not installed."
            exit 1
        }
    done
}

main() {
    check_deps
    log "INFO" "Running rc-scan.sh."
    # Use plain arrays for manifest and disk lists
    manifest_list=()
    disk_list=()
# rc-scan.sh — Audit manifest and scan environment for file reports
#
# Workflow:
# 1. Discover Target Paths
#    - Read bones/manifest.txt (if exists)
#    - Scan directories: home/, bones/, output/
#    Flags: --manifest-only (skip disk scan)
#
# 2. Filter & Classify
#    - Default types: png, jpg, svg, css, js, md, html, json, yaml
#    Flags: --include, --exclude
#
# 3. Compute File Metadata
#    - Path, size (bytes), mtime, checksum (SHA256)
#
# 4. Compare Against Manifest
#    - Identify missing files and orphans
#
# 5. Generate Reports
#    - JSON: bones/reports/scan-report.json
#    - Markdown: home/content/rotkeeper/scan-report.md
#    - Log: bones/logs/rc-scan.log
#
# 6. Expose Digests
#    - YAML: bones/reports/file-digests.yaml (path → checksum)
#
# 7. CLI Flags & Modes
#    - --dry-run, --verbose, --json-only, --md-only
#
# 8. Exit Codes
#    - 0: no issues
#    - >0: missing files or usage errors
#

#
# --- Configuration ---
# Set up default file paths, directories, and file type filters.
# Default configurations
MANIFEST_FILE="bones/manifest.txt"
SCAN_DIRS=("home/" "bones/" "output/")
REPORT_DIR="bones/reports"
LOG_DIR="bones/logs"
INCLUDE_EXT=("png" "jpg" "svg" "css" "js" "md" "html" "json" "yaml")
EXCLUDE_PATTERNS=()

#
# --- CLI Defaults & Argument Parsing ---
# Initialize CLI-related variables and parse command-line flags.
# CLI defaults
DRY_RUN=false
VERBOSE=false
JSON_ONLY=false
MD_ONLY=false

#
# Display usage help when requested or on error.
#
function usage {
  cat <<EOF
Usage: rc-scan.sh [flags]
Flags:
  --manifest-only   Read only manifest file, skip disk scan.
  --include <ext>   Comma-separated list of extensions to include.
  --exclude <pat>   Glob pattern to exclude (can repeat).
  --dry-run         Show actions without writing reports.
  --verbose         Print detailed logs.
  --json-only       Output only JSON report.
  --md-only         Output only Markdown report.
  -h, --help        Show this help.
EOF
  exit 1
}

#
# Parse input flags and options.
#
while [[ $# -gt 0 ]]; do
  case "$1" in
    --manifest-only) MANIFEST_ONLY=true; shift ;;
    --include) IFS=',' read -ra INCLUDE_EXT <<< "$2"; shift 2 ;;
    --exclude) EXCLUDE_PATTERNS+=("$2"); shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --verbose) VERBOSE=true; shift ;;
    --json-only) JSON_ONLY=true; shift ;;
    --md-only) MD_ONLY=true; shift ;;
    -h|--help) usage ;;
    *) echo "[ERROR] Unknown flag: $1"; usage ;;
  esac
done

#
# Create necessary report and log directories.
#
mkdir -p "$REPORT_DIR" "$LOG_DIR"

LOG_FILE="$LOG_DIR/rc-scan-$(date +%Y%m%d_%H%M%S).log"
#
# Redirect all stdout/stderr to the log file.
#
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[INFO] rc-scan started at $(date)"

#
# --- Step 1: Load Manifest ---
# Read manifest file entries into a plain array.
if [[ -f "$MANIFEST_FILE" ]]; then
  while read -r line; do
    manifest_list+=("$line")
  done < "$MANIFEST_FILE"
  log "INFO" "Loaded ${#manifest_list[@]} entries from $MANIFEST_FILE"
elif [[ "${MANIFEST_ONLY:-false}" == true ]]; then
  echo "[ERROR] Manifest file not found: $MANIFEST_FILE"; exit 2
fi

#
# --- Step 2: Disk Scan ---
# Walk specified directories, apply include/exclude filters.
if [[ "${MANIFEST_ONLY:-false}" != true ]]; then
  for dir in "${SCAN_DIRS[@]}"; do
    [[ -d "$dir" ]] || continue
    while IFS= read -r file; do
      ext="${file##*.}"
      # check include
      if [[ ! " ${INCLUDE_EXT[*]} " =~ " $ext " ]]; then
        $VERBOSE && echo "[SKIP] Extension filter: $file"
        continue
      fi
      # check exclude
      skip=false
      for pat in "${EXCLUDE_PATTERNS[@]}"; do
        [[ "$file" == $pat ]] && skip=true
      done
      $skip && { $VERBOSE && echo "[SKIP] Excluded by pattern: $file"; continue; }
      disk_list+=("$file")
    done < <(find "$dir" -type f)
  done
  echo "[INFO] Disk scan completed"
fi

#
# --- Step 3: Compare Manifest vs Disk ---
# Determine missing and orphaned files by comparing arrays.
missing=(); orphans=()
for f in "${manifest_list[@]}"; do
  [[ ! -e "$f" ]] && missing+=("$f")
done

# Add fallback for disk_list in case it is unexpectedly unbound
disk_list=("${disk_list[@]:-}")

if [[ ${#disk_list[@]} -eq 0 ]]; then
  log "WARN" "No files found during disk scan; disk_list is empty."
fi

for f in "${disk_list[@]}"; do
  [[ -z "$f" ]] && continue
  rel="${f#./}"
  if ! printf '%s\n' "${manifest_list[@]}" | grep -xq "$rel"; then
    orphans+=("$rel")
  fi
done

#
# --- Step 4: Generate File Metadata ---
# Compute SHA256 checksums for each scanned file.
# Requires bash — file path to SHA256 digest
declare -A file_checksums
for f in "${disk_list[@]}"; do
  f_clean=$(echo "$f" | tr -d '\r' | xargs)
  [[ -z "$f_clean" ]] && continue
  if [[ -f "$f_clean" ]]; then
    sha=$(shasum -a 256 "$f_clean" | awk '{print $1}')
  else
    log "WARN" "File not found for digest: $f_clean"
    sha=""
  fi
  [[ -n "$sha" ]] && file_checksums["$f_clean"]="$sha"
done

#
# --- Step 5: JSON Report ---
# Output findings in JSON format.
# 5. Write JSON report
if [[ "$MD_ONLY" == false ]]; then
  json_report="$REPORT_DIR/scan-report-$(date +%Y%m%d_%H%M%S).json"
  run "cat <<EOF > \"$json_report\"
{
  \"missing\": [\"$(IFS='\",\"'; echo "${missing[*]}")\"],
  \"orphans\": [\"$(IFS='\",\"'; echo "${orphans[*]}")\"],
  \"digests\": {
$(for f in "${!file_checksums[@]}"; do
  echo "    \"${f}\": \"${file_checksums[$f]}\","
done)
  }
}
EOF"
  if [[ "$DRY_RUN" != true ]]; then
    log "INFO" "JSON report written: $json_report"
  else
    log "DRY-RUN" "Would write JSON report to $json_report"
  fi
fi

#
# --- Step 6: Markdown Report ---
# Output findings in Markdown format.
# 6. Write Markdown report
if [[ "$JSON_ONLY" == false ]]; then
  mkdir -p "home/content/rotkeeper"
  md_report="$REPORT_DIR/scan-report-$(date +%Y%m%d_%H%M%S).md"
  run "cat <<EOF > \"$md_report\"
# Scan Report - $(date)
## Missing Files
$(for f in "${missing[@]}"; do echo "- $f"; done)
## Orphan Files
$(for f in "${orphans[@]}"; do echo "- $f"; done)
## File Digests
$(for f in "${!file_checksums[@]}"; do echo "- \`$f\`: ${file_checksums[$f]}"; done)
EOF"
  if [[ "$DRY_RUN" != true ]]; then
    log "INFO" "Markdown report written: $md_report"
  else
    log "DRY-RUN" "Would write Markdown report to $md_report"
  fi
fi

#
# --- Completion ---
# Final log entry and exit.
#
log "INFO" "rc-scan.sh completed successfully."
echo "[INFO] rc-scan completed at $(date)"
exit 0
}

main "$@"
