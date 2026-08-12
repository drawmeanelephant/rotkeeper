#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# ---
# rk_load_env: The canonical sequence to load the environment.
# Callers source rc-utils.sh, which automatically calls rk_load_env strict (unless ROT_SKIP_ENV=true) when initializing via rk_init_script.
# ---
rk_load_env() {
  local mode="${1:-strict}"

  local env_file
  env_file="$(dirname "${BASH_SOURCE[0]:-$0}")/rc-env.sh"
  if [[ -f "$env_file" ]]; then
     source "$env_file"
  else
     log "WARN" "rc-env.sh not found at $env_file"
  fi


  # Policy validation is kept separate from environment derivation.
  if [[ "$mode" == "strict" ]]; then
      # Ensure environment load validates that required layout-derived variables are set
      require_env_vars ROOT_DIR BONES_DIR CONTENT_DIR OUTPUT_DIR TEMPLATE_DIR ASSETS_DIR DOCS_DIR HELP_DIR META_DIR LOG_DIR TMP_DIR CONFIG_DIR ARCHIVE_DIR RELEASE_DIR REPORT_DIR BOOK_REPORT_DIR SCRIPT_DIR WEB_DIR

      local target_config="${CONFIG_DIR}/rotkeeper.yaml"
      if [[ -s "$target_config" ]]; then
        if ! yq eval '.' "$target_config" >/dev/null 2>&1; then
          log "FATAL" "YAML configuration is malformed at $target_config"
          exit 1
        fi
      fi

      validate_layout_alignment "strict"
  elif [[ "$mode" == "bootstrap" ]]; then
      validate_layout_alignment "bootstrap"
  fi
}

# ============================================================
#  ██╗   ██╗████████╗██╗██╗     ███████╗
#  ██║   ██║╚══██╔══╝██║██║     ██╔════╝
#  ██║   ██║   ██║   ██║██║     ███████╗
#  ██║   ██║   ██║   ██║██║     ╚════██║
#  ╚██████╔╝   ██║   ██║███████╗███████║
#   ╚═════╝    ╚═╝   ╚═╝╚══════╝╚══════╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-utils.sh
#  Purpose : Shared Rotkeeper helper functions and runtime sanity wrappers
#  Version : 0.5.1
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

set -euo pipefail
IFS=$'\n\t'


# --- Global Flags ---
DRY_RUN=false
VERBOSE=false
QUIET=true
DEBUG=false
HELP=false

# Parse common flags: --dry-run, --verbose, --help
# ---
# parse_flags: Interprets the whispered command-line flags (--dry-run, --verbose, --help)
# Inputs: $@ (all arguments)
# Outputs: Modifies global DRY_RUN, VERBOSE, HELP flags
# ---
# Interprets the whispered command-line flags (--dry-run, --verbose, --help)
parse_flags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --version|-v) echo "$(basename "$0") v${VERSION:-unknown}"; exit 0 ;;
      --dry-run)   DRY_RUN=true; shift ;;
      --verbose)   VERBOSE=true; QUIET=false; shift ;;
      --quiet)     QUIET=true; shift ;;
      --debug)     DEBUG=true; VERBOSE=true; QUIET=false; shift ;;
      --help|-h)   HELP=true; shift ;;
      *) break ;;
    esac
  done
}

# Default help handler (can be overridden by scripts)
# ---
# show_help: Displays the eternal void (default help text) if a script has no manual
# ---
# Displays the eternal void (default help text) if a script has no manual
if ! declare -f show_help > /dev/null; then
  show_help() {
    log "INFO" "No help available for this command."
    exit 0
  }
fi

# Logging function: prints timestamped messages and writes to $LOG_FILE if set
# ---
# log: Writes timestamped missives to the console and to the sacred $LOG_FILE
# Inputs: $1 (Level: INFO, ERROR, WARN), $2+ (Message)
# ---
log() {
  local level="$1"; shift
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  local msg="[$ts] [$level] $*"

  # Three-tier verbosity filter for standard stdout
  if [[ "$level" == "MARKER" ]]; then
    echo "$*" >&3
  elif [[ "$QUIET" == true && ( "$level" == "INFO" || "$level" == "DEBUG" || "$level" == "WARN" || "$level" == "DRY-RUN" ) ]]; then
    : # Skip stdout
  elif [[ "$level" == "DEBUG" && "$DEBUG" != true ]]; then
    : # Skip stdout
  else
    echo "$msg" >&3
  fi

  # Always write standard logs to file if present
  if [[ -n "${LOG_FILE:-}" ]]; then
    if [[ "$level" == "MARKER" ]]; then
      echo "[$ts] [MARKER] $*" >> "$LOG_FILE"
    else
      echo "$msg" >> "$LOG_FILE"
    fi
  fi
}

# Runner: dry-run and verbose wrapper for commands
run() {
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log "DRY-RUN" "$*"
  else
    [[ "$VERBOSE" == true ]] && log "INFO" "$*"
    command "$@"
  fi
}

# Require explicitly listed command-line tools (use in main scripts)
# ---
# require_bins: Checks if the required earthly binaries exist in the PATH
# Inputs: $@ (List of binary names like 'jq' or 'gawk')
# Outputs: Exits with code 2 if a tool is missing
# ---
# Checks if the required earthly binaries exist in the PATH
require_bins() {
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      log "ERROR" "Missing required dependency: $cmd"
      exit 2
    fi
  done
}

# Portable SHA-256 checksum: prefer sha256sum (Linux), fall back to
# shasum -a 256 (macOS) so scripts run on either without coreutils.
rk_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$@"
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$@"
  else
    log "ERROR" "Missing SHA-256 tool: need sha256sum or shasum"
    return 1
  fi
}

# Preflight that a SHA-256 tool exists before checksum-using code runs.
require_sha256() {
  if ! command -v sha256sum >/dev/null 2>&1 && ! command -v shasum >/dev/null 2>&1; then
    log "ERROR" "Missing SHA-256 tool: need sha256sum or shasum (e.g. brew install coreutils)"
    exit 2
  fi
}

# Build N levels of "../" using only Bash (replaces hidden `seq` usage).
rk_up_dirs() {
  local n="${1:-0}" i=0 out=""
  for ((i = 0; i < n; i++)); do
    out+="../"
  done
  printf '%s' "$out"
}

# Require yq version 4.x or higher (Go-based CLI)
require_yq_version() {
  if ! yq eval '.foo' <<< 'foo: bar' >/dev/null 2>&1; then
    log "ERROR" "yq version 4.x required. Install from https://github.com/mikefarah/yq"
    exit 2
  fi
}

# Require GNU awk (gawk) instead of macOS/BSD awk. The gawk binary itself is
# checked directly because scripts invoke `gawk` by name; probing `awk`
# reports BSD awk on macOS even when gawk is installed.
require_gawk_version() {
  if ! command -v gawk >/dev/null 2>&1 || ! gawk --version 2>&1 | grep -qi 'GNU Awk'; then
    log "ERROR" "GNU Awk required. Install it via: brew install gawk"
    exit 2
  fi
}

# Output tree ownership marker. Stale-output deletion is only permitted when
# the output tree carries this marker, proving a generator produced it.
OUTPUT_MARKER_NAME=".rotkeeper-generated"

mark_output_generated() {
  local out_dir="${1:-${OUTPUT_DIR:-}}"
  if [[ -z "$out_dir" ]]; then
    log "ERROR" "Cannot mark output tree: OUTPUT_DIR is not set"
    return 1
  fi
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log "DRY-RUN" "Would mark output tree as generated: $out_dir/$OUTPUT_MARKER_NAME"
    return 0
  fi
  mkdir -p "$out_dir"
  : > "$out_dir/$OUTPUT_MARKER_NAME"
  log "INFO" "Output tree marked as generated: $out_dir/$OUTPUT_MARKER_NAME"
}

output_is_generated() {
  local out_dir="${1:-${OUTPUT_DIR:-}}"
  [[ -n "$out_dir" && -f "$out_dir/$OUTPUT_MARKER_NAME" ]]
}





# ---
# validate_layout_alignment: Validates configured path cache against current runtime context.
# Ensures the repository has not been broken, moved, or corrupted since initialization.
# ---
validate_layout_alignment() {
  local mode="${1:-strict}"
  local target_config="${CONFIG_DIR:-${ROOT_DIR:-$PWD}/bones/config}/rotkeeper.yaml"
  if [[ ! -f "$target_config" ]]; then
    target_config="${ROOT_DIR:-$PWD}/config/rotkeeper.yaml"
  fi
  if [[ ! -f "$target_config" ]]; then
    target_config="${PWD}/bones/config/rotkeeper.yaml"
  fi

  local style="crypt"
  local root_fallback="${ROOT_DIR:-$PWD}"
  local config_source="layout default"

  local expected_content
  local expected_output
  local expected_bones
  local expected_templates
  local expected_assets
  local expected_docs
  local expected_meta

  if [[ -f "$target_config" ]]; then
      style=$(yq eval '.layout_style // "crypt"' "$target_config" 2>/dev/null || echo "crypt")

      local has_paths
      has_paths=$(yq eval 'has("paths")' "$target_config" 2>/dev/null || echo "false")

      if [[ "$has_paths" == "true" ]]; then
          config_source="config paths"
          local saved_root
          saved_root=$(yq eval '.paths.ROOT_DIR // ""' "$target_config" 2>/dev/null)

          if [[ -n "$saved_root" && "$saved_root" != "$root_fallback" ]]; then
              if [[ "$mode" != "bootstrap" ]]; then
                  echo "[ERROR] Environment relocation mismatch detected." >&2
                  echo "  -> Expected Root (from config) : $saved_root" >&2
                  echo "  -> Actual Root (runtime)       : $root_fallback" >&2
                  echo "  -> Fix: Reinitialize environment using './rotkeeper.sh init' to repair paths." >&2
                  exit 1
              fi
          fi

          expected_content=$(yq eval '.paths.CONTENT_DIR // ""' "$target_config" 2>/dev/null)
          expected_output=$(yq eval '.paths.OUTPUT_DIR // ""' "$target_config" 2>/dev/null)
          expected_bones=$(yq eval '.paths.BONES_DIR // ""' "$target_config" 2>/dev/null)
          expected_templates=$(yq eval '.paths.TEMPLATE_DIR // ""' "$target_config" 2>/dev/null)
          expected_assets=$(yq eval '.paths.ASSETS_DIR // ""' "$target_config" 2>/dev/null)
          expected_docs=$(yq eval '.paths.DOCS_DIR // ""' "$target_config" 2>/dev/null)
          expected_meta=$(yq eval '.paths.META_DIR // ""' "$target_config" 2>/dev/null)

          # Validate internal path coherency: ensure paths are within ROOT_DIR
          if [[ "$mode" != "bootstrap" ]]; then
              for p_name in CONTENT_DIR OUTPUT_DIR BONES_DIR TEMPLATE_DIR ASSETS_DIR DOCS_DIR META_DIR; do
                  local p_val="${!p_name:-}"
                  if [[ "$p_name" == "CONTENT_DIR" ]]; then p_val="$expected_content"; fi
                  if [[ "$p_name" == "OUTPUT_DIR" ]]; then p_val="$expected_output"; fi
                  if [[ "$p_name" == "BONES_DIR" ]]; then p_val="$expected_bones"; fi
                  if [[ "$p_name" == "TEMPLATE_DIR" ]]; then p_val="$expected_templates"; fi
                  if [[ "$p_name" == "ASSETS_DIR" ]]; then p_val="$expected_assets"; fi
                  if [[ "$p_name" == "DOCS_DIR" ]]; then p_val="$expected_docs"; fi
                  if [[ "$p_name" == "META_DIR" ]]; then p_val="$expected_meta"; fi

                  if [[ -z "$p_val" || "$p_val" == "null" ]]; then
                      echo "[ERROR] Corrupted path cache." >&2
                      echo "  -> Expected value for $p_name is empty or missing in config paths." >&2
                      echo "  -> Fix: Configuration state is corrupted. Run './rotkeeper.sh init' to heal." >&2
                      exit 1
                  fi

                  local canon_val
                  canon_val=$(realpath -m "$p_val" 2>/dev/null || readlink -m "$p_val" 2>/dev/null || echo "$p_val")
                  local canon_root
                  canon_root=$(realpath -m "$root_fallback" 2>/dev/null || readlink -m "$root_fallback" 2>/dev/null || echo "$root_fallback")

                  # Boundary check using strict path suffix to prevent "repo-malicious" substring matching "repo"
                  if [[ -n "$canon_val" && "$canon_val" != "$canon_root" && "$canon_val" != "$canon_root/"* ]]; then
                      echo "[ERROR] Structural coherence violation." >&2
                      echo "  -> $p_name ($canon_val) escapes Root Dir ($canon_root)." >&2
                      echo "  -> Fix: Ensure paths remain inside the repository boundary." >&2
                      exit 1
                  fi
              done
          fi
      fi
  fi

  # Fallback BHO baseline checks if paths aren't explicitly serialized
  if [[ "$config_source" == "layout default" ]]; then
      case "${style,,}" in
        "busy")
          expected_bones="$root_fallback/bones"
          expected_content="$root_fallback/home/content"
          expected_output="$root_fallback/output"
          expected_templates="$root_fallback/templates"
          expected_assets="$root_fallback/assets"
          expected_docs="$expected_content/docs"
          expected_meta="$expected_bones/meta"
          ;;
        "sterile")
          expected_bones="$root_fallback/bones"
          expected_content="$root_fallback/src/content"
          expected_output="$root_fallback/dist"
          expected_templates="$root_fallback/config/templates"
          expected_assets="$root_fallback/src/assets"
          expected_docs="$expected_content/docs"
          expected_meta="$expected_bones/meta"
          ;;
        "crypt"|*)
          expected_bones="$root_fallback/bones"
          expected_content="$root_fallback/home/content"
          expected_output="$root_fallback/output"
          expected_templates="$expected_bones/templates"
          expected_assets="$root_fallback/home/assets"
          expected_docs="$expected_content/docs"
          expected_meta="$expected_bones/meta"
          ;;
      esac
  fi

  # Validate runtime BHO values against expectations
  if [[ "$mode" != "bootstrap" ]]; then
      for p_name in CONTENT_DIR OUTPUT_DIR BONES_DIR TEMPLATE_DIR ASSETS_DIR DOCS_DIR META_DIR; do
          local runtime_val="${!p_name:-}"
          local expected_val=""
          if [[ "$p_name" == "CONTENT_DIR" ]]; then expected_val="$expected_content"; fi
          if [[ "$p_name" == "OUTPUT_DIR" ]]; then expected_val="$expected_output"; fi
          if [[ "$p_name" == "BONES_DIR" ]]; then expected_val="$expected_bones"; fi
          if [[ "$p_name" == "TEMPLATE_DIR" ]]; then expected_val="$expected_templates"; fi
          if [[ "$p_name" == "ASSETS_DIR" ]]; then expected_val="$expected_assets"; fi
          if [[ "$p_name" == "DOCS_DIR" ]]; then expected_val="$expected_docs"; fi
          if [[ "$p_name" == "META_DIR" ]]; then expected_val="$expected_meta"; fi

          # Use canonical paths for validation to avoid symlink/relative path false mismatches
          local c_runtime c_expected
          c_runtime=$(realpath -m "$runtime_val" 2>/dev/null || readlink -m "$runtime_val" 2>/dev/null || echo "$runtime_val")
          c_expected=$(realpath -m "$expected_val" 2>/dev/null || readlink -m "$expected_val" 2>/dev/null || echo "$expected_val")

          if [[ -n "$c_runtime" && -n "${c_expected:-}" && "$c_runtime" != "$c_expected" ]]; then
              echo "[ERROR] Environment layout mismatch detected for $p_name." >&2
              echo "  -> Expected (from $config_source) : $c_expected" >&2
              echo "  -> Actual (runtime)       : $c_runtime" >&2
              echo "  -> Fix: Configuration state is corrupted. Run './rotkeeper.sh init' to heal." >&2
              exit 1
          fi
      done

      # Strict Mid-flight layout change check (when paths exist but layout differs)
      if [[ "$config_source" == "config paths" ]]; then
          local layout_expected_content layout_expected_output layout_expected_templates layout_expected_assets layout_expected_docs layout_expected_meta layout_expected_bones
          case "${style,,}" in
            "busy")
              layout_expected_content="$root_fallback/home/content"
              layout_expected_output="$root_fallback/output"
              layout_expected_templates="$root_fallback/templates"
              layout_expected_assets="$root_fallback/assets"
              layout_expected_docs="$layout_expected_content/docs"
              layout_expected_bones="$root_fallback/bones"
              layout_expected_meta="$layout_expected_bones/meta"
              ;;
            "sterile")
              layout_expected_content="$root_fallback/src/content"
              layout_expected_output="$root_fallback/dist"
              layout_expected_templates="$root_fallback/config/templates"
              layout_expected_assets="$root_fallback/src/assets"
              layout_expected_docs="$layout_expected_content/docs"
              layout_expected_bones="$root_fallback/bones"
              layout_expected_meta="$layout_expected_bones/meta"
              ;;
            "crypt"|*)
              layout_expected_content="$root_fallback/home/content"
              layout_expected_output="$root_fallback/output"
              layout_expected_templates="$root_fallback/bones/templates"
              layout_expected_assets="$root_fallback/home/assets"
              layout_expected_docs="$layout_expected_content/docs"
              layout_expected_bones="$root_fallback/bones"
              layout_expected_meta="$layout_expected_bones/meta"
              ;;
          esac

          local layout_mismatch=false
          local changed_prop=""
          local c_cached c_layout

          for chk in "CONTENT_DIR:$layout_expected_content:$expected_content" "OUTPUT_DIR:$layout_expected_output:$expected_output" "TEMPLATE_DIR:$layout_expected_templates:$expected_templates" "ASSETS_DIR:$layout_expected_assets:$expected_assets" "DOCS_DIR:$layout_expected_docs:$expected_docs" "META_DIR:$layout_expected_meta:$expected_meta"; do
              local p_name="${chk%%:*}"
              local rest="${chk#*:}"
              local l_exp="${rest%%:*}"
              local c_exp="${rest#*:}"

              c_layout=$(realpath -m "$l_exp" 2>/dev/null || echo "$l_exp")
              c_cached=$(realpath -m "$c_exp" 2>/dev/null || echo "$c_exp")

              if [[ "$c_layout" != "$c_cached" ]]; then
                  layout_mismatch=true
                  changed_prop="$p_name"
                  break
              fi
          done

          if [[ "$layout_mismatch" == "true" ]]; then
              echo "[ERROR] Mid-flight layout change detected." >&2
              echo "  -> Layout Style   : $style" >&2
              echo "  -> Conflict found in $changed_prop" >&2
              echo "  -> Cached : $c_cached" >&2
              echo "  -> Layout : $c_layout" >&2
              echo "  -> Fix: Reinitialize environment using './rotkeeper.sh init' to rebuild paths." >&2
              exit 1
          fi
      fi
  fi

  if [[ "$mode" == "strict" ]]; then
      # don't strictly require outputs/archives before we run, only core things if they exist
      for p_name in CONTENT_DIR BONES_DIR TEMPLATE_DIR ASSETS_DIR; do
          local p_val="${!p_name:-}"
          if [[ -n "$p_val" && ! -d "$p_val" ]]; then
              # Allow first-run to succeed by skipping strict directory checks if we're clearly not initialized at all yet.
              if [[ ! -d "${BONES_DIR:-}" || ! -d "${CONFIG_DIR:-}" ]]; then
                  continue
              fi
              echo "[ERROR] Runtime readiness failure: Directory for $p_name not found." >&2
              echo "  -> Missing: $p_val" >&2
              echo "  -> Fix: Initialize directories using './rotkeeper.sh init'." >&2
              exit 1
          fi
      done
  fi
}




# Error trap: report error line and exit
trap_err() {
  local status=$?
  local line=${BASH_LINENO[0]:-${1:-unknown}}
  local file=${BASH_SOURCE[1]:-${BASH_SOURCE[0]:-unknown}}
  local func=${FUNCNAME[1]:-${FUNCNAME[0]:-MAIN}}
  local cmd=${BASH_COMMAND:-unknown}
  log "ERROR" "Command '$cmd' failed with status $status in function '$func' at $file:$line"
  exit "$status"
}

# Cleanup hook: override in scripts to perform teardown
cleanup_ran=false
cleanup() {
  if [[ "${cleanup_ran:-false}" == true ]]; then return 0; fi
  cleanup_ran=true
  :
}

# ---
# set_traps: Binds the err and exit hooks to ensure graceful demise upon failure
# ---
# Binds the err and exit hooks to ensure graceful demise upon failure
set_traps() {
  trap 'trap_err $LINENO' ERR
  trap 'cleanup' EXIT
}

# Load rc-env.sh from script root


# Initialize log file with script name
init_log() {
  local name="${1:-$(basename "$0" .sh)}"
  LOG_FILE="$LOG_DIR/${name}-$(date +%Y-%m-%d_%H%M).log"
  mkdir -p "$(dirname "$LOG_FILE")"
}

# Canonical version source: one plain semver line in bones/config/version.
# ROTKEEPER_VERSION overrides it. Every dispatcher script reads the version
# through this loader, so version stamps are never duplicated across the
# codebase, release names, or tests.
rk_load_version() {
  if [[ -n "${ROTKEEPER_VERSION:-}" ]]; then
    VERSION="$ROTKEEPER_VERSION"
    return 0
  fi
  local version_file="${VERSION_FILE:-$(dirname "${BASH_SOURCE[0]:-$0}")/../config/version}"
  VERSION="unknown"
  if [[ -f "$version_file" ]]; then
    VERSION="$(tr -d '[:space:]' < "$version_file")"
    VERSION="${VERSION#v}"
    [[ -n "$VERSION" ]] || VERSION="unknown"
  fi
}

VERSION=""
rk_load_version

# Standardize script initialization: sets name, logs, traps, and parses common flags

rk_init_script() {
  SCRIPTNAME="${1:-$(basename "$0" .sh)}"
  shift

  : "${DRY_RUN:=${RK_DRY:-false}}"
  : "${VERBOSE:=${RK_VERBOSE:-false}}"
  : "${QUIET:=${RK_QUIET:-true}}"
  : "${DEBUG:=${RK_DEBUG:-false}}"
  : "${HELP:=false}"

  parse_flags "$@"
  if [[ "$DRY_RUN" == true ]]; then
    QUIET=false
  fi
  if [[ "$HELP" == true ]]; then
    show_help
    exit 0
  fi

  set_traps

  # Ensure the environment is canonically loaded before continuing so logs can write to LOG_DIR
  if [[ "${ROT_SKIP_ENV:-false}" != true ]]; then
    rk_load_env strict
  fi

  init_log "$SCRIPTNAME"

  # Save original stdout to fd 3 for MARKER bypass
  exec 3>&1

  # Redirect output to log file as well
  if [[ "$QUIET" == true ]]; then
    exec > "$LOG_FILE" 2>&1
  else
    # Keep stdout attached to the caller. Process-substitution tees are not
    # portable across restricted macOS/BSD shells and can fail before a ritual
    # starts; log() still records structured messages to LOG_FILE.
    exec >> "$LOG_FILE" 2>&1
  fi

  # If debug is enabled, dump env and turn on tracing
  if [[ "$DEBUG" == true ]]; then
    env
    set -x
  fi
}

get_base_no_ext() {
    local file="$1"
    local dir_part="."
    if [[ "$file" == */* ]]; then
        dir_part="${file%/*}"
    fi
    local file_part="${file##*/}"
    local base_name
    if [[ "$file_part" =~ ^\.[^.]+\. ]]; then
        base_name="${file_part%.*}"
    elif [[ "$file_part" =~ ^\.[^.]+$ ]]; then
        base_name="$file_part"
    else
        base_name="${file_part%.*}"
    fi
    if [ "$dir_part" = "." ]; then
        echo "$base_name"
    else
        echo "${dir_part}/${base_name}"
    fi
}

# Canonicalize a path even when its leaf or intermediate directories do not
# exist yet. This keeps safety checks portable on macOS, where realpath -m and
# readlink -m are not consistently available.
rk_canonical_path() {
    local path="$1"
    local current suffix name current_abs
    current="$path"
    suffix=""

    while [[ ! -d "$current" ]]; do
        name=$(basename -- "$current")
        suffix="/$name$suffix"
        current=$(dirname -- "$current")
        [[ "$current" == "/" || "$current" == "." ]] && return 1
    done

    current_abs=$(cd "$current" 2>/dev/null && pwd -P) || return 1
    printf '%s%s\n' "$current_abs" "$suffix"
}

get_sidecar_path() {
    local target="$1"
    local base_no_ext
    base_no_ext=$(get_base_no_ext "$target")

    local derived_path
    if [[ -d "$ROOT_DIR/$target" ]]; then
        derived_path="${META_DIR}/${target}.soul.md"
    else
        derived_path="${META_DIR}/${base_no_ext}.soul.md"
    fi

    # Flatten out-of-bounds traversal mappings cleanly
    local canonical_soul
    canonical_soul=$(rk_canonical_path "$derived_path" 2>/dev/null || true)

    if [[ -z "$canonical_soul" || ( "$canonical_soul" != "$META_DIR" && "$canonical_soul" != "$META_DIR/"* ) ]]; then
        log "ERROR" "Path traversal attempted via sidecar metadata mapping: $target"
        echo "${META_DIR}/null.soul.md"
    else
        echo "$canonical_soul"
    fi
}

read_meta_sidecar_body() {
    local target_file="$1"
    local sidecar
    sidecar=$(get_sidecar_path "$target_file")
    if [[ -f "$sidecar" ]]; then
        sed "1{/^---$/!q;}; 1,/^---$/d" "$sidecar"
    fi
}

# Return script directory
resolve_script_dir() {
  cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

# Check if file has YAML frontmatter
has_frontmatter() {
  local file="$1"
  grep -q '^---' "$file"
}

# Extract value from YAML frontmatter key (primitive)
get_yaml_key() {
  local key="$1"
  local file="$2"
  awk -v k="$key" '$0 ~ "^"k":" {print $2; exit}' "$file"
}

# List markdown files in a directory
list_md_files() {
  find "$1" -type f -name '*.md'
}

# Require env vars to be set
require_env_vars() {
  for var in "$@"; do
    if [[ -z "${!var:-}" ]]; then
      log "ERROR" "Required env var not set: $var"
      exit 1
    fi
  done
}


# Run main only if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main() {
        # placeholder main logic for rc-utils.sh
        :
    }
    main "$@"
fi
