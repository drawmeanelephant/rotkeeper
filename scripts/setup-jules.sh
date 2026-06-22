#!/usr/bin/env bash
# ============================================================
#       ██╗██╗   ██╗██╗     ███████╗███████╗
#       ██║██║   ██║██║     ██╔════╝██╔════╝
#       ██║██║   ██║██║     █████╗  ███████╗
#  ██   ██║██║   ██║██║     ██╔══╝  ╚════██║
#  ╚█████╔╝╚██████╔╝███████╗███████╗███████║
#   ╚════╝  ╚═════╝ ╚══════╝╚══════╝╚══════╝
# ============================================================
#  Project : Rotkeeper
#  Script  : setup-jules.sh
#  Purpose : Deterministic environment prep for Jules (Ubuntu)
# ============================================================

set -euo pipefail

echo "============================================================"
echo " Starting Rotkeeper Setup for Jules..."
echo "============================================================"

# Ensure we're running as root or with sudo if apt-get is used
if [[ $EUID -ne 0 ]]; then
    SUDO="sudo"
else
    SUDO=""
fi

echo "1. Installing APT dependencies..."
$SUDO apt-get update
$SUDO apt-get install -y pandoc jq rsync zip gawk wget curl

echo "2. Installing yq v4 (pinned)..."
YQ_VERSION="v4.40.5"
YQ_BINARY="yq_linux_amd64"
$SUDO wget -q "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY}" -O /usr/local/bin/yq
$SUDO chmod +x /usr/local/bin/yq

echo "3. Blessing scripts..."
# Resolve project root relative to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

chmod +x "$PROJECT_ROOT/rotkeeper.sh"
find "$PROJECT_ROOT/bones/scripts" -type f \( -name "rc-*.sh" -o -name "rc-*.bats" \) -exec chmod +x {} \;

echo "============================================================"
echo " Setup complete! Ready for 'rotkeeper.sh smoke'."
echo "============================================================"
