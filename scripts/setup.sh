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
# Env assumptions: reads `RK_SKIP_APT`, architecture, OS, and `PATH`; requires network access and uses `sudo` for system installs when not running as root. Oliver is pinned by `OLIVER_PIN`; yq is pinned by `YQ_VERSION` on the download route.
# CWD assumptions: none; project script permissions are updated relative to this script location.
# Input/Output contracts: accepts `--no-apt` on Linux; downloads dependencies to temporary directories, installs tools under `/usr/local/bin` or through Homebrew/apt, and marks existing project scripts executable. If a verified Oliver artifact cannot be installed, exits 3 and deliberately preserves/reports its temporary directory with RK_OLIVER_BIN and user-local recovery commands. It has no help or dry-run parser. DIP reads annotations without executing setup.
# ============================================================

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../bones/scripts/rc-utils.sh"

echo "============================================================"
echo " Starting Rotkeeper Setup..."
echo "============================================================"

# Ensure we're running as root or with sudo if apt-get is used.
# Git Bash/MSYS2 has no sudo and a non-root EUID, so require the binary.
if [[ $EUID -ne 0 ]] && command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
else
    SUDO=""
fi

# Detect System Architecture dynamically.
# Git Bash/MSYS2/Cygwin report msys_nt-*/mingw*_nt-*/cygwin_nt-*; normalize to windows.
OS_TYPE=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$OS_TYPE" in
  msys*|mingw*|cygwin*) OS_TYPE="windows" ;;
esac
ARCH_TYPE=$(uname -m)

case "$ARCH_TYPE" in
  x86_64)  ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *)       ARCH="amd64" ;;
esac

YQ_VERSION="v4.40.5"
BINARY="yq_${OS_TYPE}_${ARCH}"
# Upstream publishes yq_windows_amd64.exe; an extensionless install still execs under MSYS.
[[ "$OS_TYPE" == "windows" ]] && BINARY="${BINARY}.exe"

echo "🤖 Provisioning environment for system profile: $BINARY"

if [[ "$OS_TYPE" == "linux" ]]; then
  # --no-apt (or RK_SKIP_APT=1) skips the apt-get route for users who install
  # dependencies themselves. A stalled apt mirror otherwise hangs setup with
  # no feedback, so the apt calls below are also time-bounded when the
  # `timeout` utility is available.
  SKIP_APT="${RK_SKIP_APT:-0}"
  for _rk_arg in "$@"; do
    case "$_rk_arg" in
      --no-apt) SKIP_APT=1 ;;
    esac
  done
  unset _rk_arg
  if [[ "$SKIP_APT" != "1" ]] && command -v apt-get >/dev/null 2>&1; then
    _RK_APT_TIMEOUT=()
    if command -v timeout >/dev/null 2>&1; then
      _RK_APT_TIMEOUT=(timeout 120)
    fi
    if ! "${_RK_APT_TIMEOUT[@]}" $SUDO apt-get update; then
      echo "WARN: 'apt-get update' failed or timed out after 120s; skipping apt dependency install."
      echo "      Install manually: jq rsync zip gawk wget curl git libxml2-utils,"
      echo "      then re-run setup (or pass --no-apt to skip this step entirely)."
    elif ! "${_RK_APT_TIMEOUT[@]}" $SUDO apt-get install -y jq rsync zip gawk wget curl git libxml2-utils; then
      echo "WARN: 'apt-get install' failed; install manually: jq rsync zip gawk wget curl git libxml2-utils."
    fi
    unset _RK_APT_TIMEOUT
  elif [[ "$SKIP_APT" == "1" ]]; then
    echo "Skipping apt dependency install (--no-apt / RK_SKIP_APT=1)."
    echo "Ensure these are present: jq rsync zip gawk wget curl git libxml2-utils."
  fi
  YQ_TMP="$(mktemp /tmp/yq.XXXXXX)"
  wget -q "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${BINARY}" -O "$YQ_TMP"
elif [[ "$OS_TYPE" == "darwin" ]]; then
  # macOS environment compatibility fallback
  if command -v brew >/dev/null 2>&1; then
    brew install jq rsync zip gawk yq
  else
    YQ_TMP="$(mktemp /tmp/yq.XXXXXX)"
    curl -sL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${BINARY}" -o "$YQ_TMP"
  fi
elif [[ "$OS_TYPE" == "windows" ]]; then
  # Git Bash/MSYS2: no apt or brew. Git for Windows ships jq, gawk, curl, git,
  # and tar; rsync and zip must come from MSYS2 packages (pacman -S rsync zip)
  # or an equivalent manual install. Warn rather than attempt provisioning.
  for _rk_tool in rsync zip; do
    if ! command -v "$_rk_tool" >/dev/null 2>&1; then
      echo "WARN: '$_rk_tool' missing — install it via MSYS2 ('pacman -S $_rk_tool') or copy the package binaries into /usr/bin."
    fi
  done
  unset _rk_tool
  YQ_TMP="$(mktemp /tmp/yq.XXXXXX)"
  curl -sL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${BINARY}" -o "$YQ_TMP"
fi

if [ -n "${YQ_TMP:-}" ] && [ -f "$YQ_TMP" ]; then
  mkdir -p /usr/local/bin 2>/dev/null || true
  $SUDO mv "$YQ_TMP" /usr/local/bin/yq
  $SUDO chmod +x /usr/local/bin/yq
fi

echo "2. Installing Oliver renderer..."
# Oliver has no stable release yet, so Rotkeeper pins an exact source commit:
# the binary built from $OLIVER_PIN is the renderer contract for 0.8.x.
# Move the pin deliberately (see oliver-contract.md) — never on a whim.
# 2026-08-21: bumped to 06dd640 — wrap fix #115 via 06dd6403c505b4863a54c548c978e494b55eb759 (PR #116, parseArgs missing wrap)
# 2026-08-27: bumped to 8460f28 — shared template contract v2 (rotkeeper #244):
# oliver wrap interpolates the extended metadata tokens (version, subtitle,
# tags, asset_meta, navigation, warnings) from --meta-json; the adapter feeds
# version from bones/config/version and subtitle/tags/asset_meta from source
# frontmatter via yq. 8460f28 is the merge commit of oliver PR #126 (feature
# commit 6db830e); the builds release embeds the merge SHA. Previous pin
# (2026-08-21, 06dd640) landed wrap fix #115 (PR #116); the 2026-08-21 9ad86a3
# pin landed Phase 6 S1+S2+S3+S4+S5 (oliver meta #107, wrap #108, render links
# #109, plan+manifest #110) via 9ad86a3763b8bd2f227fd5da94be9fc8ea5fa5fc
# 2026-08-15: bumped to 6edb520c — upstream now publishes prebuilt binaries
# via a rolling `builds` release (oliver-<os>-<arch> + sha256sums.txt), so
# the install path is download-first with checksum + `--version` verification,
# falling back to a Zig 0.16.0 source build. The prior pin (2026-08-14,
# c8a8e06) shipped the XHTML output profile (--to html|xhtml, oliver #54,
# docs/XHTML.md), fail-closed on raw HTML under --to xhtml
# (error.RawHtmlNotXmlWellFormed), plus audit fixes #55-#58 (NUL -> U+FFFD
# under the XHTML profile, CLI subcommand grammar with --to render-only);
# the 2026-08-13 pin (e314dbbe) added the Cooklang frontend (CK1) plus CK2-CK5.
# 2026-09-22: bumped to b84f636 — rolling `builds` release now serves oliver
# 1.1.0 (commit b84f6368181079b9df2fc2c28646ffcb29ffd2ff); the previous pin
# no longer matches the downloadable binary, which forced every fresh setup
# onto the Zig source-build fallback. Verified on Linux: render/preflight
# and the full test matrix pass with 1.1.0.
OLIVER_PIN="b84f6368181079b9df2fc2c28646ffcb29ffd2ff"

report_oliver_install_failure() {
  local artifact="$1" tempdir="$2"
  {
    echo "ERROR: Could not install pinned Oliver to /usr/local/bin/oliver (setup exit 3)."
    printf 'Temporary directory deliberately preserved: %s\n' "$tempdir"
    echo "The verified artifact is still usable. To use it now:"
    printf '  export RK_OLIVER_BIN=%q\n' "$artifact"
    echo "  bash rotkeeper.sh preflight"
    echo "For a persistent install without administrative permission:"
    echo "  mkdir -p \"\$HOME/.local/bin\""
    printf "  install -m 0755 %q \"\$HOME/.local/bin/oliver\"\n" "$artifact"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo "  export RK_OLIVER_BIN=\"\$HOME/.local/bin/oliver\""
    echo "  bash rotkeeper.sh preflight"
    echo "After copying and passing preflight, remove the preserved temporary directory when no longer needed."
  } >&2
}

install_oliver_binary() {
  # Prebuilt-binary fast path: upstream publishes a rolling `builds` release.
  # We download the platform binary, verify it against the published
  # sha256sums.txt, and assert `oliver --version` reports exactly the pinned
  # commit before installing. Download/verification failures fall back to
  # source; installation failures preserve the verified artifact and exit 3.
  # The pin is never silently satisfied by a different commit.
  local os_token="" arch_token=""
  case "$OS_TYPE" in
    linux) os_token="linux" ;;
    darwin) os_token="macos" ;;
    windows) os_token="windows" ;;
  esac
  case "$ARCH_TYPE" in
    x86_64) arch_token="x86_64" ;;
    aarch64|arm64) arch_token="aarch64" ;;
  esac
  [[ -n "$os_token" && -n "$arch_token" ]] || return 1

  local asset="oliver-${os_token}-${arch_token}"
  # The Windows artifact carries an .exe suffix upstream.
  [[ "$os_token" == "windows" ]] && asset="${asset}.exe"
  local url="https://github.com/drawmeanelephant/oliver/releases/download/builds/${asset}"
  local tmpdir bin_path reported expected actual
  tmpdir="$(mktemp -d)"
  bin_path="$tmpdir/${asset}"
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
  expected="$(grep -F "${asset}" "$tmpdir/sha256sums.txt" | awk '{print $1}')"
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
  mkdir -p /usr/local/bin 2>/dev/null || true
  if ! $SUDO install -m 0755 "$bin_path" /usr/local/bin/oliver; then
    report_oliver_install_failure "$bin_path" "$tmpdir"
    exit 3
  fi
  echo "Installed oliver from the upstream builds release ($reported)."
  rm -rf "$tmpdir"
}

NEED_OLIVER_INSTALL=true
OLIVER_FOUND="$(command -v oliver 2>/dev/null || true)"
if [[ -n "$OLIVER_FOUND" ]]; then
  OLIVER_REPORTED="$(command "$OLIVER_FOUND" --version 2>/dev/null || true)"
  if [[ "$OLIVER_REPORTED" == *"commit $OLIVER_PIN"* ]]; then
    echo "Oliver already present at $OLIVER_FOUND ($OLIVER_REPORTED), skipping install."
    NEED_OLIVER_INSTALL=false
  else
    echo "WARN: Oliver at $OLIVER_FOUND reports '${OLIVER_REPORTED:-nothing}', expected commit $OLIVER_PIN."
    echo "      Reinstalling the pinned build so the renderer contract holds."
  fi
fi

if [[ "$NEED_OLIVER_INSTALL" == true ]]; then
  if install_oliver_binary; then
    :
  elif command -v zig >/dev/null 2>&1; then
    # Requires Zig 0.16.0 (https://ziglang.org/download/) and git. A full clone
    # is required: a shallow clone lacks the pinned object once upstream advances.
    OLIVER_BUILD_DIR="$(mktemp -d /tmp/oliver-build.XXXXXX)"
    git clone https://github.com/drawmeanelephant/oliver.git "$OLIVER_BUILD_DIR"
    git -C "$OLIVER_BUILD_DIR" checkout --quiet "$OLIVER_PIN"
    if [[ "$(git -C "$OLIVER_BUILD_DIR" rev-parse HEAD)" != "$OLIVER_PIN" ]]; then
      echo "FATAL: could not check out pinned Oliver commit $OLIVER_PIN" >&2
      exit 1
    fi
    echo "Building Oliver from pinned commit $OLIVER_PIN"
    (cd "$OLIVER_BUILD_DIR" && zig build)
    OLIVER_BUILT="$OLIVER_BUILD_DIR/zig-out/bin/oliver"
    # Zig emits oliver.exe on Windows.
    [[ "$OS_TYPE" == "windows" && ! -f "$OLIVER_BUILT" && -f "$OLIVER_BUILT.exe" ]] && OLIVER_BUILT="$OLIVER_BUILT.exe"
    mkdir -p /usr/local/bin 2>/dev/null || true
    if ! $SUDO install -m 0755 "$OLIVER_BUILT" /usr/local/bin/oliver; then
      report_oliver_install_failure "$OLIVER_BUILT" "$OLIVER_BUILD_DIR"
      exit 3
    fi
    rm -rf "$OLIVER_BUILD_DIR"
  else
    echo "WARN: No Oliver reporting commit $OLIVER_PIN could be installed: the builds release was unavailable and Zig 0.16.0 is not installed."
    echo "      Install Zig 0.16.0 (https://ziglang.org/download/), then re-run this script"
    echo "      to build Oliver from https://github.com/drawmeanelephant/oliver."
  fi
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
