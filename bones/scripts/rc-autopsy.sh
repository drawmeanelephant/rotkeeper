#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# ============================================================
#  ██████╗  ██████╗  ██████╗ ██╗  ██╗
#  ██╔══██╗██╔═══██╗██╔═══██╗██║ ██╔╝
#  ██████╔╝██║   ██║██║   ██║█████╔╝
#  ██╔══██╗██║   ██║██║   ██║██╔═██╗
#  ██████╔╝╚██████╔╝╚██████╔╝██║  ██╗
#  ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝
# ============================================================
# Env assumptions: reads BONES_DIR, CONFIG_DIR, DRY_RUN, LOG_DIR, REPORT_DIR, ROOT_DIR, SCRIPT_DIR, TMP_DIR, VERSION (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.
# CWD assumptions: No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.
# Input/Output contracts: CLI args and env vars in; files and stdout/stderr out; respects --dry-run (no writes) and --verbose.
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-autopsy.sh
#  Purpose : Script dissection and output cataloging
#  Version : 0.5.1
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================



# ---
# show_help: Print autopsy usage and exit.
# Inputs: none
# Outputs: Prints help to stdout
# Env: Reads BONES_DIR, CONFIG_DIR, DRY_RUN, LOG_DIR, QUIET, REPORT_DIR ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
show_help() { cat <<HELP_EOF
rc-autopsy.sh — Script dissection ritual v$VERSION
Usage: rc-autopsy.sh [mode] [options]

Modes:
  --help-report    Extract --help output from all rc-*.sh into a reference report
  --output-report  Scan scripts for file-write operations and catalog outputs
  --all            Run both reports (default)

Options:
  --dry-run        Preview without writing
  --verbose        Detailed logging
  --help, -h       Show this message
  --version, -v    Show version
HELP_EOF
}


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
rk_init_script rc-autopsy "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR REPORT_DIR

HELP_REPORT=false
OUTPUT_REPORT=false

# ---
# parse_args: Parse autopsy mode flags (--help-report, --output-report, --all).
# Inputs: $@ (args)
# Outputs: Sets HELP_REPORT/OUTPUT_REPORT; exits on --help/--version
# Env: Reads BONES_DIR, DRY_RUN, QUIET, REPORT_DIR, ROOT_DIR, SCRIPT_DIR ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
parse_args() {
  local has_mode=false
  for arg in "$@"; do
    case "$arg" in
      --help-report) HELP_REPORT=true; has_mode=true ;;
      --output-report) OUTPUT_REPORT=true; has_mode=true ;;
      --all) HELP_REPORT=true; OUTPUT_REPORT=true; has_mode=true ;;
      --help|-h) show_help; exit 0 ;;
      --version|-v) echo "rc-autopsy.sh v$VERSION"; exit 0 ;;
      --dry-run|--verbose) ;; # Handled by rc-utils.sh
      -*) ;; # Ignore other flags
      *) ;;
    esac
  done

  if [[ "$has_mode" == false ]]; then
    HELP_REPORT=true
    OUTPUT_REPORT=true
  fi
  return 0
}

# ---
# run_help_report: Extract --help text from allowed scripts into autopsy-help.md.
# Inputs: none (reads SCRIPT_DIR, ROOT_DIR, REPORT_DIR)
# Outputs: Writes REPORT_DIR/autopsy-help.md
# Env: Reads BONES_DIR, DRY_RUN, QUIET, REPORT_DIR, ROOT_DIR, SCRIPT_DIR ... (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
run_help_report() {
  local OUT="$REPORT_DIR/autopsy-help.md"
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "Would generate help report at $OUT"
    return 0
  fi

  # SIDE EFFECT (write): overwrites bones/reports/autopsy-help.md
  mkdir -p "$REPORT_DIR"
  {
    echo "---"
    echo "title: \"Rotkeeper Script Help Reference\""
    echo "generated: \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
    echo "template: \"rotkeeper-doc.html\""
    echo "---"
    echo
    echo "# Script Help Reference"
    echo
  } > "$OUT"

    local search_script_dir="$SCRIPT_DIR"
    local search_root_dir="$ROOT_DIR"

    if [[ ! -d "$search_script_dir" ]]; then
      search_script_dir="./${SCRIPT_DIR#"$ROOT_DIR"/}"
    fi
    if [[ ! -f "$search_root_dir/rotkeeper.sh" ]]; then
      search_root_dir="."
    fi

    mapfile -t scripts < <({ find "$search_script_dir" -maxdepth 1 -type f -name "rc-*.sh"; find "$search_root_dir" -maxdepth 1 -type f -name "rotkeeper.sh"; } | sort | uniq)

  # Static white-list tracking to enforce zero execution drift constraints
  declare -A PERMITTED_RITUALS
  for r in rc-a11y rc-assets rc-autopsy rc-book rc-bump rc-dip rc-env rc-glue rc-init rc-links rc-new rc-oliver-adapter rc-pack rc-preflight rc-release rc-render rc-scan rc-showcase rc-status rc-test rc-utils; do
    PERMITTED_RITUALS["$r.sh"]=1
  done
  PERMITTED_RITUALS["rotkeeper.sh"]=1

  for script in ${scripts[@]+"${scripts[@]}"}; do
    name="$(basename "$script")"

    if [[ -z "${PERMITTED_RITUALS[$name]:-}" ]]; then
      log "WARN" "Untrusted or rogue script trace skipped from execution cycle: $name"
      continue
    fi

    local help_output
    if ! help_output=$(ROT_SKIP_ENV=true bash "$script" --help 2>&1 || true) || [[ -z "$help_output" ]]; then
      help_output=$(grep -oE '\-\-[a-z][a-z-]+' "$script" | sort -u || echo "(No help available and no flags found)")
      log "WARN" "Script $name did not respond well to --help. Used fallback."
    fi
    
    {
      printf '## %s\n\n' "$name"
      printf '%s\n' '```text'
      printf '%s\n' "$help_output"
      printf '%s\n\n' '```'
    } >> "$OUT"
    log "INFO" "Extracted help: $name"
  done

  log "INFO" "Help report written to $OUT"
}

# ---
# render_output_report_md: Catalog file-write ops (>, >>, tee, mv, cp, tar) into autopsy-outputs.md.
# Inputs: none (reads SCRIPT_DIR, ROOT_DIR, REPORT_DIR)
# Outputs: Writes REPORT_DIR/autopsy-outputs.md
# Env: Reads DRY_RUN, REPORT_DIR, ROOT_DIR, SCRIPT_DIR (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
render_output_report_md() {
  local OUT="$REPORT_DIR/autopsy-outputs.md"
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "Would generate output report at $OUT"
    return 0
  fi

  # SIDE EFFECT (write): overwrites bones/reports/autopsy-outputs.md
  mkdir -p "$REPORT_DIR"
  {
    echo "---"
    echo "title: \"Rotkeeper Outputs Reference\""
    echo "generated: \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
    echo "template: \"rotkeeper-doc.html\""
    echo "---"
    echo
    echo "# Script Outputs Reference"
    echo
  } > "$OUT"

  declare -A ENV_VARS
  while IFS='=' read -r key val; do
    if [[ "$key" == *"_DIR" ]]; then
      ENV_VARS["$key"]="$val"
    fi
  done < <(env)

    local search_script_dir="$SCRIPT_DIR"
    local search_root_dir="$ROOT_DIR"

    if [[ ! -d "$search_script_dir" ]]; then
      search_script_dir="./${SCRIPT_DIR#"$ROOT_DIR"/}"
    fi
    if [[ ! -f "$search_root_dir/rotkeeper.sh" ]]; then
      search_root_dir="."
    fi

    mapfile -t scripts < <({ find "$search_script_dir" -maxdepth 1 -type f -name "rc-*.sh"; find "$search_root_dir" -maxdepth 1 -type f -name "rotkeeper.sh"; } | sort | uniq)

  for script in ${scripts[@]+"${scripts[@]}"}; do
    name="$(basename "$script")"
    
    local matches
    matches=$(grep -nE '(>\s*\$[A-Z_]+|>>\s*\$[A-Z_]+|tee\s+\$[A-Z_]+|mv\s+.*\$[A-Z_]+|cp\s+.*\$[A-Z_]+|tar\s+.*-[cf]f?\s)' "$script" || true)

    if [[ -n "$matches" ]]; then
      {
        printf '## %s\n\n' "$name"
        printf '| Line | Operation | Resolved Path |\n'
        printf '|------|-----------|---------------|\n'
      } >> "$OUT"

      while IFS= read -r line_match; do
        local line_num="${line_match%%:*}"
        local op_content="${line_match#*:}"
        
        op_content=$(echo "$op_content" | sed -E 's/^[[:space:]]+//')
        local original_op="$op_content"

        local resolved_path="$op_content"
        for var_name in "${!ENV_VARS[@]}"; do
          local val="${ENV_VARS[$var_name]}"
          local rel_val="${val#"$ROOT_DIR"/}"
          resolved_path=$(echo "$resolved_path" | sed -E "s|\\\$${var_name}|${rel_val}|g; s|\\\$\\{${var_name}\\}|${rel_val}|g")
        done

        resolved_path=$(echo "$resolved_path" | sed -E 's/(\$[A-Za-z_]+|\$\{[A-Za-z_]+\})/(unresolved: \1)/g')

        local simple_op=""
        if [[ "$original_op" =~ (>\s*\$[A-Z_]+) ]]; then simple_op="${BASH_REMATCH[1]}"; fi
        if [[ -z "$simple_op" ]] && [[ "$original_op" =~ (>>\s*\$[A-Z_]+) ]]; then simple_op="${BASH_REMATCH[1]}"; fi
        if [[ -z "$simple_op" ]] && [[ "$original_op" =~ (tee\s+\$[A-Z_]+) ]]; then simple_op="${BASH_REMATCH[1]}"; fi
        if [[ -z "$simple_op" ]] && [[ "$original_op" =~ (mv\s+[^\s]+\s+\$[A-Z_]+) ]]; then simple_op="${BASH_REMATCH[1]}"; fi
        if [[ -z "$simple_op" ]] && [[ "$original_op" =~ (cp\s+[^\s]+\s+\$[A-Z_]+) ]]; then simple_op="${BASH_REMATCH[1]}"; fi
        if [[ -z "$simple_op" ]] && [[ "$original_op" =~ (tar\s+[^\s]+\s+-[cf]f?\s) ]]; then simple_op="${BASH_REMATCH[1]}"; fi
        
        if [[ -z "$simple_op" ]]; then
           simple_op="$(echo "$original_op" | grep -oE '(>|>>|tee|mv|cp|tar)\s+\S+' | head -n1 || echo "$original_op")"
        fi

        local final_path="$resolved_path"
        final_path=$(echo "$final_path" | sed -E 's/.*(>|>>|tee|mv|cp|tar[ a-zA-Z-]*)[[:space:]]+//' | sed 's/"//g')
        
        echo "| $line_num | \`${simple_op}\` | \`${final_path}\` |" >> "$OUT"

      done <<< "$matches"
      echo "" >> "$OUT"
    fi
  done

  log "INFO" "Output report written to $OUT"
}

# ---
# run_output_report: Wrapper that renders the output catalog.
# Inputs: none
# Outputs: Delegates to render_output_report_md
# Env: Reads BONES_DIR, DRY_RUN, QUIET, ROOT_DIR, VERBOSE (via rc-env.sh / rk_init_script); respects DRY_RUN/VERBOSE where applicable
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
run_output_report() {
  render_output_report_md
}

# ---
# main: Dispatch help/output reports based on parsed flags.
# Inputs: $@ (args)
# Outputs: Generates selected reports
# Env: No env vars (pure args/stdin)
# CWD: No assumption — uses root-relative paths via rk_canonical_path helpers
# ---
main() {
  if ! parse_args "$@"; then
    return 0
  fi
  
  if [[ "$HELP_REPORT" == true ]]; then
    run_help_report
  fi

  if [[ "$OUTPUT_REPORT" == true ]]; then
    run_output_report
  fi
}

main "$@"
