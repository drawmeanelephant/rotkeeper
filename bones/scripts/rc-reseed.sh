#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-reseed.sh
# Purpose: Reverse ritual — unbind aggregated markdown back into original files
# Version: 0.2.6-dev
# Updated: 2025-06-05
# -----------------------------------------

set -euo pipefail
IFS=$'\n\t'

# Use current directory as root — assume script and inputs live together
ROOT_DIR="$(pwd)"

INPUT=""
DRY_RUN=false

show_help() {
  cat <<EOF
rc-reseed.sh — Reverse ritual for scriptbook/docbook/webbook unbinding

Usage: rc-reseed.sh [--input FILE] [--dry-run] [--all]

Options:
  --input FILE       Path to input file (default: ./rotkeeper-scriptbook-full.md)
  --dry-run          Preview actions without writing files
  --all              Reseed from all known books (scriptbook-full, docbook, configbook)
  --help, -h         Display this message
EOF
  exit 0
}
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
    --input) INPUT="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --all) INPUT="__ALL__"; shift ;;
    --help|-h) show_help ;;
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

  # State
  outfile=""
  in_block=false
  skip_next=0

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^\<\!\-\-\ START:\ ([^[:space:]]+)\ \-\-\>$ ]]; then
      relpath="road-to-bones/${BASH_REMATCH[1]}"
      outfile="$ROOT_DIR/$relpath"
      mkdir -p "$(dirname "$outfile")"
      $DRY_RUN || > "$outfile"
      echo "📁 Resurrecting → $relpath"
      in_block=true
      skip_next=2
      continue
    fi

    if (( skip_next > 0 )); then
      ((skip_next--))
      continue
    fi

    if [[ "$line" == '```' ]]; then
      in_block=false
      continue
    fi

    if [[ "$in_block" == true ]]; then
      [[ "$DRY_RUN" == false ]] && echo "$line" >> "$outfile"
    fi
  done < "$INPUT"
done

echo "✅ Reseed complete."

exit 0