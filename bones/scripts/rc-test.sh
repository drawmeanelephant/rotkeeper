#!/usr/bin/env bash
# ============================================================
#  ████████╗███████╗███████╗████████╗
#  ╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝
#     ██║   █████╗  ███████╗   ██║
#     ██║   ██╔══╝  ╚════██║   ██║
#     ██║   ███████╗███████║   ██║
#     ╚═╝   ╚══════╝╚══════╝   ╚═╝
# ============================================================
#  Project : Rotkeeper
#  Script  : rc-test.sh
#  Purpose : Multi-Pass Layout Integration Test Suite aligned for single distribution zip archives
#  Version : 0.4.0.4
# ============================================================

set -euo pipefail
IFS=$'\n\t'

if [[ "${1:-}" == "--dry-run" ]]; then exit 0; fi

echo "--- Rotkeeper Single framework Release Assertion Test Matrix ---"

TEST_DIR="/tmp/rotkeeper-test-env"
cleanup() {
  echo "Pruning testing footprints from the physical realm..."
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT INT TERM ERR

rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

LAYOUT_MODES=("crypt")

for mode in "${LAYOUT_MODES[@]}"; do
  pass_dir="$TEST_DIR/$mode"
  mkdir -p "$pass_dir/bones/scripts"
  mkdir -p "$pass_dir/bones/config"
  mkdir -p "$pass_dir/bones/templates"

  cp rotkeeper.sh "$pass_dir/"
  cp bones/scripts/rc-*.sh "$pass_dir/bones/scripts/"
  cp bones/scripts/rewrite-links.lua "$pass_dir/bones/scripts/"
  cp bones/templates/*.html "$pass_dir/bones/templates/"

  cat << CONF_EOF > "$pass_dir/bones/config/rotkeeper.yaml"
project: "Test Tomb"
author: "Test Necromancer"
default_template: "theme-light.html"
layout_style: "$mode"
CONF_EOF

  mkdir -p "$pass_dir/home/assets/css"
  mkdir -p "$pass_dir/home/content"

  (
    cd "$pass_dir"
    export ROT_SKIP_ENV=false

    echo "  [+] Initializing environment testing pass..."
    ./rotkeeper.sh init --with-sample > /dev/null

    echo "  [+] Executing release packager assertions..."
    ./rotkeeper.sh release "0.4.0.4" > /dev/null

    echo "  [+] Asserting single archive model matching criteria..."
    if [[ ! -f "bones/releases/rotkeeper-0.4.0.4.zip" ]]; then
       echo "❌ Assertion Failed: Canonical distribution package missing or multi-tier leaks found."
       exit 99
    fi

    if [[ -f "bones/releases/rotkeeper-0.4.0.4-lite.zip" || -f "bones/releases/rotkeeper-0.4.0.4-full.zip" ]]; then
       echo "❌ Assertion Failed: Deprecated multi-tier packages still generated."
       exit 100
    fi

    echo "  🎉 Pass [$mode] successful: canonical distribution payload matches criteria."
  )
done

echo "======================================================================"
echo "✅ ALL SINGLE-TIER CANONICAL ARCHIVE VERIFICATIONS COMPLETED SUCCESSFULLY."
echo "======================================================================"
exit 0
