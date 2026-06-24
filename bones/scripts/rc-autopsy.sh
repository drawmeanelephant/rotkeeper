#!/usr/bin/env bash
# ============================================================
#  ██████╗  ██████╗  ██████╗ ██╗  ██╗
#  ██╔══██╗██╔═══██╗██╔═══██╗██║ ██╔╝
#  ██████╔╝██║   ██║██║   ██║█████╔╝
#  ██╔══██╗██║   ██║██║   ██║██╔═██╗
#  ██████╔╝╚██████╔╝╚██████╔╝██║  ██╗
#  ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-autopsy.sh
#  Purpose : Script dissection and output cataloging
#  Version : 0.3.1.4
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; return 1; }
source "$SCRIPT_DIR/rc-env.sh"   || { echo "FATAL: cannot source rc-env.sh" >&2; return 1; }

VERSION="0.3.1.4"

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

rk_init_script rc-autopsy "$@"

set -euo pipefail
IFS=$'\n\t'

HELP_REPORT=false
OUTPUT_REPORT=false

parse_args() {
  local has_mode=false
  for arg in "$@"; do
    case "$arg" in
      --help-report) HELP_REPORT=true; has_mode=true ;;
      --output-report) OUTPUT_REPORT=true; has_mode=true ;;
      --all) HELP_REPORT=true; OUTPUT_REPORT=true; has_mode=true ;;
      --help|-h) show_help; return 1 ;;
      --version|-v) echo "rc-autopsy.sh v$VERSION"; return 1 ;;
      --dry-run|--verbose) ;; # Handled by rk_init_script
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

run_help_report() {
  local OUT="$REPORT_DIR/autopsy-help.md"
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "Would generate help report at $OUT"
    return 0
  fi

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

  mapfile -t scripts < <(find "$ROOT_DIR" "$SCRIPT_DIR" -maxdepth 1 -type f \( -name "rc-*.sh" -o -name "rotkeeper.sh" \) | sort | uniq)

  for script in "${scripts[@]}"; do
    name="$(basename "$script")"
    echo "## $name" >> "$OUT"
    echo >> "$OUT"
    echo '```text' >> "$OUT"
    
    local help_output
    if ! help_output=$(bash "$script" --help 2>&1) || echo "$help_output" | grep -qi 'No help available' || [[ -z "$help_output" ]]; then
      help_output=$(grep -E '^# FLAGS' -A 20 "$script" | grep -v '^--' || echo "(No help available and no # FLAGS block found)")
      log "WARN" "Script $name did not respond well to --help. Used fallback."
    fi
    echo "$help_output" >> "$OUT"
    
    echo '```' >> "$OUT"
    echo >> "$OUT"
    log "INFO" "Extracted help: $name"
  done

  log "INFO" "Help report written to $OUT"
}

render_output_report_md() {
  local OUT="$REPORT_DIR/autopsy-outputs.md"
  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN" "Would generate output report at $OUT"
    return 0
  fi

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

  mapfile -t scripts < <(find "$ROOT_DIR" "$SCRIPT_DIR" -maxdepth 1 -type f \( -name "rc-*.sh" -o -name "rotkeeper.sh" \) | sort | uniq)

  for script in "${scripts[@]}"; do
    name="$(basename "$script")"
    
    local matches
    matches=$(grep -nE '(>\s*\$[A-Z_]+|>>\s*\$[A-Z_]+|tee\s+\$[A-Z_]+|mv\s+.*\$[A-Z_]+|cp\s+.*\$[A-Z_]+|tar\s+.*-[cf]f?\s)' "$script" || true)

    if [[ -n "$matches" ]]; then
      echo "## $name" >> "$OUT"
      echo "" >> "$OUT"
      echo "| Line | Operation | Resolved Path |" >> "$OUT"
      echo "|------|-----------|---------------|" >> "$OUT"

      while IFS= read -r line_match; do
        local line_num="${line_match%%:*}"
        local op_content="${line_match#*:}"
        
        op_content=$(echo "$op_content" | sed -E 's/^[[:space:]]+//')
        local original_op="$op_content"

        local resolved_path="$op_content"
        for var_name in "${!ENV_VARS[@]}"; do
          local val="${ENV_VARS[$var_name]}"
          local rel_val="${val#$ROOT_DIR/}"
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

run_output_report() {
  render_output_report_md
}

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
