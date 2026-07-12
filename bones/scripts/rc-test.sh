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

if [[ "${1:-}" == "--dry-run" ]]; then
echo "======================================================================"
echo "--- Regression tests for legacy rituals (ingest, sync-inbox, cleanup, reseed) ---"

for cmd in ingest sync-inbox cleanup reseed; do
  output=$(./rotkeeper.sh "$cmd" 2>&1 || true)
  if echo "$output" | grep -q "ERROR: The '$cmd' command has been permanently removed"; then
    echo "  🎉 Pass: Command '$cmd' correctly triggered deprecation error."
  else
    echo "❌ Assertion Failed: Command '$cmd' did not trigger the expected deprecation error."
    exit 101
  fi
done

echo "✅ ALL REGRESSION ASSERTIONS COMPLETED SUCCESSFULLY."

exit 0; fi

echo "--- Rotkeeper Single framework Release Assertion Test Matrix ---"

TEST_DIR="/tmp/rotkeeper-test-env"
cleanup() {
  echo "Pruning testing footprints from the physical realm..."
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT INT TERM ERR

rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

LAYOUT_MODES=("crypt" "busy" "sterile")

for mode in "${LAYOUT_MODES[@]}"; do
  pass_dir="$TEST_DIR/$mode"

  # Derive test structure map exactly as the flat path loader handles it
  case "${mode,,}" in
    "busy")
      b_scripts="bones/scripts"
      b_config="bones/config"
      b_templates="templates"
      b_css="assets/css"
      b_content="home/content"
      b_archive="bones/archive"
      ;;
    "sterile")
      b_scripts="bones/scripts"
      b_config="bones/config"
      b_templates="config/templates"
      b_css="src/assets/css"
      b_content="src/content"
      b_archive="bones/archive"
      ;;
    "crypt"|*)
      b_scripts="bones/scripts"
      b_config="bones/config"
      b_templates="bones/templates"
      b_css="home/assets/css"
      b_content="home/content"
      b_archive="bones/archive"
      ;;
  esac

  mkdir -p "$pass_dir/$b_scripts"
  mkdir -p "$pass_dir/$b_config"
  mkdir -p "$pass_dir/$b_templates"

  cp rotkeeper.sh "$pass_dir/"
  cp bones/scripts/rc-*.sh "$pass_dir/$b_scripts/"
  cp bones/scripts/rewrite-links.lua "$pass_dir/$b_scripts/"
  cp bones/templates/*.html "$pass_dir/$b_templates/"

  cat << CONF_EOF > "$pass_dir/$b_config/rotkeeper.yaml"
project: "Test Tomb"
author: "Test Necromancer"
default_template: "theme-light.html"
layout_style: "$mode"
CONF_EOF

  mkdir -p "$pass_dir/$b_css"
  mkdir -p "$pass_dir/$b_content"

  (
    cd "$pass_dir"
    export ROT_SKIP_ENV=false

    echo "  [+] Initializing environment testing pass..."
    ./rotkeeper.sh init --with-sample > /dev/null

    echo "  [+] Executing release packager assertions..."
    ./rotkeeper.sh release "0.4.0.4" > /dev/null

    echo "  [+] Asserting single archive model matching criteria..."
    if [[ ! -f "$b_archive/releases/rotkeeper-0.4.0.4.zip" ]]; then
       echo "❌ Assertion Failed: Canonical distribution package missing or multi-tier leaks found."
       exit 99
    fi

    if [[ -f "$b_archive/releases/rotkeeper-0.4.0.4-lite.zip" || -f "$b_archive/releases/rotkeeper-0.4.0.4-full.zip" ]]; then
       echo "❌ Assertion Failed: Deprecated multi-tier packages still generated."
       exit 100
    fi

    echo "  🎉 Pass [$mode] successful: canonical distribution payload matches criteria."
  )
done

echo "======================================================================"
echo "✅ ALL SINGLE-TIER CANONICAL ARCHIVE VERIFICATIONS COMPLETED SUCCESSFULLY."
echo "======================================================================"

echo "======================================================================"
echo "--- Regression tests for legacy rituals (ingest, sync-inbox, cleanup, reseed) ---"

for cmd in ingest sync-inbox cleanup reseed; do
  output=$(./rotkeeper.sh "$cmd" 2>&1 || true)
  if echo "$output" | grep -q "ERROR: The '$cmd' command has been permanently removed"; then
    echo "  🎉 Pass: Command '$cmd' correctly triggered deprecation error."
  else
    echo "❌ Assertion Failed: Command '$cmd' did not trigger the expected deprecation error."
    exit 101
  fi
done

echo "✅ ALL REGRESSION ASSERTIONS COMPLETED SUCCESSFULLY."

exit 0
