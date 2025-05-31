#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-scriptbook.sh
# Purpose: Consolidate all rc-*.sh scripts into a Markdown ritual manual for GPT ingestion
# Version: 0.2.4-dev
# Updated: 2025-05-31
# -----------------------------------------
# 🔮 rc-scriptbook.sh — Consolidate all rc-*.sh scripts into a Markdown scriptbook
# Outputs to: bones/reports/rotkeeper-manual.md

set -euo pipefail

BOOK_PATH="bones/reports/rotkeeper-manual.md"
SCRIPTS_DIR="bones/scripts"

mkdir -p bones/reports/

# Write frontmatter
cat <<EOF > "$BOOK_PATH"
---
title: Rotkeeper Ritual Manual
version: 0.2.4-dev
tags: [rotkeeper, scripts, bash, cli, archive]
---
<!-- 🧠 This file is for GPT ingestion. It contains all scripts and docs for Rotkeeper. -->
EOF

echo -e "\n# 📚 Rotkeeper: Documentation Compendium\n" >> "$BOOK_PATH"

echo "## 📄 docs/example.md" >> "$BOOK_PATH"
echo >> "$BOOK_PATH"
echo '```markdown' >> "$BOOK_PATH"
echo "---" >> "$BOOK_PATH"
echo "title: Example" >> "$BOOK_PATH"
echo "template: doc" >> "$BOOK_PATH"
echo "version: 0.2.4-dev" >> "$BOOK_PATH"
echo "---" >> "$BOOK_PATH"
echo "This is an example documentation file stub." >> "$BOOK_PATH"
echo '```' >> "$BOOK_PATH"
echo -e "\n---\n" >> "$BOOK_PATH"

# Append each script to the book
for script in "$SCRIPTS_DIR"/rc-*.sh; do
  name=$(basename "$script")
  echo "## 🔧 \`$name\`" >> "$BOOK_PATH"
  echo >> "$BOOK_PATH"
  echo '```bash' >> "$BOOK_PATH"
  cat "$script" >> "$BOOK_PATH"
  echo '```' >> "$BOOK_PATH"
  echo -e "\n---\n" >> "$BOOK_PATH"
done

echo "[✔] Ritual manual written to $BOOK_PATH"
