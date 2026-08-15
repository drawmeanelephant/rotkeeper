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
#  Script  : setup.sh
#  Purpose : Deterministic environment prep (Ubuntu/macOS)
# ============================================================

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../bones/scripts/rc-utils.sh"

echo "============================================================"
echo " Starting Rotkeeper Setup..."
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
    $SUDO apt-get update && $SUDO apt-get install -y jq rsync zip gawk wget curl git libxml2-utils
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
# 2026-08-15: bumped to 6edb520c — upstream now publishes prebuilt binaries
# via a rolling `builds` release (oliver-<os>-<arch> + sha256sums.txt), so
# the install path is download-first with checksum + `--version` verification,
# falling back to a Zig 0.16.0 source build. The prior pin (2026-08-14,
# c8a8e06) shipped the XHTML output profile (--to html|xhtml, oliver #54,
# docs/XHTML.md), fail-closed on raw HTML under --to xhtml
# (error.RawHtmlNotXmlWellFormed), plus audit fixes #55-#58 (NUL -> U+FFFD
# under the XHTML profile, CLI subcommand grammar with --to render-only);
# the 2026-08-13 pin (e314dbbe) added the Cooklang frontend (CK1) plus CK2-CK5.
OLIVER_PIN="6edb520cabb31220995e676a95bf59cfb0e1ce4b"

install_oliver_binary() {
  # Prebuilt-binary fast path: upstream publishes a rolling `builds` release.
  # We download the platform binary, verify it against the published
  # sha256sums.txt, and assert `oliver --version` reports exactly the pinned
  # commit before installing. Any failure falls back to the source build
  # below — the pin is never silently satisfied by a different commit.
  local os_token="" arch_token=""
  case "$OS_TYPE" in
    linux) os_token="linux" ;;
    darwin) os_token="macos" ;;
  esac
  case "$ARCH_TYPE" in
    x86_64) arch_token="x86_64" ;;
    aarch64|arm64) arch_token="aarch64" ;;
  esac
  [[ -n "$os_token" && -n "$arch_token" ]] || return 1

  local url="https://github.com/drawmeanelephant/oliver/releases/download/builds/oliver-${os_token}-${arch_token}"
  local tmpdir bin_path reported expected actual
  tmpdir="$(mktemp -d)"
  bin_path="$tmpdir/oliver-${os_token}-${arch_token}"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --max-time 120 "$url" -o "$bin_path" || { rm -rf "$tmpdir"; return 1; }
    curl -fsSL --max-time 60 "${url%/*}/sha256sums.txt" -o "$tmpdir/sha256sums.txt" || { rm -rf "$tmpdir"; return 1; }
  elif command -v wget >/dev/null 2>&1; then
    wget -q -T 120 "$url" -O "$bin_path" || { rm -rf "$tmpdir"; return 1; }
    wget -q -T 60 "${url%/*}/sha256sums.txt" -O "$tmpdir/sha256sums.txt" || { rm -rf "$tmpdir"; return 1; }
  else
    rm -rf "$tmpdir"
    return 1
  fi
  expected="$(grep -F "oliver-${os_token}-${arch_token}" "$tmpdir/sha256sums.txt" | awk '{print $1}')"
  actual="$(rk_sha256 "$bin_path" | awk '{print $1}')"
  if [[ -z "$expected" || "$actual" != "$expected" ]]; then
    echo "WARN: builds checksum mismatch for oliver-${os_token}-${arch_token}; falling back to source build."
    rm -rf "$tmpdir"
    return 1
  fi
  chmod +x "$bin_path"
  reported="$("$bin_path" --version 2>/dev/null)" || { rm -rf "$tmpdir"; return 1; }
  if [[ "$reported" != *"commit $OLIVER_PIN"* ]]; then
    echo "WARN: builds binary reports '$reported', expected commit $OLIVER_PIN; falling back to source build."
    rm -rf "$tmpdir"
    return 1
  fi
  $SUDO install -m 0755 "$bin_path" /usr/local/bin/oliver
  echo "Installed oliver from the upstream builds release ($reported)."
  rm -rf "$tmpdir"
}

if command -v oliver >/dev/null 2>&1; then
  echo "Oliver already present at $(command -v oliver), skipping install."
elif install_oliver_binary; then
  :
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
  echo "WARN: Oliver not found on PATH, the builds release was unavailable, and Zig 0.16.0 is not installed."
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
