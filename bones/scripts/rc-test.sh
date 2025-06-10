#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-test.sh
# Purpose: Run dry-run tests on all rc-*.sh scripts and log their results
# Version: 0.2.5
# Updated: 2025-06-03
# -----------------------------------------

# Source shared Rotkeeper helpers
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"

set -euo pipefail
IFS=$'\n\t'

# Parse common flags and handle help
parse_flags "$@"
if [[ "$HELP" == true ]]; then
  show_help
fi

# Directory containing rc-*.sh scripts
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Determine which scripts to test (all by default)
scripts_to_test=("$SCRIPTS_DIR"/rc-*.sh)


pass_count=0
fail_count=0

TIMESTAMP=$(date +"%Y-%m-%d_%H%M")
LOGFILE="$LOG_DIR/rc-test-${TIMESTAMP}.log"

mkdir -p "$LOG_DIR"

echo "🧪 Rotkeeper CLI Test — $TIMESTAMP" | tee "$LOGFILE"
echo "=====================================" | tee -a "$LOGFILE"

for f in "${scripts_to_test[@]}"; do
  script_name=$(basename "$f")

  # Avoid running this script on itself or known stubs
  if [[ "$script_name" == "rc-test.sh" || "$script_name" == "rc-api.sh" ]]; then
    echo "⚠️  Skipping $script_name (known stub/self)" | tee -a "$LOGFILE"
    continue
  fi

  echo "🔧 Testing $script_name..." | tee -a "$LOGFILE"
  if [[ "$script_name" == "rc-docs-fix.sh" ]]; then
    output=$(bash "$f" --pattern "Rotkeeper" --replace "Rotkeeper" --dry-run 2>&1)
  else
    output=$(bash "$f" --dry-run 2>&1)
  fi
  status=$?

  echo "$output" | tee -a "$LOGFILE"

  if [[ $status -eq 0 ]]; then
    echo "✅ PASS: $script_name" | tee -a "$LOGFILE"
    pass_count=$((pass_count + 1))
  else
    echo "❌ FAIL: $script_name" | tee -a "$LOGFILE"
    fail_count=$((fail_count + 1))
  fi

  echo "✔️ Completed $script_name" | tee -a "$LOGFILE"
  echo "" | tee -a "$LOGFILE"
  echo "---" | tee -a "$LOGFILE"
done

echo "⚙️  Running unit tests via Bats..." | tee -a "$LOGFILE"

if command -v bats >/dev/null 2>&1; then
  bats bones/tests/*.bats | tee -a "$LOGFILE"
else
  echo "⚠️  Bats not installed. Skipping unit tests." | tee -a "$LOGFILE"
fi

echo "" | tee -a "$LOGFILE"
echo "---" | tee -a "$LOGFILE"

echo "🧾 Summary: $pass_count PASS, $fail_count FAIL" | tee -a "$LOGFILE"
if [[ $fail_count -gt 0 ]]; then
  exit 1
else
  exit 0
fi