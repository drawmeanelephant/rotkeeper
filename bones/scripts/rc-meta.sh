#!/usr/bin/env bash
# ============================================================
#  ██████╗  ██████╗ ████████╗██╗  ██╗███████╗███████╗██████╗
#  ██╔══██╗██╔═══██╗╚══██╔══╝██║ ██╔╝██╔════╝██╔════╝██╔══██╗
#  ██████╔╝██║   ██║   ██║   █████╔╝ █████╗  █████╗  ██████╔╝
#  ██╔══██╗██║   ██║   ██║   ██╔═██╗ ██╔══╝  ██╔══╝  ██╔═══╝
#  ██║  ██║╚██████╔╝   ██║   ██║  ██╗███████╗███████╗██║
#  ╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-meta.sh
#  Purpose : Extract structured YAML frontmatter from tombs
#  Version : 0.3.0.12
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

# =============================================================================
# Extracts frontmatter metadata from Markdown files and emits a unified YAML list
# Designed to support contentmeta, scriptmeta, and future assetmeta modes
# =============================================================================

set -euo pipefail

# Source shared environment + utils
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh" || {
  echo "[FATAL] Could not source rc-utils.sh" >&2
  exit 1
}
source_rc_env

MODE=""
VERBOSE=false
DEBUG=false

parse_flags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --contentmeta) MODE="contentmeta"; shift ;;
      --verbose) VERBOSE=true; shift ;;
      --debug) DEBUG=true; shift ;;
      --dry-run) DRY_RUN=true; shift ;;
      --help)
        echo "Usage: rc-meta.sh [--contentmeta] [--verbose] [--debug] [--dry-run]"
        echo "  --contentmeta   Extract frontmatter YAML from content tombs"
        echo "  --verbose       Print file-by-file extraction details"
        echo "  --debug         Print extracted frontmatter blocks before parsing"
        exit 0
        ;;
      *)
        echo "[ERROR] Unknown option: $1"
        exit 1
        ;;
    esac
  done
}

run_contentmeta() {
  if [[ "${DRY_RUN:-false}" == true ]]; then
    echo "[INFO] Dry run enabled. Skipping extraction."
    return 0
  fi
  local OUT="$REPORT_DIR/rotkeeper-contentmeta.yaml"
  local TMP="$(mktemp)"
  echo "[INFO] Extracting content metadata to $OUT"
  echo "" > "$OUT"

  find "$CONTENT_DIR" -name '*.md' -type f | sort | while read -r file; do
    rel="${file#$ROOT_DIR/}"
    fm=$(awk '/^---/ {count++} count==1 {next} count==2 {exit} count==1 {print}' "$file" 2>/dev/null || true)

    if [[ -n "$fm" ]] && echo "$fm" | yq eval '.' &>/dev/null; then
      echo "$fm" | yq eval ". as \$meta | {path: \"$rel\"} + \$meta" >> "$TMP"
      $VERBOSE && echo "[+] $rel"
      $DEBUG && {
        echo "----- BEGIN $rel -----"
        echo "$fm"
        echo "----- END   $rel -----"
      }
    else
      $VERBOSE && echo "[!] Skipping invalid frontmatter: $file"
      $DEBUG && {
        echo "----- INVALID: $rel -----"
        echo "$fm"
        echo "-------------------------"
      }
    fi
  done

  mv "$TMP" "$OUT"
  echo "[✔] Wrote frontmatter data to $OUT"
}

main() {
  parse_flags "$@"
  check_dependencies yq

  case "$MODE" in
    contentmeta|"")
      run_contentmeta
      ;;
    *)
      echo "[ERROR] Unknown mode: $MODE"
      exit 2
      ;;
  esac
}

main "$@"
