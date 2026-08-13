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
source "$(dirname "${BASH_SOURCE[0]}")/../bones/scripts/rc-utils.sh"

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
    $SUDO apt-get update && $SUDO apt-get install -y jq rsync zip gawk wget curl git
  fi
  wget -q "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${BINARY}" -O /tmp/yq
elif [[ "$OS_TYPE" == "darwin" ]]; then
  # macOS environment compatibility fallback
  if command -v brew >/dev/null 2>&1; then
    brew install jq rsync zip gawk yq
  else
    curl -sL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${BINARY}" -o /tmp/yq
  fi
fi

if [ -f /tmp/yq ]; then
  $SUDO mv /tmp/yq /usr/local/bin/yq
  $SUDO chmod +x /usr/local/bin/yq
fi

echo "2. Installing Oliver renderer..."
# Oliver has no stable release yet, so Rotkeeper pins an exact source commit:
# the binary built from $OLIVER_PIN is the renderer contract for 0.6.x.
# Move the pin deliberately (see oliver-contract.md) — never on a whim.
OLIVER_PIN="22b3c7795adb1caac160b3bc863980d35bbec379"
if command -v oliver >/dev/null 2>&1; then
  echo "Oliver already present at $(command -v oliver), skipping install."
elif command -v zig >/dev/null 2>&1; then
  # Requires Zig 0.16.0 (https://ziglang.org/download/) and git. A full clone
  # is required: a shallow clone lacks the pinned object once upstream advances.
  rm -rf /tmp/oliver-build
  git clone https://github.com/drawmeanelephant/oliver.git /tmp/oliver-build
  git -C /tmp/oliver-build checkout --quiet "$OLIVER_PIN"
  if [[ "$(git -C /tmp/oliver-build rev-parse HEAD)" != "$OLIVER_PIN" ]]; then
    echo "FATAL: could not check out pinned Oliver commit $OLIVER_PIN" >&2
    exit 1
  fi
  echo "Building Oliver from pinned commit $OLIVER_PIN"
  (cd /tmp/oliver-build && zig build)
  $SUDO install -m 0755 "/tmp/oliver-build/zig-out/bin/oliver" /usr/local/bin/oliver
else
  echo "WARN: Oliver not found on PATH and Zig 0.16.0 is not installed."
  echo "      Install Zig 0.16.0 (https://ziglang.org/download/), then re-run this script"
  echo "      to build Oliver from https://github.com/drawmeanelephant/oliver."
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
