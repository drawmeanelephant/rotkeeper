#!/usr/bin/env bash
# Project: Rotkeeper
# Repo: https://github.com/drawmeanelephant/rotkeeper
# Script: rc-unbook.sh
# Purpose: Extract fenced scriptbook sections back into files
# Version: 0.3.0.9
# Updated: 2026-04-02
# ------------------------------------------------------------
# Part of the Rotkeeper ritual system: bones, scripts, tombs.

set -euo pipefail
IFS=$'\n\t'

SCRIPTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILS="$SCRIPTDIR/rc-utils.sh"

if [[ -f "$UTILS" ]]; then
  # shellcheck source=/dev/null
  source "$UTILS"
else
  log() {
    local level="$1"; shift
    printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*"
  }
  run() {
    if [[ "${DRYRUN:-false}" == "true" ]]; then
      log "DRY-RUN" "$*"
    else
      "$@"
    fi
  }
  initlog() { :; }
  cleanup() { :; }
  traperr() {
    local line="${1:-unknown}"
    log "ERROR" "Unhandled error on line $line"
    exit 1
  }
  requirebins() {
    local cmd
    for cmd in "$@"; do
      command -v "$cmd" >/dev/null 2>&1 || {
        log "ERROR" "Missing required dependency: $cmd"
        exit 2
      }
    done
  }
fi

ROOTDIR="$(cd "$SCRIPTDIR/.." && pwd)"
INPUT=""
OUTROOT="$ROOTDIR"
DRYRUN=false
VERBOSE=false
FORCE=false
HELP=false
MADE=0
SKIPPED=0

showhelp() {
  cat <<'HELP'
rc-unbook.sh
Extract files from a Rotkeeper scriptbook using START/END path markers.

Usage:
  rc-unbook.sh --input FILE [options]

Options:
  --input FILE     Path to the scriptbook markdown file to extract.
  --output DIR     Root directory to write extracted files into.
  --dry-run        Preview actions without writing files.
  --force          Overwrite existing files.
  --verbose        Show detailed logs.
  --help, -h       Show this help message and exit.

Expected marker format:
  <!-- START relative/path/to/file.sh -->
  ```bash
  ...file contents...
  ```
  <!-- END relative/path/to/file.sh -->
HELP
}

parseflags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --input)
        INPUT="${2:-}"
        shift 2
        ;;
      --output)
        OUTROOT="${2:-}"
        shift 2
        ;;
      --dry-run)
        DRYRUN=true
        shift
        ;;
      --force)
        FORCE=true
        shift
        ;;
      --verbose)
        VERBOSE=true
        shift
        ;;
      --help|-h)
        HELP=true
        shift
        ;;
      *)
        log "ERROR" "Unknown argument: $1"
        showhelp
        exit 1
        ;;
    esac
  done
}

cleanup() {
  [[ "$VERBOSE" == "true" ]] && log "INFO" "Cleaning up after rc-unbook.sh." || true
}

extract_with_awk() {
  local input_file="$1"
  local output_root="$2"
  local dryrun_flag="$3"
  local force_flag="$4"
  local verbose_flag="$5"

  awk \
    -v outroot="$output_root" \
    -v dryrun="$dryrun_flag" \
    -v force="$force_flag" \
    -v verbose="$verbose_flag" '
    function ltrim(s) { sub(/^[[:space:]]+/, "", s); return s }
    function rtrim(s) { sub(/[[:space:]]+$/, "", s); return s }
    function trim(s)  { return rtrim(ltrim(s)) }
    function shellquote(s,    t) {
      t = s
      gsub(/'"'"'/, "'"'"'\\'"'"''"'"'", t)
      return "'"'"'" t "'"'"'"
    }
    function vlog(msg) {
      if (verbose == "true") {
        print strftime("%Y-%m-%d %H:%M:%S") " [INFO] " msg > "/dev/stderr"
      }
    }
    function warn(msg) {
      print strftime("%Y-%m-%d %H:%M:%S") " [WARN] " msg > "/dev/stderr"
    }
    function fail(msg) {
      print strftime("%Y-%m-%d %H:%M:%S") " [ERROR] " msg > "/dev/stderr"
      exit 3
    }
    BEGIN {
      in_block = 0
      in_fence = 0
      current_path = ""
      current_file = ""
      made = 0
      skipped = 0
    }
    {
      line = $0

      if (match(line, /^<!--[[:space:]]*START[[:space:]]+(.+)[[:space:]]*-->$/, m)) {
        current_path = trim(m[1])
        if (current_path == "") fail("Encountered empty START marker path")
        current_file = outroot "/" current_path
        in_block = 1
        in_fence = 0
        vlog("Found block for " current_path)
        next
      }

      if (in_block && match(line, /^<!--[[:space:]]*END[[:space:]]+(.+)[[:space:]]*-->$/, m)) {
        end_path = trim(m[1])
        if (end_path != current_path) {
          fail("Mismatched END marker: expected " current_path ", got " end_path)
        }
        if (current_file != "") {
          close(current_file)
        }
        in_block = 0
        in_fence = 0
        current_path = ""
        current_file = ""
        next
      }

      if (!in_block) next

      if (line ~ /^```/) {
        if (!in_fence) {
          if (dryrun == "true") {
            print strftime("%Y-%m-%d %H:%M:%S") " [DRY-RUN] Would extract " current_path > "/dev/stderr"
            skipped++
            in_fence = 1
            next
          }

          cmd = "test -e " shellquote(current_file)
          exists = (system(cmd) == 0)
          if (exists && force != "true") {
            warn("Skipping existing file without --force: " current_path)
            skipped++
            current_file = ""
            in_fence = 1
            next
          }

          dir = current_file
          sub(/\/[^/]+$/, "", dir)
          if (dir != current_file) {
            system("mkdir -p " shellquote(dir))
          }
          if (exists && force == "true") {
            vlog("Overwriting " current_path)
          } else {
            vlog("Writing " current_path)
          }
          in_fence = 1
          made++
          next
        } else {
          if (current_file != "") close(current_file)
          in_fence = 0
          next
        }
      }

      if (in_fence && current_file != "") {
        print line >> current_file
      }
    }
    END {
      print "MADE=" made > "/dev/stderr"
      print "SKIPPED=" skipped > "/dev/stderr"
      if (in_block) {
        fail("Unclosed START marker at end of file")
      }
    }
  ' "$input_file" 2>&1
}

main() {
  parseflags "$@"

  if [[ "$HELP" == "true" ]]; then
    showhelp
    exit 0
  fi

  init_log rc-unbook
  trap cleanup EXIT INT TERM
  trap 'trap_err ${LINENO}' ERR

  require_bins awk mkdir date

  if [[ -z "$INPUT" ]]; then
    log "ERROR" "Missing required --input FILE"
    showhelp
    exit 1
  fi

  if [[ ! -f "$INPUT" ]]; then
    if [[ "$DRYRUN" == "true" ]]; then
      log "DRYRUN" "Input file not found: $INPUT (skipping extraction)"
      exit 0
    else
      log "ERROR" "Input file not found: $INPUT"
      exit 1
    fi
  fi

  log "INFO" "Running rc-unbook.sh."
  log "INFO" "Input scriptbook: $INPUT"
  log "INFO" "Output root: $OUTROOT"

  result="$(extract_with_awk "$INPUT" "$OUTROOT" "$DRYRUN" "$FORCE" "$VERBOSE")"

  if grep -q '^MADE=' <<< "$result"; then
    MADE="$(grep '^MADE=' <<< "$result" | tail -n1 | cut -d= -f2)"
  fi
  if grep -q '^SKIPPED=' <<< "$result"; then
    SKIPPED="$(grep '^SKIPPED=' <<< "$result" | tail -n1 | cut -d= -f2)"
  fi

  while IFS= read -r line; do
    [[ "$line" =~ ^MADE=|^SKIPPED= ]] && continue
    [[ -n "$line" ]] && printf '%s\n' "$line" >&2
  done <<< "$result"

  log "INFO" "Extraction complete. Files written: $MADE. Files skipped: $SKIPPED."
}

main "$@"
