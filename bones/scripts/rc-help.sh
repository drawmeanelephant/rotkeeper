#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER HELP AGGREGATOR █▓▒░
# Purpose: Aggregate and display help texts for all rc-*.sh scripts.
# Version: 0.2.5-pre
# Updated: 2025-06-03

# TODO:
# - Add --verbose to show full internal script paths
# - Add --script [name] to limit to one script
# - Improve formatting for Obsidian export

set -euo pipefail
IFS=$'\n\t'

show_header() {
  echo
  echo "======================================="
  echo " Rotkeeper: Comprehensive Help Index"
  echo " Version: 0.2.5-pre (Generated on 2025-06-03)"
  echo "======================================="
  echo
}

show_help() {
  show_header
  for script in "$(dirname "${BASH_SOURCE[0]:-$0}")"/rc-*.sh; do
    if [[ -x "$script" ]]; then
      echo "───────────────────────────────────────"
      echo " Help for $(basename "$script")"
      echo "───────────────────────────────────────"
      if bash "$script" --help 2>/dev/null; then
        :
      else
        echo "[ERROR] Could not run help for $(basename "$script")"
      fi
      echo
    fi
  done
}

# If no arguments are provided, display aggregated help.
if [[ $# -eq 0 ]]; then
  show_help
  exit 0
fi

# Display usage for rc-help.sh itself.
cat <<EOF
Usage: rc-help.sh [no arguments]

Aggregates and displays help text from all Rotkeeper scripts.
EOF
exit 1