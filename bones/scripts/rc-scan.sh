#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# ============================================================
#  ███████╗██████╗  █████╗ ███╗   ██╗
#  ██╔════╝██╔══██╗██╔══██╗████╗  ██║
#  ███████╗██║  ██║███████║██╔██╗ ██║
#  ╚════██║██║  ██║██╔══██║██║╚██╗██║
#  ███████║██████╔╝██║  ██║██║ ╚████║
#  ╚══════╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝
# ============================================================
# Env assumptions: reads BONES_DIR, CONFIG_DIR, CONTENT_DIR, DRY_RUN, LOG_DIR, LOG_FILE, OUTPUT_DIR, REPORT_DIR, ROOT_DIR, SCRIPT_DIR, TMP_DIR, VERBOSE, VERSION (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.
# CWD assumptions: No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.
# Input/Output contracts: CLI args and env vars in; files and stdout/stderr out; respects --dry-run (no writes) and --verbose.
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-scan.sh
#  Purpose : Audit the render ledger vs disk: missing, output-tree orphans, ledger digests, and digest mismatches
#  Version : 0.5.2
#  Updated : 2026-08-27
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

# Initialize arrays for manifest and disk entries to avoid unbound variable under set -u
manifest_list=()
disk_list=()


# ---
# show_help: Print scan usage and exit.
# Inputs: $1 (optional exit code)
# Outputs: Prints help to stdout and exits
# Env: Reads BONES_DIR, CONFIG_DIR, CONTENT_DIR, DRY_RUN, LOG_DIR, OUTPUT_DIR ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
show_help() {
  cat <<EOF
rc-scan.sh — Audit manifest and scan environment for file reports (v${VERSION:-unknown})

Usage:
  rotkeeper.sh scan [flags]

Description:
  Audits the render ledger (bones/manifest.txt) against disk:
  missing = ledger entries absent from disk; orphans = files under the
  rendered output tree that the ledger does not list (output/assets/
  is exempt — owned by the assets ritual); digests = SHA-256 of
  ledger-listed files present on disk; digest_mismatches = ledger
  entries with a recorded SHA-256 (pack's two-space format) whose
  on-disk digest differs or whose file is absent. Writes Markdown/JSON
  reports to bones/reports/.

Flags:
  --manifest-only   Read only manifest file, skip the output-tree walk.
  --include <ext>   Comma-separated extensions to include in the orphan walk.
  --exclude <pat>   Glob pattern to exclude from the orphan walk (can repeat).
  --json            Emit machine-readable JSON to stdout (report files unchanged).
  --json-only       Output only JSON report.
  --md-only         Output only Markdown report.
  --dry-run         Show actions without writing reports.
  --verbose         Print detailed logs.
  -h, --help        Show this help message and exit.
  --version, -v     Show script version and quit.

Examples:
  bash rotkeeper.sh scan                                     Full audit
  bash rotkeeper.sh scan --manifest-only                     Manifest check only
  bash rotkeeper.sh scan --include md,textile --dry-run      Filtered preview
  bash rotkeeper.sh scan --json | jq .                       Machine-readable output

Exit codes:
  0    Success
  1    Environment failure
  2    Manifest file missing
EOF
  exit "${1:-0}"
}


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
rk_init_script "rc-scan" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR OUTPUT_DIR

if [ -z "${BASH_VERSION:-}" ]; then
    echo "🚨 rc-scan.sh requires bash. Please run with: bash ./rc-scan.sh" >&2
    exit 1
fi



# ---
# main: Audit render ledger vs disk, classify output-tree orphans, emit reports.
# Inputs: $@ (flags: --manifest-only, --include, --exclude, --json, --json-only, --md-only)
# Outputs: Writes scan reports to REPORT_DIR; logs digests and orphans
# Env: Reads BONES_DIR, CONTENT_DIR, DRY_RUN, LOG_DIR, LOG_FILE, OUTPUT_DIR ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
main() {
    require_bins bash jq
    require_sha256
    log "INFO" "Running rc-scan.sh."
    # Use plain arrays for manifest and disk lists
    manifest_list=()
    disk_list=()
#
# --- Output Artifacts ---
# rc-scan.sh emits two optional report types (controlled by flags):
#   - JSON Report: bones/reports/scan-report-YYYYMMDD_HHMMSS.json
#   - Markdown Report: bones/reports/scan-report-YYYYMMDD_HHMMSS.md
# Each report includes:
#   - Missing Files: listed in the ledger but absent from disk
#   - Orphan Files: under OUTPUT_DIR but absent from the ledger (assets tree exempt)
#   - File Digests: SHA256 of ledger-listed files present on disk
#   - Digest Mismatches: ledger entries with recorded SHA-256 whose on-disk digest differs
#

#
# --- Configuration ---
# Set up default file paths, directories, and file type filters.
# Default configurations
MANIFEST_FILE="${BONES_DIR#"$ROOT_DIR"/}/manifest.txt"
SCAN_DIRS=("${OUTPUT_DIR#"$ROOT_DIR"/}/")
REPORT_DIR="${REPORT_DIR#"$ROOT_DIR"/}"
LOG_DIR="${LOG_DIR#"$ROOT_DIR"/}"
INCLUDE_EXT=("png" "jpg" "svg" "css" "js" "md" "html" "json" "yaml")
EXCLUDE_PATTERNS=()

#
# --- CLI Defaults & Argument Parsing ---
# Initialize CLI-related variables and parse command-line flags.
# CLI defaults
JSON_MODE=false
JSON_ONLY=false
MD_ONLY=false

#
# Parse input flags and options.
#
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version|-v) echo "$(basename "$0") v${VERSION:-unknown}"; exit 0 ;;
    --manifest-only) MANIFEST_ONLY=true; shift ;;
    --include) IFS=',' read -ra INCLUDE_EXT <<< "$2"; shift 2 ;;
    --exclude) EXCLUDE_PATTERNS+=("$2"); shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --verbose) VERBOSE=true; shift ;;
    --json) JSON_MODE=true; shift ;;
    --json-only) JSON_ONLY=true; shift ;;
    --md-only) MD_ONLY=true; shift ;;
    -h|--help) show_help ;;
    *) echo "[ERROR] Unknown flag: $1"; show_help 2 ;;
  esac
done

#
# Create necessary report and log directories.
#
  # SIDE EFFECT (write): creates bones/reports and bones/logs if missing
mkdir -p "$REPORT_DIR" "$LOG_DIR"

# --dry-run must stay non-mutating: the per-run scan log is only opened for
# real runs.
if [[ "${DRY_RUN:-false}" != true ]]; then
  # SIDE EFFECT (write): opens a fresh per-run scan log under bones/logs (real runs only)
  LOG_FILE="$LOG_DIR/rc-scan-$(date +%Y%m%d_%H%M%S).log"

  echo "[INFO] rc-scan started at $(date)"
fi

#
# --- Step 1: Load Manifest ---
# Read manifest file entries into a plain array.
if [[ -f "$MANIFEST_FILE" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    clean_line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [[ -z "$clean_line" || "$clean_line" =~ ^# ]] && continue
    manifest_list+=("$clean_line")
  done < "$MANIFEST_FILE"
  log "INFO" "Loaded ${#manifest_list[@]} entries from $MANIFEST_FILE"
elif [[ "${MANIFEST_ONLY:-false}" == true ]]; then
  echo "[ERROR] Manifest file not found: $MANIFEST_FILE"; exit 2
fi

#
# --- Step 2: Disk Scan ---
# Walk the rendered output tree, apply include/exclude filters. Orphan
# classification is output-scoped: the manifest is the render ledger, and
# source/system files outside OUTPUT_DIR are not ledger material.
if [[ "${MANIFEST_ONLY:-false}" != true ]]; then
  for dir in ${SCAN_DIRS[@]+"${SCAN_DIRS[@]}"}; do
    [[ -d "$dir" ]] || continue
    while IFS= read -r file; do
      ext="${file##*.}"
      # check include: exact-match loop. A "${INCLUDE_EXT[*]}" join inherits
      # the script's newline-leading IFS, so the previous " $ext " regex
      # against that string could never match and the walk stayed empty (#292).
      include_hit=false
      for inc in ${INCLUDE_EXT[@]+"${INCLUDE_EXT[@]}"}; do
        if [[ "$inc" == "$ext" ]]; then include_hit=true; break; fi
      done
      if [[ "$include_hit" != true ]]; then
        $VERBOSE && echo "[SKIP] Extension filter: $file"
        continue
      fi
      # check exclude
      skip=false
      for pat in ${EXCLUDE_PATTERNS[@]+"${EXCLUDE_PATTERNS[@]}"}; do
        [[ "$file" == $pat ]] && skip=true
      done
      $skip && { $VERBOSE && echo "[SKIP] Excluded by pattern: $file"; continue; }
      disk_list+=("$file")
    # find prune: skip the assets tree (output/assets is owned by the assets
    # ritual, not the ledger), volatile dirs, and emit only regular files
    done < <(find "$dir" \( -type d -a \( -path "${dir}assets" -o -name "tmp" -o -name "logs" -o -name "archive" -o -name "reports" -o -name "book-reports" \) -prune \) -o \( -type f -print \))
  done
  echo "[INFO] Disk scan completed"
fi

#
# --- Step 3: Compare Manifest vs Disk ---
# Determine missing (ledger entries absent from disk) and orphaned files
# (output-tree files the ledger does not list) against normalized paths.
missing=(); orphans=()
manifest_paths=()

for f in ${manifest_list[@]+"${manifest_list[@]}"}; do
  p="${f%%  *}"
  p="${p%% *}"
  p="${p#"$ROOT_DIR"/}"
  p="${p#./}"
  [[ -n "$p" ]] && manifest_paths+=("$p")
done

for rel_f in ${manifest_paths[@]+"${manifest_paths[@]}"}; do
  [[ ! -e "$rel_f" && ! -e "$ROOT_DIR/$rel_f" ]] && missing+=("$rel_f")
done

# No padding fallback: disk_list stays a real (possibly empty) array so the
# empty-walk warning below can actually fire (#292). Downstream loops use
# guarded expansions under set -u.
if [[ ${#disk_list[@]} -eq 0 ]]; then
  log "WARN" "No files found during the output-tree walk; orphan scope is empty."
fi

for f in ${disk_list[@]+"${disk_list[@]}"}; do
  [[ -z "$f" ]] && continue
  rel="${f#"$ROOT_DIR"/}"
  rel="${rel#./}"
  if ! printf '%s\n' ${manifest_paths[@]+"${manifest_paths[@]}"} | grep -xq "$rel"; then
    orphans+=("$rel")
  fi
done

#
# --- Step 4: Generate File Metadata ---
# Compute SHA256 checksums for each manifest-listed file present on disk
# (ledger verification; entries absent from disk are reported in missing[]).
# Requires bash — file path to SHA256 digest
declare -A file_checksums=()
for f in ${manifest_paths[@]+"${manifest_paths[@]}"}; do
  target="$f"
  [[ -f "$target" ]] || target="$ROOT_DIR/$f"
  if [[ -f "$target" ]]; then
    sha=$(rk_sha256 "$target" | awk '{print $1}')
    [[ -n "$sha" ]] && file_checksums["$f"]="$sha"
  fi
done

#
# --- Step 4a: Ledger Integrity (digest_mismatches) ---
# Manifest lines recorded by pack as "<path>  <sha256>" carry the expected
# digest. Verify each such line against the on-disk SHA-256; a mismatch
# signals tamper/drift, a missing file is already in missing[] but also
# surfaced here with actual null for a single audit view.
declare -A expected_sha=()
for raw in ${manifest_list[@]+"${manifest_list[@]}"}; do
  # pack uses exactly two spaces between path and lowercase hex sha256
  if [[ "$raw" =~ ^(.+)[[:space:]]{2}([0-9a-fA-F]{64})$ ]]; then
    e_path="${BASH_REMATCH[1]}"
    e_sha="${BASH_REMATCH[2]}"
    e_path="${e_path%%  *}"
    e_path="${e_path%% *}"
    e_path="${e_path#"$ROOT_DIR"/}"
    e_path="${e_path#./}"
    [[ -n "$e_path" ]] && expected_sha["$e_path"]="${e_sha,,}"
  fi
done

digest_mismatches=()
for e_path in "${!expected_sha[@]}"; do
  e_sha="${expected_sha[$e_path]}"
  target="$e_path"
  [[ -f "$target" ]] || target="$ROOT_DIR/$e_path"
  if [[ ! -f "$target" ]]; then
    # missing — record with actual null (jq will encode as JSON null)
    digest_mismatches+=("$e_path|$e_sha|")
  else
    actual=$(rk_sha256 "$target" | awk '{print $1}')
    actual="${actual,,}"
    if [[ "$actual" != "$e_sha" ]]; then
      digest_mismatches+=("$e_path|$e_sha|$actual")
    fi
  fi
done

#
# --- Step 4b: Machine-Readable Stdout (--json) ---
# --json emits a single schema-tagged JSON object on fd 3 so it stays visible
# to callers even in quiet mode. Report files are written exactly as without
# the flag; human-visible MARKER/log behavior is unchanged.
if [[ "$JSON_MODE" == true ]]; then
  mkdir -p "$TMP_DIR"

  missing_json="[]"
  if [[ ${#missing[@]} -gt 0 ]]; then
    missing_json=$(printf '%s\n' "${missing[@]}" | jq -R . | jq -s .)
  fi

  orphans_json="[]"
  if [[ ${#orphans[@]} -gt 0 ]]; then
    orphans_json=$(printf '%s\n' "${orphans[@]}" | jq -R . | jq -s .)
  fi

  digests_json="{}"
  if [[ ${#file_checksums[@]} -gt 0 ]]; then
    digests_json=$(
      for f in "${!file_checksums[@]}"; do
        printf '%s\t%s\n' "$f" "${file_checksums[$f]}"
      done | LC_ALL=C sort | jq -Rn '
        [inputs | select(length > 0) | split("\t")]
        | map({key: .[0], value: .[1]})
        | from_entries
      '
    )
  fi

  mismatches_json="[]"
  if [[ ${#digest_mismatches[@]} -gt 0 ]]; then
    mismatches_json=$(
      for entry in "${digest_mismatches[@]}"; do
        IFS='|' read -r m_path m_exp m_act <<< "$entry"
        # Encode actual as JSON null when empty (missing file)
        if [[ -z "$m_act" ]]; then
          jq -n --arg path "$m_path" --arg exp "$m_exp" '{path: $path, expected: $exp, actual: null}'
        else
          jq -n --arg path "$m_path" --arg exp "$m_exp" --arg act "$m_act" '{path: $path, expected: $exp, actual: $act}'
        fi
      done | jq -s 'sort_by(.path)'
    )
  fi

  # SIDE EFFECT (write): creates a bones/tmp scratch file for stdout JSON assembly
  json_out="$TMP_DIR/scan-json-stdout.$$"
  {
    echo "{"
    printf '  "schema": "rotkeeper.scan.v2",\n'
    printf '  "generated_at": "%s",\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '  "manifest": %s,\n' "$(printf '%s' "$MANIFEST_FILE" | jq -R .)"
    printf '  "counts": {"missing": %d, "orphans": %d, "digest_mismatches": %d},\n' "${#missing[@]}" "${#orphans[@]}" "${#digest_mismatches[@]}"
    printf '  "missing": %s,\n' "$missing_json"
    printf '  "orphans": %s,\n' "$orphans_json"
    printf '  "digest_count": %d,\n' "${#file_checksums[@]}"
    printf '  "digests": %s,\n' "$digests_json"
    printf '  "digest_mismatches": %s\n' "$mismatches_json"
    echo "}"
  } > "$json_out"

  # Fail closed on malformed JSON rather than shipping it to CI consumers.
  if ! jq empty "$json_out" >/dev/null 2>&1; then
    log "ERROR" "scan --json generated invalid JSON; scratch copy kept at $json_out"
    cat "$json_out" >&2
    exit 1
  fi

  # SIDE EFFECT (write): appends the stdout JSON object to the per-run log
  if [[ -n "${LOG_FILE:-}" ]]; then
    cat "$json_out" >> "$LOG_FILE"
  fi
  cat "$json_out" >&3 2>/dev/null || cat "$json_out"
  # SIDE EFFECT (delete): removes the stdout JSON scratch file after emit
  rm -f "$json_out"
fi

#
# --- Step 5: JSON Report ---
# Output findings in JSON format.
# 5. Write JSON report
if [[ "$MD_ONLY" == false ]]; then
  json_report="$REPORT_DIR/scan-report-$(date +%Y%m%d_%H%M%S).json"
  if [[ "$DRY_RUN" != true ]]; then
    missing_json="[]"
    if [[ ${#missing[@]} -gt 0 ]]; then
      missing_json=$(printf '%s\n' "${missing[@]}" | jq -R . | jq -s .)
    fi

    orphans_json="[]"
    if [[ ${#orphans[@]} -gt 0 ]]; then
      orphans_json=$(printf '%s\n' "${orphans[@]}" | jq -R . | jq -s .)
    fi

    mismatches_json_report="[]"
    if [[ ${#digest_mismatches[@]} -gt 0 ]]; then
      mismatches_json_report=$(
        for entry in "${digest_mismatches[@]}"; do
          IFS='|' read -r m_path m_exp m_act <<< "$entry"
          if [[ -z "$m_act" ]]; then
            jq -n --arg path "$m_path" --arg exp "$m_exp" '{path: $path, expected: $exp, actual: null}'
          else
            jq -n --arg path "$m_path" --arg exp "$m_exp" --arg act "$m_act" '{path: $path, expected: $exp, actual: $act}'
          fi
        done | jq -s 'sort_by(.path)'
      )
    fi

    # SIDE EFFECT (write): writes bones/reports/scan-report-<ts>.json (real runs only)
    cat > "$json_report" <<EOF
{
  "missing": $missing_json,
  "orphans": $orphans_json,
  "digests": {
$(for f in "${!file_checksums[@]}"; do
  echo "    \"${f}\": \"${file_checksums[$f]}\","
done | sed '$ s/,$//')
  },
  "digest_mismatches": $mismatches_json_report
}
EOF
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
  md_report="$REPORT_DIR/scan-report-$(date +%Y%m%d_%H%M%S).md"
  if [[ "$DRY_RUN" != true ]]; then
    # SIDE EFFECT (write): writes bones/reports/scan-report-<ts>.md (real runs only)
    cat > "$md_report" <<EOF
# Scan Report - $(date)
## Missing Files
$(for f in ${missing[@]+"${missing[@]}"}; do echo "- $f"; done)
## Orphan Files
$(for f in ${orphans[@]+"${orphans[@]}"}; do echo "- $f"; done)
## File Digests
$(for f in "${!file_checksums[@]}"; do echo "- \`$f\`: ${file_checksums[$f]}"; done)
## Digest Mismatches
$(if [[ ${#digest_mismatches[@]} -eq 0 ]]; then echo "- none"; else for entry in "${digest_mismatches[@]}"; do IFS='|' read -r m_path m_exp m_act <<< "$entry"; if [[ -z "$m_act" ]]; then echo "- \`$m_path\`: expected $m_exp, actual missing"; else echo "- \`$m_path\`: expected $m_exp, actual $m_act"; fi; done; fi)
EOF
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
