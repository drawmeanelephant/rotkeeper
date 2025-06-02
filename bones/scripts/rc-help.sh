

#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER HELP AGGREGATOR █▓▒░
# Purpose: Aggregate and display help texts for all rc-*.sh scripts.
# Version: 0.1.0
# Updated: 2025-06-02

set -euo pipefail
IFS=$'\n\t'

show_header() {
  echo
  echo "======================================="
  echo " Rotkeeper: Comprehensive Help Index"
  echo " Version: 0.1.0 (Generated on 2025-06-02)"
  echo "======================================="
  echo
}

show_help() {
  show_header
  for script in "$(dirname "${BASH_SOURCE[0]}")"/rc-*.sh; do
    if [[ -x "$script" ]]; then
      echo "───────────────────────────────────────"
      echo " Help for $(basename "$script")"
      echo "───────────────────────────────────────"
      bash "$script" --help
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