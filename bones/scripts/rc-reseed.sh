#!/usr/bin/env bash
# ============================================================
#  ██████╗ ███████╗███████╗███████╗███████╗██████╗
#  ██╔══██╗██╔════╝██╔════╝██╔════╝██╔════╝██╔══██╗
#  ██████╔╝█████╗  ███████╗█████╗  █████╗  ██║  ██║
#  ██╔══██╗██╔══╝  ╚════██║██╔══╝  ██╔══╝  ██║  ██║
#  ██║  ██║███████╗███████║███████╗███████╗██████╔╝
#  ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚══════╝╚═════╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-reseed.sh
#  Purpose : Reverse ritual — unbind aggregated markdown back into original files
#  Version : 0.4.0.3
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

set -euo pipefail
IFS=$'\n\t'


show_help() {
  cat <<EOF2
rc-reseed.sh — Reverse ritual for scriptbook/docbook/configbook unbinding

Usage: rc-reseed.sh [--input FILE] [--dry-run] [--all]

Options:
  --version, -v    Show script version and quit
  --input FILE       Path to input file (default: ./rotkeeper-scriptbook-full.md)
  --dry-run          Preview actions without writing files
  --all              Reseed from all known books (scriptbook-full, docbook, configbook)
  --help, -h         Display this message
EOF2
  exit 0
}

source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
VERSION="${ROTKEEPER_VERSION:-0.4.0.3}"

rk_init_script "rc-reseed" "$@"
require_env_vars ROOT_DIR BONES_DIR SCRIPT_DIR CONFIG_DIR LOG_DIR TMP_DIR CONTENT_DIR DOCS_DIR

# Use current directory as root — assume script and inputs live together
ROOT_DIR="$(pwd)"

INPUT=""
# =============================================================================
# rc-reseed.sh — Resurrection from Documentation
#
#   If the scripts are gone, and the tombs are quiet,
#   Let the scriptbook speak, and the docbook riot.
#
#   From bones of markdown, traced and torn,
#   We rebuild what once was born.
#   Echoes parsed from fenced-off code,
#   Stitch the fragments back to road.
#
#   Beware, archivist: this rite rewrites.
#   Ghosts return with sharpened bytes.
# =============================================================================
# Arg parsing
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version|-v) echo "$(basename "$0") v${VERSION:-unknown}"; exit 0 ;;
    --input) INPUT="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --verbose) VERBOSE=true; shift ;;
    --all) INPUT="__ALL__"; shift ;;
    --help|-h) show_help ;;
    --force) FORCE=true; shift ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

if [[ -z "$INPUT" ]]; then
  INPUT="$ROOT_DIR/rotkeeper-scriptbook-full.md"
fi

echo "🔁 Running rc-reseed.sh"

if [[ "$INPUT" == "__ALL__" ]]; then
  DEFAULT_BOOKS=("rotkeeper-scriptbook-full.md" "rotkeeper-docbook.md" "rotkeeper-configbook.md")
else
  DEFAULT_BOOKS=("$INPUT")
fi

for INPUT in "${DEFAULT_BOOKS[@]}"; do
  [[ -f "$INPUT" ]] || { echo "⚠️  Skipping missing input: $INPUT"; continue; }
  echo "📖 Reading from: $INPUT"

  # Pre-scan for duplicates
  declare -A file_counts
  declare -A skip_list
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^\<\!\-\-\ START(:)?\ ([^[:space:]:]+)(::[^[:space:]]+)?\ \-\-\>$ ]]; then
      relpath="${BASH_REMATCH[2]}"
      if [[ -z "${file_counts[$relpath]:-}" ]]; then
        file_counts["$relpath"]=1
      else
        ((file_counts["$relpath"]++))
      fi
    fi
  done < "$INPUT"

  for p in "${!file_counts[@]}"; do
    if (( file_counts["$p"] > 1 )); then
      log "WARN" "Skipping duplicate file in binder: $p (found ${file_counts["$p"]} times)"
      skip_list["$p"]=1
    fi
  done

  # State tracking variables
  outfile=""
  active_suffix=""
  in_block=false
  in_code_fence=false
  skip_next=0

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Track whether we are inside an active markdown code block
    if [[ "$line" =~ ^\`\`\` ]]; then
      if [[ "$in_code_fence" == true ]]; then
        in_code_fence=false
      else
        in_code_fence=true
      fi
      # If we're inside a file block, we still write the fence back to the script
      if [[ "$in_block" == true && "$DRY_RUN" == false ]]; then
        echo "$line" >> "$outfile"
      fi
      continue
    fi

    # ONLY catch path markers if they appear OUTSIDE of code fences
    if [[ "$in_block" == false && "$in_code_fence" == false && "$line" =~ ^\<\!\-\-\ START(:)?\ ([^[:space:]:]+)(::[^[:space:]]+)?\ \-\-\>$ ]]; then
      relpath="${BASH_REMATCH[2]}"
      if [[ -n "${skip_list[$relpath]:-}" ]]; then
        continue
      fi
      if [[ -n "${BASH_REMATCH[3]:-}" ]]; then
        active_suffix="${BASH_REMATCH[3]}"
      else
        active_suffix=""
      fi
      relpath="${BASH_REMATCH[2]}"
      outfile="$ROOT_DIR/$relpath"
      mkdir -p "$(dirname "$outfile")"
      if [[ "$DRY_RUN" == false ]]; then
        : > "$outfile"
      fi
      echo "📁 Resurrecting → $relpath"
      in_block=true
      skip_next=0 # Frontmatter processing handled natively now
      continue
    fi

    if [[ "$in_block" == true && "$in_code_fence" == false && "$line" =~ ^\<\!\-\-\ END(:)?\ ([^[:space:]:]+)(::[^[:space:]]+)?\ \-\-\>$ ]]; then
      relpath="${BASH_REMATCH[2]}"
      if [[ "$ROOT_DIR/$relpath" != "$outfile" ]]; then
        continue
      fi
      end_suffix="${BASH_REMATCH[3]:-}"
      if [[ -n "$active_suffix" && "$active_suffix" != "$end_suffix" ]]; then
        log "WARN" "Mismatched END suffix for $relpath. Expected $active_suffix, got $end_suffix. Ignoring."
        continue
      fi
      if [[ "$DRY_RUN" == false && "$outfile" == *".sh" ]]; then
        chmod +x "$outfile" 2>/dev/null || true
      fi
      in_block=false
      continue
    fi

    # Write the earthly code lines back into the resurrected files
    if [[ "$in_block" == true && "$DRY_RUN" == false ]]; then
      echo "$line" >> "$outfile"
    fi
  done < "$INPUT"
done

echo "✅ Reseed complete."

exit 0
