#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-docbook.sh
# Purpose: Bundle all Markdown documentation into a single GPT-readable file
# Version: 0.2.1
# Updated: 2025-05-27
# -----------------------------------------

set -euo pipefail

OUTPUT="bones/reports/rotkeeper-docbook.md"
DOC_DIRS=("home/content/docs" "home/docs" "bones/docs")

mkdir -p "$(dirname "$OUTPUT")"
echo "# 📘 Rotkeeper Documentation Bundle" > "$OUTPUT"
echo "" >> "$OUTPUT"

for dir in "${DOC_DIRS[@]}"; do
  [[ -d "$dir" ]] || continue
  find "$dir" -type f -name "*.md" | while read -r doc; do
    echo "## 📄 ${doc}" >> "$OUTPUT"
    echo '```markdown' >> "$OUTPUT"
    cat "$doc" >> "$OUTPUT"
    echo '```' >> "$OUTPUT"
    echo "" >> "$OUTPUT"
  done
done

echo "✅ Documentation bundled to $OUTPUT"