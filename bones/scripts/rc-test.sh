#!/usr/bin/env bash
# ============================================================
#  Project : Rotkeeper
#  Script  : test.sh
#  Purpose : End-to-end integration test harness for Rotkeeper
# ============================================================

VERSION="0.3.1.3"
set -euo pipefail

if [[ "${1:-}" == "--dry-run" ]]; then
  exit 0
fi

# Start in a clean environment
echo "--- Rotkeeper Test Harness ---"

TEST_DIR="/tmp/rotkeeper-test-env"

cleanup() {
  echo "Cleaning up test environment..."
  rm -rf "$TEST_DIR"
}

trap cleanup EXIT INT TERM ERR

echo "1. Creating test workspace..."
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
cp rotkeeper.sh "$TEST_DIR/"
cp -R bones "$TEST_DIR/"
cp -R home "$TEST_DIR/"

cd "$TEST_DIR"

echo "2. Testing 'init'..."
./rotkeeper.sh init --force > /dev/null

echo "3. Testing 'new'..."
./rotkeeper.sh new test-article-unique > /dev/null
if [[ ! -f "home/content/test-article-unique.md" ]]; then
  echo "FAIL: 'new' command did not generate test-article-unique.md"
  exit 1
fi

echo "4. Testing 'render'..."
./rotkeeper.sh render > /dev/null
if [[ ! -f "output/test-article-unique.html" ]]; then
  echo "FAIL: 'render' command did not generate test-article-unique.html"
  exit 1
fi

echo "5. Testing 'assets'..."
./rotkeeper.sh assets > /dev/null
if [[ ! -f "bones/asset-manifest.yaml" ]]; then
  echo "FAIL: 'assets' command did not generate asset-manifest.yaml"
  exit 1
fi

echo "6. Testing 'scan'..."
./rotkeeper.sh scan > /dev/null
SCAN_REPORT=$(ls bones/reports/scan-report-*.json 2>/dev/null | head -n 1)
if [[ -z "$SCAN_REPORT" ]]; then
  echo "FAIL: 'scan' command did not generate a report"
  exit 1
fi

echo "7. Testing 'dry-run' on all scripts..."
for script in bones/scripts/rc-*.sh; do
  case "$(basename "$script")" in
    rc-bump.sh)
      bash "$script" --dry-run -m "test" > /dev/null || { echo "FAIL: $script failed dry-run"; exit 1; }
      ;;
    rc-release.sh)
      bash "$script" "0.0.0" --dry-run > /dev/null || { echo "FAIL: $script failed dry-run"; exit 1; }
      ;;
    rc-new.sh)
      bash "$script" --dry-run test-article-2 > /dev/null || { echo "FAIL: $script failed dry-run"; exit 1; }
      ;;
    rc-reseed.sh)
      bash "$script" --dry-run --all > /dev/null || { echo "FAIL: $script failed dry-run"; exit 1; }
      ;;
    *)
      bash "$script" --dry-run > /dev/null || { echo "FAIL: $script failed dry-run"; exit 1; }
      ;;
  esac
done

echo "✅ All tests passed successfully."
exit 0
