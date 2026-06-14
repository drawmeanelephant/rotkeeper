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
#  Script  : rc-reseed.sh
#  Purpose : Reverse ritual — unbind aggregated markdown back into original files
#  Version : 0.3.0.2
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

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

    if [[ "$in_block" == true && "$DRY_RUN" == false ]]; then
      # Skip fence lines
      [[ "$line" == '```' ]] && continue
      # Skip stitching markers <!-- START / END -->
      [[ "$line" =~ ^\<\!\-\- ]] && continue
      # Write only the actual code lines
      echo "$line" >> "$outfile"
    fi

    # After finishing a script file, sanitize line endings and add final newline
    if [[ "$line" =~ ^\<\!\-\-\ END:\ ([^[:space:]]+)\ \-\-\>$ && "$DRY_RUN" == false && "$outfile" == *".sh" ]]; then
      # Convert CRLF → LF
      sed -i '' 's/\r$//' "$outfile" 2>/dev/null || true
      # Ensure trailing newline
      tail -c1 "$outfile" | read -r _ || echo "" >> "$outfile"

      # Auto-close any unclosed 'if' blocks
      open_if=$(grep -c '^[[:space:]]*if ' "$outfile")
      close_fi=$(grep -c '^[[:space:]]*fi' "$outfile")
      while (( open_if > close_fi )); do
          echo "fi" >> "$outfile"
          ((close_fi++))
      done

      # Auto-close any unclosed 'for' or 'while' loops
      open_for=$(grep -c '^[[:space:]]*\(for \|while \)' "$outfile")
      close_done=$(grep -c '^[[:space:]]*done' "$outfile")
      while (( open_for > close_done )); do
          echo "done" >> "$outfile"
          ((close_done++))
      done

      # Auto-close any unclosed functions (count '{' vs '}')
      open_func=$(grep -c '{' "$outfile")
      close_func=$(grep -c '}' "$outfile")
      while (( open_func > close_func )); do
          echo "}" >> "$outfile"
          ((close_func++))
      done

      # Add default main guard if none exists
      if ! grep -q '^@' "$outfile"; then
          cat <<'EOF' >> "$outfile"

# Only run if script executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main() { :; }
    main "$@"
fi

@  # script end marker for reseed
EOF
      fi

      chmod +x "$outfile"
      in_block=false
    fi

    if [[ "$line" == '```' ]]; then
      in_block=false
      continue
    fi

  done < "$INPUT"
done

echo "✅ Reseed complete."

exit 0

