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

echo "2. Installing Apex renderer..."
APEX_VERSION="v1.1.15"
case "$OS_TYPE" in
  linux)
    case "$ARCH" in
      amd64) APEX_ASSET="linux-x86_64" ;;
      arm64) APEX_ASSET="linux-aarch64" ;;
      *)     APEX_ASSET="linux-x86_64" ;;
    esac
    ;;
  darwin)
    APEX_ASSET="macos-universal"
    ;;
esac

if command -v apex >/dev/null 2>&1; then
  echo "Apex already present at $(command -v apex), skipping install."
else
  # The release .sha256 sidecar lists paths relative to its parent
  # (e.g. "release/apex-...tar.gz"), so verify from a dir containing
  # release/ as a subdirectory.
  rm -rf /tmp/apex-verify
  mkdir -p /tmp/apex-verify/release
  APEX_TARBALL="apex-${APEX_VERSION#v}-${APEX_ASSET}.tar.gz"
  wget -q "https://github.com/ApexMarkdown/apex/releases/download/${APEX_VERSION}/${APEX_TARBALL}" -O "/tmp/apex-verify/release/${APEX_TARBALL}"
  wget -q "https://github.com/ApexMarkdown/apex/releases/download/${APEX_VERSION}/${APEX_TARBALL}.sha256" -O "/tmp/apex-verify/release/${APEX_TARBALL}.sha256"
  (cd /tmp/apex-verify && sha256sum -c "release/${APEX_TARBALL}.sha256")
  rm -rf /tmp/apex-install
  mkdir -p /tmp/apex-install
  tar -xzf "/tmp/apex-verify/release/${APEX_TARBALL}" -C /tmp/apex-install
  $SUDO install -m 0755 "/tmp/apex-install/apex-${APEX_VERSION#v}-${APEX_ASSET}/apex" /usr/local/bin/apex
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
