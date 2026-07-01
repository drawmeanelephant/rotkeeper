#!/usr/bin/env bash
# ============================================================
#  Project : Rotkeeper
#  Script  : rc-test.sh
#  Purpose : Multi-Pass Layout Integration Test Matrix
#  Version : 0.4.0.3
# ============================================================

set -euo pipefail
IFS=$'\n\t'

if [[ "${1:-}" == "--dry-run" ]]; then exit 0; fi

echo "--- Rotkeeper Multi-Pass Layout Matrix Test Suite ---"

TEST_DIR="/tmp/rotkeeper-test-env"
cleanup() {
  echo "Pruning testing footprints from the physical realm..."
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT INT TERM ERR

# Establish sandbox footprint
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

# Matrix Configuration Array
LAYOUT_MODES=("crypt" "busy" "sterile")

for mode in "${LAYOUT_MODES[@]}"; do
  echo "======================================================================"
  echo "🔬 EXECUTING VALIDATION PASS: [Layout Mode: $mode]"
  echo "======================================================================"

  # 1. Provision Fresh Sandbox Layout Architecture
  pass_dir="$TEST_DIR/$mode"
  mkdir -p "$pass_dir/bones/scripts"
  mkdir -p "$pass_dir/bones/config"
  mkdir -p "$pass_dir/bones/templates"

  # Copy foundational codebases
  cp rotkeeper.sh "$pass_dir/"
  cp bones/scripts/rc-*.sh "$pass_dir/bones/scripts/"
  cp bones/scripts/rewrite-links.lua "$pass_dir/bones/scripts/"
  cp bones/templates/*.html "$pass_dir/bones/templates/"

  # Inject target layout setting into our active configuration profile
  cat << CONF_EOF > "$pass_dir/bones/config/rotkeeper.yaml"
project: "Test Tomb"
author: "Test Necromancer"
default_template: "theme-light.html"
layout_style: "$mode"
CONF_EOF

  # Setup targeted sub-directories natively based on active pass context
  case "$mode" in
    "busy")
      mv "$pass_dir/bones/templates" "$pass_dir/templates"
      mkdir -p "$pass_dir/assets/css"
      mkdir -p "$pass_dir/home/content"
      cp home/assets/css/*.css "$pass_dir/assets/css/"
      ;;
    "sterile")
      mkdir -p "$pass_dir/config"
      mv "$pass_dir/bones/templates" "$pass_dir/config/templates"
      mkdir -p "$pass_dir/src/assets/css"
      mkdir -p "$pass_dir/src/content"
      cp home/assets/css/*.css "$pass_dir/src/assets/css/"
      ;;
    "crypt")
      mkdir -p "$pass_dir/home/assets/css"
      mkdir -p "$pass_dir/home/content"
      cp home/assets/css/*.css "$pass_dir/home/assets/css/"
      ;;
  esac

  # 2. Enter target workspace boundary and execute lifecycle loops
  (
    cd "$pass_dir"
    export ROT_SKIP_ENV=false # Enforce fresh boots

    echo "  [+] Initializing environment..."
    ./rotkeeper.sh init --with-sample > /dev/null

    # Assert structural content scaffolding placement matches criteria
    case "$mode" in
      "busy")    [ -f "home/content/test-file.md" ] || exit 40 ;;
      "sterile") [ -f "src/content/test-file.md" ] || exit 41 ;;
      "crypt")   [ -f "home/content/test-file.md" ] || exit 42 ;;
    esac

    echo "  [+] Testing 'new' scaffold ritual..."
    ./rotkeeper.sh new "custom-page" > /dev/null

    echo "  [+] Compiling and running Pandoc Forge passes..."
    ./rotkeeper.sh render > /dev/null

    # Validate output targets match criteria
    case "$mode" in
      "busy")    [ -f "output/custom-page.html" ] || exit 50 ;;
      "sterile") [ -f "dist/custom-page.html" ] || exit 51 ;;
      "crypt")   [ -f "output/custom-page.html" ] || exit 52 ;;
    esac

    echo "  [+] Auditing asset mapping constraints..."
    ./rotkeeper.sh assets > /dev/null
    [ -f "bones/asset-manifest.yaml" ] || exit 53

    echo "  [+] Running validation audit tools..."
    ./rotkeeper.sh book --fsbook > /dev/null
    ./rotkeeper.sh autopsy --all > /dev/null
    ./rotkeeper.sh dip > /dev/null

    echo "  [+] Verifying workspace status summaries..."
    ./rotkeeper.sh status --json > /dev/null

    echo "  🎉 Pass [$mode] successful and structurally coherent."
  )
done

echo "======================================================================"
echo "✅ ALL LAYOUT MATRIX PASSES COMPLETED WITHOUT ENTROPY PROLIFERATION."
echo "======================================================================"
exit 0
