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
#  Script  : rc-help.sh
#  Purpose : Aggregate and display help texts for all rc-*.sh scripts
#  Version : 0.3.0.9
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

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
  echo " Version: 0.3.0 (Generated on 2026-03-23)"
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

# If --dry-run is passed, exit successfully.
for arg in "$@"; do
  if [[ "$arg" == "--dry-run" ]]; then
    exit 0
  fi
done

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

