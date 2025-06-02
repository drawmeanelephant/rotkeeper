#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-docbook.sh
# Purpose: Bundle all Markdown documentation into a single GPT-readable file
# Version: 0.2.4-dev
# Updated: 2025-05-31
# -----------------------------------------

source "$(dirname "${BASH_SOURCE[0]}")/rc-env.sh"

set -euo pipefail

OUTPUT="$REPORT_DIR/rotkeeper-docbook.md"
DOC_DIRS=("$CONTENT_DIR/docs" "$ROOT_DIR/home/docs" "$BONES_DIR/docs")

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