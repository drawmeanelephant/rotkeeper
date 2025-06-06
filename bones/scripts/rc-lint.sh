#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER LINTER █▓▒░
# Purpose: Audit Rotkeeper files for frontmatter, structural, and syntactic sanity.
# Version: 0.1.0
# Updated: 2025-06-02

#── Flag defaults
STRICT=0
INCLUDE_DRAFTS=0
SCAN_DIR="."

#── Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict) STRICT=1 ;;
    --include-drafts) INCLUDE_DRAFTS=1 ;;
    --dir) SCAN_DIR="$2"; shift ;;
    --help)
      echo "Usage: rc-lint.sh [--strict] [--include-drafts] [--dir path]"
      echo "  --strict           Treat missing optional keys as errors"
      echo "  --include-drafts   Include files marked with 'status: draft'"
      echo "  --dir              Directory to scan (default: .)"
      echo "  --help             Show this help message"
      exit 0
      ;;
    *) echo "Unknown flag: $1"; exit 1 ;;
  esac
  shift
done

set -euo pipefail
IFS=$'\n\t'

#── Allowed YAML keys (whitelist)
declare -a ALLOWED_KEYS=(title slug template version updated status description subtitle tags asset_meta author)

error_count=0

#── Check frontmatter keys in Markdown
lint_frontmatter() {
  local file="$1"

  local status
  status=$(yq e '.status // ""' "$file" 2>/dev/null || echo "")
  if [[ "$status" == "draft" && "$INCLUDE_DRAFTS" -ne 1 ]]; then
    echo "⚠️  [$file] Skipping draft file"
    return
  fi

  local missing=()
  for key in title slug template version updated; do
    local val
    val=$(yq e ".$key // \"\"" "$file" 2>/dev/null || echo "")
    if [[ -z "$val" ]]; then
      missing+=("$key")
    fi
  done
  if [[ "${#missing[@]}" -gt 0 ]]; then
    echo "❌ [$file] Missing frontmatter keys: ${missing[*]}"
    ((error_count++))
  fi

  # Strict mode check for all allowed keys
  if [[ "$STRICT" -eq 1 ]]; then
    for key in "${ALLOWED_KEYS[@]}"; do
      local val
      val=$(yq e ".$key // \"\"" "$file" 2>/dev/null || echo "")
      if [[ -z "$val" ]]; then
        echo "❌ [$file] (strict) Missing key: $key"
        ((error_count++))
      fi
    done
  fi

  # Check for unknown keys
  local keys
  keys=$(yq e 'paths | map(.[0]) | unique | .[]' "$file" 2>/dev/null || echo "")
  for k in $keys; do
    if [[ ! " ${ALLOWED_KEYS[*]} " =~ " $k " ]]; then
      echo "⚠️  [$file] Unknown frontmatter key: $k"
      # Not necessarily fatal
    fi
  done
}

#── Check for set -euo pipefail & trap
lint_shell_prelude() {
  local file="$1"
  if ! grep -q 'set -euo pipefail' "$file"; then
    echo "❌ [$file] Missing 'set -euo pipefail'"
    ((error_count++))
  fi
  if ! grep -q '^trap .* ERR' "$file"; then
    echo "⚠️  [$file] No 'trap ... ERR' found (recommended)"
  fi
}

#── Check for broken Markdown links (naive implementation)
lint_md_links() {
  local file="$1"
  grep -Eo '\[[^]]+\]\([^)]*\.md\)' "$file" | while read -r link; do
    local target
    target=$(echo "$link" | sed -E 's/.*\(([^)]*)\).*/\1/')
    if [[ ! -f "$(dirname "$file")/$target" ]]; then
      echo "❌ [$file] Broken Markdown link → $target"
      ((error_count++))
    fi
  done
}

#── Main loop: scan Markdown files
for md in $(find "$SCAN_DIR" -name '*.md'); do
  lint_frontmatter "$md"
  lint_md_links "$md"
done

#── Main loop: scan rc-*.sh scripts at top level of bones/scripts
for sh in $(find "$SCAN_DIR" -maxdepth 1 -name 'rc-*.sh'); do
  lint_shell_prelude "$sh"
done

#── Summary
if [[ "$error_count" -gt 0 ]]; then
  echo "❗ Linting finished: $error_count error(s) found."
  exit 1
else
  echo "✅ Linting passed: No missing required frontmatter or shell prelude errors."
  exit 0
fi