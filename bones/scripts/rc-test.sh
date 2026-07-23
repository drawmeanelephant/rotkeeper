#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
rk_load_env strict

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
#  Version : 0.4.1
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

TEST_DIR="${ROOT_DIR:-$PWD}/bones/tmp/rotkeeper-test-env"
cleanup_ran=false
TEST_RELEASE_VERSION=$(grep -E '^VERSION="' rotkeeper.sh | cut -d'"' -f2)
if [[ -z "$TEST_RELEASE_VERSION" ]]; then
  echo "ERROR: Could not determine test release version from rotkeeper.sh" >&2
  exit 1
fi

canonicalize_test_path() {
  local path="$1"
  local parent
  local base
  local canonical

  if canonical=$(realpath -m "$path" 2>/dev/null); then
    printf '%s\n' "$canonical"
    return 0
  fi

  parent=$(dirname "$path")
  base=$(basename "$path")
  if parent=$(cd "$parent" 2>/dev/null && pwd -P); then
    printf '%s/%s\n' "$parent" "$base"
  else
    printf '%s\n' "$path"
  fi
}

# shellcheck disable=SC2329 # invoked indirectly by the EXIT/INT/TERM traps
cleanup() {
  local status=$?
  if [[ "${cleanup_ran:-false}" == true ]]; then
    return "$status"
  fi
  cleanup_ran=true

  trap - ERR EXIT INT TERM
  set +e

  if [[ -n "${TEST_DIR:-}" && -d "${TEST_DIR}" ]]; then
    CANONICAL_TEST_DIR=$(canonicalize_test_path "$TEST_DIR")
    if [[ "${CANONICAL_TEST_DIR}/" == "${ROOT_DIR}/"* ]]; then
      echo "Pruning testing footprints from the physical realm..."
      rm -rf "$CANONICAL_TEST_DIR" || true
    fi
  fi

  return "$status"
}

# shellcheck disable=SC2329 # invoked indirectly by the ERR trap
on_err() {
  local status=$?
  printf 'ERROR: status=%s file=%s line=%s function=%s command=%q\n' \
    "$status" "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}" \
    "${BASH_LINENO[0]:-$LINENO}" "${FUNCNAME[1]:-MAIN}" \
    "$BASH_COMMAND" >&2
  return "$status"
}

trap 'on_err' ERR
trap 'cleanup' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if [[ -n "${TEST_DIR:-}" ]]; then
    CANONICAL_TEST_DIR=$(canonicalize_test_path "$TEST_DIR")
    if [[ "${CANONICAL_TEST_DIR}/" == "${ROOT_DIR}/"* ]]; then
        rm -rf "$CANONICAL_TEST_DIR" || true
    fi
fi
mkdir -p "$TEST_DIR"

LAYOUT_MODES=("crypt" "busy" "sterile")

for mode in ${LAYOUT_MODES[@]+"${LAYOUT_MODES[@]}"}; do
  pass_dir="$TEST_DIR/$mode"

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

    echo "  [+] Testing renderer selection and validation..."
    # 1. Invalid renderer flag must fail
    if ./rotkeeper.sh render --renderer invalid_choice >/dev/null 2>&1; then
      echo "❌ Assertion Failed: --renderer invalid_choice should have failed."
      exit 102
    fi

    # 2. Missing RK_APEX_BIN must fail for default apex renderer
    if RK_APEX_BIN="" ./rotkeeper.sh render >/dev/null 2>&1; then
      echo "❌ Assertion Failed: default apex render without RK_APEX_BIN should have failed."
      exit 103
    fi

    # 3. Non-existent RK_APEX_BIN must fail for default apex renderer
    if RK_APEX_BIN="/nonexistent/apex" ./rotkeeper.sh render >/dev/null 2>&1; then
      echo "❌ Assertion Failed: default apex render with invalid RK_APEX_BIN should have failed."
      exit 104
    fi

    # 4. Pandoc opt-in render (if pandoc is available)
    if command -v pandoc >/dev/null 2>&1; then
      ./rotkeeper.sh render --renderer pandoc > /dev/null
    fi

    # 5. Pure Bash/GAWK/YQ Apex adapter contract test (Zero Python)
    echo "  [+] Executing default pure Bash/GAWK/YQ Apex adapter contract tests..."
    mkdir -p bones/tmp
    fake_bin="$pass_dir/bones/tmp/fake_apex"
    cat << 'FAKE_EOF' > "$fake_bin"
#!/usr/bin/env bash
set -euo pipefail
file="${1:-}"
if [[ -f "$file" ]]; then
  awk '/^---$/ { f++; next } f>=2 || f==0 { print }' "$file" | \
    sed -E 's/\[([^]]+)\]\(([^)]+)\)/<a href="\2">\1<\/a>/g'
fi
FAKE_EOF
    chmod +x "$fake_bin"

    # Create ugly metadata & edge-case link test file
    cat << 'UGLY_EOF' > "$b_content/ugly-edge-case.md"
---
title: "An \"Ugly\" Quoted Title"
description: |-
  A multiline description
  with quotes "hello" and breaks.
---

[Normal Link](my-first-page.md)
[Fragment Link](my-first-page.md#section-1)
[Query Link](my-first-page.md?v=123#fragment)
[External Link](https://example.com/docs.md)
[Mailto Link](mailto:necromancer@example.com)
[Angle Bracket Link](<my-first-page.md>)
[Angle Bracket External Link](<https://example.com/docs.md>)
[Angle Bracket Fragment Link](<my-first-page.md#section-1>)
<a href="my-first-page.md">Raw HTML Link</a>
UGLY_EOF

    RK_APEX_BIN="$fake_bin" ./rotkeeper.sh render > /dev/null

    # Verify link rewriting assertions on generated HTML (using dynamic $OUTPUT_DIR)
    out_dir_rel="output"
    if [[ "$mode" == "sterile" ]]; then
      out_dir_rel="dist"
    fi
    rendered_ugly="$out_dir_rel/ugly-edge-case.html"

    if [[ ! -f "$rendered_ugly" ]]; then
      echo "❌ Assertion Failed: Apex rendered output missing for ugly-edge-case.html ($rendered_ugly)"
      exit 105
    fi

    if grep -q 'href="my-first-page.md"' "$rendered_ugly"; then
      echo "❌ Assertion Failed: .md link was not rewritten to .html"
      exit 106
    fi

    if ! grep -q 'href="my-first-page.html"' "$rendered_ugly"; then
      echo "❌ Assertion Failed: .md link was not correctly rewritten to .html"
      exit 107
    fi

    if ! grep -q 'href="my-first-page.html#section-1"' "$rendered_ugly"; then
      echo "❌ Assertion Failed: .md#fragment link was not correctly rewritten"
      exit 108
    fi

    if ! grep -q 'href="my-first-page.html?v=123#fragment"' "$rendered_ugly"; then
      echo "❌ Assertion Failed: .md?query#fragment link was not correctly rewritten"
      exit 109
    fi

    if ! grep -q 'href="https://example.com/docs.md"' "$rendered_ugly"; then
      echo "❌ Assertion Failed: External URL was incorrectly modified"
      exit 110
    fi

    if ! grep -q 'href="mailto:necromancer@example.com"' "$rendered_ugly"; then
      echo "❌ Assertion Failed: mailto link was incorrectly modified"
      exit 111
    fi

    if grep -q 'href="%3C' "$rendered_ugly" || grep -q 'href="<' "$rendered_ugly"; then
      echo "❌ Assertion Failed: angle bracket wrapper leaked into rendered href attribute"
      exit 112
    fi

    echo "  [+] Executing packager JSON export assertions..."
    ./rotkeeper.sh pack > /dev/null
    export_json=$(find "$b_archive" -name "tomb-export-*.json" 2>/dev/null | head -n 1)
    if [[ -z "$export_json" || ! -f "$export_json" ]]; then
      echo "❌ Assertion Failed: packager JSON export file tomb-export-*.json missing."
      exit 113
    fi
    if ! jq empty "$export_json" >/dev/null 2>&1; then
      echo "❌ Assertion Failed: packager JSON export is not valid JSON."
      exit 114
    fi
    if ! jq -e '.[0] | has("absolute_path") and has("relative_path") and has("frontmatter") and has("source_markdown")' "$export_json" >/dev/null 2>&1; then
      echo "❌ Assertion Failed: packager JSON export entry is missing required fields (source_markdown)."
      exit 115
    fi

    echo "  [+] Executing Pandoc-free isolation assertions..."
    no_pandoc_bin="$pass_dir/bones/tmp/no_pandoc_bin"
    mkdir -p "$no_pandoc_bin"
    cat << 'PANDOC_STUB' > "$no_pandoc_bin/pandoc"
#!/usr/bin/env bash
echo "ERROR: Simulated Pandoc binary unavailable" >&2
exit 127
PANDOC_STUB
    chmod +x "$no_pandoc_bin/pandoc"

    if ! PATH="$no_pandoc_bin:$PATH" RK_APEX_BIN="$fake_bin" ./rotkeeper.sh render >/dev/null 2>&1; then
      echo "❌ Assertion Failed: default Apex render failed with Pandoc unavailable."
      exit 116
    fi

    if ! PATH="$no_pandoc_bin:$PATH" ./rotkeeper.sh pack --content >/dev/null 2>&1; then
      echo "❌ Assertion Failed: pack --content failed with Pandoc unavailable."
      exit 117
    fi

    if PATH="$no_pandoc_bin:$PATH" RK_RENDERER=pandoc ./rotkeeper.sh render --renderer pandoc >/dev/null 2>&1; then
      echo "❌ Assertion Failed: legacy --renderer pandoc should have failed when Pandoc is unavailable."
      exit 118
    fi

    echo "  [+] Executing release packager assertions..."
    ./rotkeeper.sh release "$TEST_RELEASE_VERSION" > /dev/null

    echo "  [+] Asserting single archive model matching criteria..."
    if [[ ! -f "$b_archive/releases/rotkeeper-$TEST_RELEASE_VERSION.zip" ]]; then
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
