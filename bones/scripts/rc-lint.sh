

#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER LINTER █▓▒░
# Purpose: Audit Rotkeeper files for frontmatter, structural, and syntactic sanity.
# Version: 0.1.0
# Updated: 2025-06-02

set -euo pipefail
IFS=$'\n\t'

#── Allowed YAML keys (whitelist)
declare -a ALLOWED_KEYS=(title slug template version updated status description subtitle tags asset_meta author)

error_count=0

#── Check frontmatter keys in Markdown
lint_frontmatter() {
  local file="$1"
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
  # Check for unknown keys
  local keys
  keys=$(yq e 'keys | .[]' "$file" 2>/dev/null || echo "")
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
for md in $(find . -name '*.md'); do
  lint_frontmatter "$md"
  lint_md_links "$md"
done

#── Main loop: scan rc-*.sh scripts at top level of bones/scripts
for sh in $(find . -maxdepth 1 -name 'rc-*.sh'); do
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