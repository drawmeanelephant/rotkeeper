#!/usr/bin/env bash
# ============================================================
#  ██████╗  ██████╗ ████████╗██╗  ██╗███████╗███████╗██████╗
#  ██╔══██╗██╔═══██╗╚══██╔══╝██║ ██╔╝██╔════╝██╔════╝██╔══██╗
#  ██████╔╝██║   ██║   ██║   █████╔╝ █████╗  █████╗  ██████╔╝
#  ██╔══██╗██║   ██║   ██║   ██╔═██╗ ██╔══╝  ██╔══╝  ██╔═══╝
#  ██║  ██║╚██████╔╝   ██║   ██║  ██╗███████╗███████╗██║
#  ╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-lint.sh
#  Purpose : Audit Rotkeeper files for frontmatter, structural, and syntactic sanity
#  Version : 0.2.8
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

#── Flag defaults
STRICT=0
INCLUDE_DRAFTS=0
SCAN_DIR="."
SUMMARY_MODE=""
SUMMARY_FILE="bones/reports/lint-report.md"

#── Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict) STRICT=1 ;;
    --include-drafts) INCLUDE_DRAFTS=1 ;;
    --dir) SCAN_DIR="$2"; shift ;;
    --summary)
      SUMMARY_MODE="$2"
      shift
      ;;
    --dry-run) ;;
    --verbose) ;;
    --help)
      echo "Usage: rc-lint.sh [--strict] [--include-drafts] [--dir path] [--summary markdown]"
      echo "  --strict           Treat missing optional keys as errors"
      echo "  --include-drafts   Include files marked with 'status: draft'"
      echo "  --dir              Directory to scan (default: .)"
      echo "  --summary markdown      Output results to bones/reports/lint-report.md"
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

if [[ "$SUMMARY_MODE" == "markdown" ]]; then
  mkdir -p bones/reports/
  : > "$SUMMARY_FILE"
  echo "# 🧪 Rotkeeper Lint Report" >> "$SUMMARY_FILE"
  echo "_Generated: $(date)_" >> "$SUMMARY_FILE"
  echo >> "$SUMMARY_FILE"
fi

#── Check frontmatter keys in Markdown
lint_frontmatter() {
  local file="$1"

  local status
  status=$(yq e '.status // ""' "$file" 2>/dev/null || echo "")
  if [[ "$status" == "draft" && "$INCLUDE_DRAFTS" -ne 1 ]]; then
    echo "⚠️  [$file] Skipping draft file"
    [[ "$SUMMARY_MODE" == "markdown" ]] && echo "- ⚠️  \`$file\`: Skipping draft file" >> "$SUMMARY_FILE"
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
    [[ "$SUMMARY_MODE" == "markdown" ]] && echo "- ❌ \`$file\`: Missing keys → ${missing[*]}" >> "$SUMMARY_FILE"
    ((error_count++))
  fi

  # Strict mode check for all allowed keys
  if [[ "$STRICT" -eq 1 ]]; then
    for key in "${ALLOWED_KEYS[@]}"; do
      local val
      val=$(yq e ".$key // \"\"" "$file" 2>/dev/null || echo "")
      if [[ -z "$val" ]]; then
        echo "❌ [$file] (strict) Missing key: $key"
        [[ "$SUMMARY_MODE" == "markdown" ]] && echo "- ❌ \`$file\`: (strict) Missing key → $key" >> "$SUMMARY_FILE"
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
      [[ "$SUMMARY_MODE" == "markdown" ]] && echo "- ⚠️  \`$file\`: Unknown frontmatter key → $k" >> "$SUMMARY_FILE"
      # Not necessarily fatal
    fi
  done
}

#── Check for set -euo pipefail & trap
lint_shell_prelude() {
  local file="$1"
  if ! grep -q 'set -euo pipefail' "$file"; then
    echo "❌ [$file] Missing 'set -euo pipefail'"
    [[ "$SUMMARY_MODE" == "markdown" ]] && echo "- ❌ \`$file\`: Missing 'set -euo pipefail'" >> "$SUMMARY_FILE"
    ((error_count++))
  fi
  if ! grep -q '^trap .* ERR' "$file"; then
    echo "⚠️  [$file] No 'trap ... ERR' found (recommended)"
    [[ "$SUMMARY_MODE" == "markdown" ]] && echo "- ⚠️  \`$file\`: No 'trap ... ERR' found (recommended)" >> "$SUMMARY_FILE"
  fi
}

#── Check for broken Markdown links (naive implementation)
lint_md_links() {
  local file="$1"
  (grep -Eo '\[[^]]+\]\([^)]*\.md\)' "$file" || true) | while read -r link; do
    local target
    target=$(echo "$link" | sed -E 's/.*\(([^)]*)\).*/\1/')
    if [[ ! -f "$(dirname "$file")/$target" ]]; then
      echo "❌ [$file] Broken Markdown link → $target"
      [[ "$SUMMARY_MODE" == "markdown" ]] && echo "- ❌ \`$file\`: Broken Markdown link → $target" >> "$SUMMARY_FILE"
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
  if [[ "$SUMMARY_MODE" == "markdown" ]]; then
    echo >> "$SUMMARY_FILE"
    echo "**Total errors**: $error_count" >> "$SUMMARY_FILE"
  fi
  exit 1
else
  echo "✅ Linting passed: No missing required frontmatter or shell prelude errors."
  if [[ "$SUMMARY_MODE" == "markdown" ]]; then
    echo >> "$SUMMARY_FILE"
    echo "**Total errors**: $error_count" >> "$SUMMARY_FILE"
  fi
  exit 0
fi

