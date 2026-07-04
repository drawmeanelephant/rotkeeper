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

# Detect System Architecture dynamically
OS_TYPE=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH_TYPE=$(uname -m)

case "$ARCH_TYPE" in
  x86_64)  ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *)       ARCH="amd64" ;;
esac

YQ_VERSION="v4.40.5"
BINARY="yq_${OS_TYPE}_${ARCH}"

echo "🤖 Provisioning environment for system profile: $BINARY"

if [[ "$OS_TYPE" == "linux" ]]; then
  if command -v apt-get >/dev/null 2>&1; then
    $SUDO apt-get update && $SUDO apt-get install -y pandoc jq rsync zip gawk wget curl
  fi
  wget -q "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${BINARY}" -O /tmp/yq
elif [[ "$OS_TYPE" == "darwin" ]]; then
  # macOS environment compatibility fallback
  if command -v brew >/dev/null 2>&1; then
    brew install pandoc jq rsync zip gawk yq
  else
    curl -sL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${BINARY}" -o /tmp/yq
  fi
fi

if [ -f /tmp/yq ]; then
  $SUDO mv /tmp/yq /usr/local/bin/yq
  $SUDO chmod +x /usr/local/bin/yq
fi


echo "3. Blessing scripts..."
# Resolve project root relative to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

chmod +x "$PROJECT_ROOT/rotkeeper.sh"
find "$PROJECT_ROOT/bones/scripts" -type f \( -name "rc-*.sh" -o -name "rc-*.bats" \) -exec chmod +x {} \;

echo "============================================================"
echo " Setup complete! Ready for 'rotkeeper.sh test'."
echo "============================================================"
