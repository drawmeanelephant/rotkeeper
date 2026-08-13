#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }

if [[ "${1:-}" == "--version" || "${1:-}" == "-v" ]]; then
  echo "rc-test.sh v$VERSION"
  exit 0
fi

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'HELP_EOF'
rc-test.sh — Integration test harness matrix

Usage:
  rotkeeper.sh test|smoke [--dry-run]

Options:
  --dry-run      Run only the removed-command regression checks
  --help, -h     Show help
  --version, -v  Show version and quit
HELP_EOF
  exit 0
fi

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
#  Version : 0.5.1
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

require_bins jq

echo "--- Rotkeeper Single framework Release Assertion Test Matrix ---"

TEST_DIR="${ROOT_DIR:-$PWD}/bones/tmp/rotkeeper-test-env"
cleanup_ran=false
TEST_RELEASE_VERSION="${ROTKEEPER_VERSION:-}"
if [[ -z "$TEST_RELEASE_VERSION" && -f "$ROOT_DIR/bones/config/version" ]]; then
  TEST_RELEASE_VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/bones/config/version")"
  TEST_RELEASE_VERSION="${TEST_RELEASE_VERSION#v}"
fi
if [[ -z "$TEST_RELEASE_VERSION" ]]; then
  echo "ERROR: Could not determine release version from bones/config/version" >&2
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
  cp bones/templates/*.html "$pass_dir/$b_templates/"
  cp "$ROOT_DIR/bones/config/version" "$pass_dir/$b_config/version"

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

    # 2. Missing RK_OLIVER_BIN: falls back to PATH discovery; must fail only
    #    when no oliver executable exists on PATH (hermetic environments).
    if command -v oliver >/dev/null 2>&1; then
      if ! RK_OLIVER_BIN="" ./rotkeeper.sh render >/dev/null 2>&1; then
        echo "❌ Assertion Failed: oliver on PATH should render with empty RK_OLIVER_BIN."
        exit 103
      fi
    else
      if RK_OLIVER_BIN="" ./rotkeeper.sh render >/dev/null 2>&1; then
        echo "❌ Assertion Failed: default oliver render without RK_OLIVER_BIN should have failed."
        exit 103
      fi
    fi

    # 3. Non-existent RK_OLIVER_BIN must fail for default oliver renderer
    if RK_OLIVER_BIN="/nonexistent/oliver" ./rotkeeper.sh render >/dev/null 2>&1; then
      echo "❌ Assertion Failed: default oliver render with invalid RK_OLIVER_BIN should have failed."
      exit 104
    fi

    # 4. Removed renderer must be rejected (Pandoc support was removed)
    if RK_RENDERER=pandoc ./rotkeeper.sh render --renderer pandoc >/dev/null 2>&1; then
      echo "❌ Assertion Failed: removed --renderer pandoc should have been rejected."
      exit 133
    fi

    # 5. Pure Bash/GAWK/YQ Oliver adapter contract test (Zero Python)
    echo "  [+] Executing default pure Bash/GAWK/YQ Oliver adapter contract tests..."
    mkdir -p bones/tmp
    fake_bin="$pass_dir/bones/tmp/fake_oliver"
    cat << 'FAKE_EOF' > "$fake_bin"
#!/usr/bin/env bash
set -euo pipefail
# Mimic Oliver's CLI shape: oliver render --from <markdown|textile> < file
if [[ "${1:-}" != "render" || "${2:-}" != "--from" || ( "${3:-}" != "markdown" && "${3:-}" != "textile" ) ]]; then
  exit 1
fi
if [[ "${3:-}" == "textile" ]]; then
  printf '<h1>textile-input-confirmed</h1>\n<a href="sibling.textile">Sibling</a>\n'
  exit 0
fi
awk '/^---$/ { f++; next } f>=2 || f==0 { print }' | \
  sed -E 's/\[([^]]+)\]\(([^)]+)\)/<a href="\2">\1<\/a>/g'
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

    RK_OLIVER_BIN="$fake_bin" ./rotkeeper.sh render > /dev/null

    # Verify link rewriting assertions on generated HTML (using dynamic $OUTPUT_DIR)
    out_dir_rel="output"
    if [[ "$mode" == "sterile" ]]; then
      out_dir_rel="dist"
    fi
    rendered_ugly="$out_dir_rel/ugly-edge-case.html"

    if [[ ! -f "$rendered_ugly" ]]; then
      echo "❌ Assertion Failed: Oliver rendered output missing for ugly-edge-case.html ($rendered_ugly)"
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

    # --- Checked-in hermetic smoke fixture + golden comparison ---
    # The fixture lives at bones/scripts/tests/fixtures/oliver-smoke/ and renders
    # through the same fake binary used above (zero Oliver required). The rendered
    # <body> region is layout-independent (the head's $assets_root$ link differs
    # per layout style), so the golden body is compared verbatim on every mode.
    FIXTURE_SRC="$ROOT_DIR/bones/scripts/tests/fixtures/oliver-smoke/smoke-fixture.md"
    GOLDEN_HTML="$ROOT_DIR/bones/scripts/tests/fixtures/oliver-smoke/smoke-fixture-expected.html"

    if [[ -f "$FIXTURE_SRC" && -f "$GOLDEN_HTML" ]]; then
      cp "$FIXTURE_SRC" "$b_content/smoke-fixture.md"
      RK_OLIVER_BIN="$fake_bin" ./rotkeeper.sh render > /dev/null

      rendered_smoke="$out_dir_rel/smoke-fixture.html"
      if [[ ! -f "$rendered_smoke" ]]; then
        echo "❌ Assertion Failed: smoke fixture did not render: $rendered_smoke"
        exit 113
      fi

      live_body=$(sed -n '/<body class="rk-page">/,/<\/body>/p' "$rendered_smoke")
      golden_body=$(sed -n '/<body class="rk-page">/,/<\/body>/p' "$GOLDEN_HTML")
      if [[ "$live_body" != "$golden_body" ]]; then
        echo "❌ Assertion Failed: smoke fixture body diverges from golden ($mode)."
        echo "  Rendered: $rendered_smoke"
        echo "  Golden:   $GOLDEN_HTML"
        exit 113
      fi
      echo "  [+] Pass: checked-in smoke fixture body matches golden ($mode)."

      # Nested output path: the same fixture under a content subdirectory must
      # render into a mirrored nested output path with an identical body.
      mkdir -p "$b_content/docs"
      cp "$FIXTURE_SRC" "$b_content/docs/smoke-fixture.md"
      RK_OLIVER_BIN="$fake_bin" ./rotkeeper.sh render > /dev/null

      rendered_nested="$out_dir_rel/docs/smoke-fixture.html"
      if [[ ! -f "$rendered_nested" ]]; then
        echo "❌ Assertion Failed: nested smoke fixture did not render: $rendered_nested"
        exit 113
      fi

      nested_body=$(sed -n '/<body class="rk-page">/,/<\/body>/p' "$rendered_nested")
      if [[ "$nested_body" != "$golden_body" ]]; then
        echo "❌ Assertion Failed: nested smoke fixture body diverges from golden ($mode)."
        echo "  Rendered: $rendered_nested"
        exit 113
      fi
      echo "  [+] Pass: nested smoke fixture body matches golden ($mode)."
    else
      echo "⚠️  Skipping checked-in smoke fixture: fixture or golden missing."
    fi

    # --- v0.5.1 Specific Maintenance Contract Assertions ---
    echo "  [+] Executing v0.5.1 literal-safe, HTML-escaping, soul sidecar & Oliver stderr assertions..."
    
    # 1. Oliver stderr separation check with fake binary emitting warnings
    fake_warn_bin="$pass_dir/bones/tmp/fake_oliver_warn"
    cat << 'WARN_BIN_EOF' > "$fake_warn_bin"
#!/usr/bin/env bash
set -euo pipefail
# Mimic Oliver's CLI shape: oliver render --from markdown < file.md
if [[ "${1:-}" != "render" || "${2:-}" != "--from" || "${3:-}" != "markdown" ]]; then
  exit 1
fi
echo "[OLIVER WARN] Sample non-fatal renderer warning" >&2
awk '/^---$/ { f++; next } f>=2 || f==0 { print }'
WARN_BIN_EOF
    chmod +x "$fake_warn_bin"

    # Create test markdown file with ampersands, quotes, angle brackets, and $body$ literal
    cat << 'TEST_V051_EOF' > "$b_content/v051-test.md"
---
title: "Cats & Dogs <v0.5.1>"
description: "R&D & \"Quotes\""
---

Body text containing Ampersand & Bits and literal $body$ text.
TEST_V051_EOF

    # Create soul sidecar with frontmatter block
    mkdir -p "bones/meta"
    cat << 'SOUL_V051_EOF' > "bones/meta/v051-test.soul.md"
---
title: "Overridden Title & <Sidecar>"
---
SOUL_V051_EOF

    RK_OLIVER_BIN="$fake_warn_bin" ./rotkeeper.sh render > /dev/null

    rendered_v051="$out_dir_rel/v051-test.html"
    if [[ ! -f "$rendered_v051" ]]; then
      echo "❌ Assertion Failed: v051-test.html missing after render."
      exit 119
    fi

    # Verify sidecar frontmatter title override + HTML escaping
    if ! grep -q 'Overridden Title &amp; &lt;Sidecar&gt;' "$rendered_v051"; then
      echo "❌ Assertion Failed: .soul.md frontmatter title override or HTML escaping failed."
      exit 120
    fi

    # Verify literal-safe interpolation of & and $body$ (no unsubstituted metadata placeholders left)
    # shellcheck disable=SC2016
    if grep -q '\$title\$' "$rendered_v051" || grep -q '\$description\$' "$rendered_v051"; then
      echo "❌ Assertion Failed: Template interpolation leaked \$title\$ or \$description\$ placeholder."
      exit 121
    fi

    # shellcheck disable=SC2016
    if ! grep -q 'Body text containing Ampersand & Bits and literal \$body\$ text.' "$rendered_v051"; then
      echo "❌ Assertion Failed: Literal body content containing & or \$body\$ was corrupted."
      exit 122
    fi

    # Verify Oliver stderr did not leak into rendered HTML body
    if grep -q 'OLIVER WARN' "$rendered_v051"; then
      echo "❌ Assertion Failed: Oliver stderr leaked into rendered HTML body."
      exit 123
    fi

    # --- Real Oliver renderer smoke pass (runs only when an executable binary
    # is discoverable; hermetic fixture binaries cover the rest) ---
    REAL_OLIVER="${RK_OLIVER_BIN:-}"
    if [[ -z "$REAL_OLIVER" || ! -x "$REAL_OLIVER" ]]; then
      REAL_OLIVER="$(command -v oliver 2>/dev/null || true)"
    fi

    if [[ -n "$REAL_OLIVER" && -x "$REAL_OLIVER" ]]; then
      echo "  [+] Executing real Oliver renderer smoke pass ($REAL_OLIVER)..."
      cat << 'FIXTURE_EOF' > "$b_content/real-oliver-fixture.md"
---
title: "Real Oliver Fixture"
description: "Smoke fixture rendered by the real Oliver binary"
---

# Real Oliver Fixture

[Internal Link](my-first-page.md)

Text with **bold**, `code`, and a [fragment](my-first-page.md#section-1).
FIXTURE_EOF

      if ! RK_OLIVER_BIN="$REAL_OLIVER" ./rotkeeper.sh render >/dev/null 2>&1; then
        echo "❌ Assertion Failed: real Oliver render failed with $REAL_OLIVER."
        exit 129
      fi

      rendered_real="$out_dir_rel/real-oliver-fixture.html"
      if [[ ! -f "$rendered_real" ]]; then
        echo "❌ Assertion Failed: real Oliver rendered output missing for real-oliver-fixture.html"
        exit 130
      fi

      if ! grep -q '<!DOCTYPE' "$rendered_real" && ! grep -q '<html' "$rendered_real"; then
        echo "❌ Assertion Failed: real Oliver output does not look like rendered HTML."
        exit 131
      fi

      if ! grep -q 'Real Oliver Fixture' "$rendered_real"; then
        echo "❌ Assertion Failed: real Oliver fixture title missing from rendered HTML."
        exit 132
      fi

      # --- Real Oliver CommonMark contract corpus ---
      # The hermetic golden above is produced by the fixture (fake) binary and
      # verifies the adapter pipeline: frontmatter stripping, link rewriting,
      # escaping. It is NOT a CommonMark fidelity golden. This pass renders a
      # checked-in edge-case corpus through the REAL binary and asserts
      # Oliver-produced structures, so renderer fidelity is verified whenever
      # a real oliver is present (see bones/scripts/tests/fixtures/oliver-contract/
      # and the "Rendered Markdown surface" section of oliver-contract.md).
      CONTRACT_DIR="$ROOT_DIR/bones/scripts/tests/fixtures/oliver-contract"
      if [[ -d "$CONTRACT_DIR" ]]; then
        echo "  [+] Executing real Oliver CommonMark contract corpus ($mode)..."
        cp "$CONTRACT_DIR"/*.md "$b_content/"
        RK_OLIVER_BIN="$REAL_OLIVER" ./rotkeeper.sh render > /dev/null

        inline="$out_dir_rel/contract-inline.html"
        blocks="$out_dir_rel/contract-blocks.html"
        table="$out_dir_rel/contract-table.html"
        contract_failed=false

        check_contract() {
          local desc="$1" file="$2"; shift 2
          if ! grep -q "$@" "$file"; then
            echo "❌ Assertion Failed: contract corpus missing $desc in $file"
            contract_failed=true
          fi
        }

        check_contract "bold" "$inline" '<strong>bold</strong>'
        check_contract "rewritten internal link" "$inline" 'href="my-first-page.html"'
        check_contract "fragment preserved" "$inline" 'href="my-first-page.html#section-1"'
        check_contract "autolink escaping" "$inline" 'href="https://example.com/x?a=1&amp;b=2"'
        check_contract "mailto autolink" "$inline" 'mailto:necromancer@example.com'
        check_contract "raw inline HTML" "$inline" '<b>inline tag</b>'
        check_contract "numeric entity" "$inline" 'entity &amp; numeric A'
        check_contract "code span escaping" "$inline" 'code &quot;quotes&quot; &amp;'
        if grep -q 'href="my-first-page.md"' "$inline"; then
          echo "❌ Assertion Failed: contract corpus internal .md href not rewritten to .html."
          contract_failed=true
        fi

        check_contract "heading" "$blocks" '<h1>Blocks</h1>'
        check_contract "fenced code info string" "$blocks" '<pre><code class="language-zig">'
        check_contract "nested blockquote" "$blocks" '<blockquote>'
        check_contract "ordered list" "$blocks" '<ol>'
        check_contract "thematic break" "$blocks" '<hr />'
        if [[ "$(grep -c '<blockquote>' "$blocks")" -ne 2 ]]; then
          echo "❌ Assertion Failed: contract corpus expected 2 nested blockquotes in $blocks."
          contract_failed=true
        fi

        # GFM pipe tables ARE rendered by Oliver (header, body, alignment
        # colons, escaped pipes). Task lists and footnotes are NOT part of
        # CommonMark and must stay literal and never crash the pass.
        check_contract "GFM table element" "$table" '<table>'
        check_contract "GFM table header" "$table" '<th>Feature</th>'
        check_contract "GFM table cell" "$table" '<td>GFM table</td>'
        check_contract "GFM table alignment" "$table" 'align="center"'
        check_contract "GFM table escaped pipe" "$table" -F '>a|b<'
        check_contract "literal task list (documented boundary)" "$table" -F -- '- [x] done'
        check_contract "literal footnote ref (documented boundary)" "$table" -F '[^1]'
        check_contract "literal footnote body (documented boundary)" "$table" -F '[^1]: footnote text'

        if [[ "$contract_failed" == true ]]; then
          exit 140
        fi
        echo "  [+] Pass: real Oliver CommonMark contract corpus ($mode)."
      else
        if [[ "${RK_STRICT:-0}" == "1" ]]; then
          echo "❌ Assertion Failed: real Oliver contract corpus skipped ($CONTRACT_DIR missing) but RK_STRICT=1 requires it."
          exit 142
        fi
        echo "  ⚠️  Skipping real Oliver contract corpus: $CONTRACT_DIR missing."
      fi
    else
      if [[ "${RK_STRICT:-0}" == "1" ]]; then
        echo "❌ Assertion Failed: real Oliver renderer smoke pass skipped (no executable oliver binary found) but RK_STRICT=1 requires it."
        exit 141
      fi
      echo "  [+] Skipping real Oliver renderer smoke pass (no executable oliver binary found)."
    fi

    # Verify manifest path consistency across render, pack, and scan
    if [[ ! -f "bones/manifest.txt" ]]; then
      echo "❌ Assertion Failed: bones/manifest.txt missing after render pass."
      exit 124
    fi

    if ! grep -q "$rendered_v051" "bones/manifest.txt"; then
      echo "❌ Assertion Failed: rendered page $rendered_v051 not in bones/manifest.txt."
      exit 125
    fi

    echo "  [+] Executing configurable input format (textile) assertions..."
    yq eval '.input_format = "textile"' -i "$b_config/rotkeeper.yaml"
    cat << 'TEXTILE_EOF' > "$b_content/textile-check.md"
---
title: "Textile Check"
description: "Textile input format verification"
---

h1. Textile headline

"Textile Link":sibling.textile
TEXTILE_EOF

    if ! RK_OLIVER_BIN="$fake_bin" ./rotkeeper.sh render > /dev/null; then
      echo "❌ Assertion Failed: render with input_format=textile failed."
      exit 144
    fi

    rendered_textile="$out_dir_rel/textile-check.html"
    if [[ ! -f "$rendered_textile" ]]; then
      echo "❌ Assertion Failed: textile-format page missing after render: $rendered_textile"
      exit 145
    fi
    if ! grep -q 'textile-input-confirmed' "$rendered_textile"; then
      echo "❌ Assertion Failed: rendered output does not prove --from textile reached the renderer."
      exit 146
    fi
    if ! grep -q 'href="sibling.html"' "$rendered_textile"; then
      echo "❌ Assertion Failed: .textile internal link was not rewritten to .html."
      exit 147
    fi

    yq eval '.input_format = "markdown"' -i "$b_config/rotkeeper.yaml"
    echo "  [+] Pass: input_format=textile propagated to renderer ($mode)."

    echo "  [+] Executing .textile source extension assertions..."
    cat << 'TEXTILE_SRC_EOF' > "$b_content/textile-src.textile"
---
title: "Textile Source"
description: "Textile extension source verification"
---

h1. Textile headline

"Textile Link":sibling.textile
TEXTILE_SRC_EOF

    if ! RK_OLIVER_BIN="$fake_bin" ./rotkeeper.sh render > /dev/null; then
      echo "❌ Assertion Failed: render with a .textile source failed."
      exit 158
    fi

    rendered_textile_src="$out_dir_rel/textile-src.html"
    if [[ ! -f "$rendered_textile_src" ]]; then
      echo "❌ Assertion Failed: .textile source page missing after render: $rendered_textile_src"
      exit 159
    fi
    if ! grep -q 'textile-input-confirmed' "$rendered_textile_src"; then
      echo "❌ Assertion Failed: .textile source did not render with --from textile (extension must override the config default markdown)."
      exit 160
    fi
    if ! grep -q 'href="sibling.html"' "$rendered_textile_src"; then
      echo "❌ Assertion Failed: .textile source internal link was not rewritten to .html."
      exit 161
    fi

    echo "  [+] Executing source basename collision assertions..."
    cat << 'COLLIDE_MD_EOF' > "$b_content/collision.md"
---
title: "Collision Markdown"
---
Collision markdown body.
COLLIDE_MD_EOF
    cat << 'COLLIDE_TX_EOF' > "$b_content/collision.textile"
---
title: "Collision Textile"
---
h1. Collision textile body.
COLLIDE_TX_EOF

    if RK_OLIVER_BIN="$fake_bin" ./rotkeeper.sh render > /dev/null 2>&1; then
      echo "❌ Assertion Failed: render with colliding collision.md + collision.textile sources should have failed."
      exit 162
    fi
    rm -f "$b_content/collision.md" "$b_content/collision.textile"
    echo "  [+] Pass: source basename collision refused ($mode)."

    # Execute pack to generate tomb archives & json export
    ./rotkeeper.sh pack > /dev/null

    # Execute scan to verify manifest vs disk agreement
    if ! ./rotkeeper.sh scan > /dev/null; then
      echo "❌ Assertion Failed: ./rotkeeper.sh scan failed after pack."
      exit 126
    fi

    # Assert zero missing and zero orphan entries in scan report
    scan_json=$(find "bones/reports" -name "scan-report-*.json" 2>/dev/null | tail -n 1)
    if [[ -z "$scan_json" || ! -f "$scan_json" ]]; then
      echo "❌ Assertion Failed: scan JSON report missing."
      exit 127
    fi

    missing_cnt=$(jq '.missing | length' "$scan_json")
    orphan_cnt=$(jq '.orphans | length' "$scan_json")
    if [[ "$missing_cnt" -ne 0 || "$orphan_cnt" -ne 0 ]]; then
      echo "❌ Assertion Failed: scan reported $missing_cnt missing files and $orphan_cnt orphan files."
      echo "--- Scan JSON Report ---"
      cat "$scan_json"
      echo ""
      exit 128
    fi

    echo "  [+] Executing packager JSON export assertions..."
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

    echo "  [+] Executing pack integrity assertions..."
    newest_tomb=$(find "$b_archive" -name 'tomb-*.tar.gz' 2>/dev/null | sort | tail -n 1)
    if [[ -z "$newest_tomb" || ! -f "$newest_tomb" ]]; then
      echo "❌ Assertion Failed: no tomb-*.tar.gz archive found after pack."
      exit 116
    fi
    if ! gzip -t "$newest_tomb" 2>/dev/null; then
      echo "❌ Assertion Failed: tomb archive failed gzip integrity check: $newest_tomb"
      exit 117
    fi
    if ! tar -tzf "$newest_tomb" | grep -q '^metadata.json$'; then
      echo "❌ Assertion Failed: tomb archive missing metadata.json entry: $newest_tomb"
      exit 118
    fi
    if tar -tzf "$newest_tomb" | grep -vEq "^metadata\.json$|^$out_dir_rel/"; then
      echo "❌ Assertion Failed: tomb archive contains entries outside root-relative prefixes (absolute path leak?)."
      echo "--- Tomb entries ---"
      tar -tzf "$newest_tomb" | head -n 5
      exit 139
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

    echo "  [+] Executing release ZIP content assertions..."
    release_zip="$b_archive/releases/rotkeeper-$TEST_RELEASE_VERSION.zip"
    if ! unzip -tq "$release_zip" > /dev/null 2>&1; then
      echo "❌ Assertion Failed: release ZIP failed integrity test."
      exit 148
    fi
    release_entries=$(zipinfo -1 "$release_zip")
    if [[ -z "$release_entries" ]]; then
      echo "❌ Assertion Failed: release ZIP listing is empty."
      exit 148
    fi
    for req_entry in "rotkeeper/rotkeeper.sh" "rotkeeper/bones/config/rotkeeper.yaml" "rotkeeper/bones/config/version" "rotkeeper/bones/config/release-manifest.txt" "rotkeeper/bones/scripts/rc-utils.sh"; do
      if ! grep -Fxq "$req_entry" <<< "$release_entries"; then
        echo "❌ Assertion Failed: framework spine entry missing from release archive: $req_entry"
        exit 149
      fi
    done
    if grep -vq '^rotkeeper/' <<< "$release_entries"; then
      echo "❌ Assertion Failed: release archive contains entries outside the rotkeeper/ framework root."
      exit 150
    fi
    if grep -Eq '^rotkeeper/(output|bones/logs|bones/tmp|bones/archive|bones/reports|bones/book-reports|home/content/messages)/' <<< "$release_entries"; then
      echo "❌ Assertion Failed: forbidden generated/cache tree shipped in release archive."
      exit 151
    fi
    if grep -Eq '(\.pem|\.key|\.p12|\.pyc|\.npmrc|id_rsa|\.DS_Store|_temp\.md)$|(^|/)\.env(\.|$)' <<< "$release_entries"; then
      echo "❌ Assertion Failed: forbidden artifact shipped in release archive."
      exit 151
    fi
    if find "$b_archive/releases" -name 'rotkeeper-*.tar*' 2>/dev/null | grep -q .; then
      echo "❌ Assertion Failed: non-canonical archive leftovers found in release directory."
      exit 152
    fi

    echo "  [+] Executing --dry-run non-mutation assertions..."
    # Payload files only: bones/logs is excluded because routine log files are
    # minute-granular telemetry, not rendered/archived/reported state.
    pre_count=$(find . -path './bones/logs' -prune -o -type f -print | wc -l | tr -d ' ')
    ./rotkeeper.sh render --dry-run > /dev/null
    ./rotkeeper.sh pack --dry-run > /dev/null
    ./rotkeeper.sh scan --dry-run > /dev/null
    ./rotkeeper.sh release "$TEST_RELEASE_VERSION" --dry-run > /dev/null
    post_count=$(find . -path './bones/logs' -prune -o -type f -print | wc -l | tr -d ' ')
    if [[ "$pre_count" != "$post_count" ]]; then
      echo "❌ Assertion Failed: --dry-run mutated the workspace ($pre_count -> $post_count files)."
      exit 153
    fi

    echo "  [+] Executing stale-output pruning assertions..."
    rm -f "$b_content/ugly-edge-case.md"
    if ! RK_OLIVER_BIN="$fake_bin" ./rotkeeper.sh render > /dev/null; then
      echo "❌ Assertion Failed: render after source removal failed."
      exit 154
    fi
    if [[ -f "$out_dir_rel/ugly-edge-case.html" ]]; then
      echo "❌ Assertion Failed: stale rendered page survived after its source was pruned."
      exit 154
    fi
    echo "  [+] Pass: stale rendered output pruned ($mode)."

    echo "  [+] Executing archive naming uniqueness assertions..."
    ./rotkeeper.sh pack > /dev/null
    ./rotkeeper.sh pack > /dev/null
    newest_tomb=$(find "$b_archive" -name 'tomb-*.tar.gz' 2>/dev/null | sort | tail -n 1)
    prev_tomb=$(find "$b_archive" -name 'tomb-*.tar.gz' 2>/dev/null | sort | tail -n 2 | head -n 1)
    if [[ -z "$newest_tomb" || "$newest_tomb" == "$prev_tomb" ]]; then
      echo "❌ Assertion Failed: consecutive pack runs produced colliding archive names."
      exit 155
    fi

    echo "  🎉 Pass [$mode] successful: canonical distribution payload matches criteria."
  )
done

echo "======================================================================"
echo "✅ ALL SINGLE-TIER CANONICAL ARCHIVE VERIFICATIONS COMPLETED SUCCESSFULLY."
echo "======================================================================"

echo "======================================================================"
echo "--- Command contract: --help is non-mutating, --version is consistent ---"

CONTRACT_COMMANDS=(init new render pack preflight release bump test scan assets autopsy glue links showcase dip book status)

tree_snapshot() {
  git status --porcelain 2>/dev/null
  find "$ROOT_DIR/bones/logs" -type f 2>/dev/null | sort
  find "$ROOT_DIR/bones/tmp" -type f 2>/dev/null | sort
}

contract_failed=false
for cmd in ${CONTRACT_COMMANDS[@]+"${CONTRACT_COMMANDS[@]}"}; do
  before_tree="$(tree_snapshot)"

  if ! help_out=$(./rotkeeper.sh "$cmd" --help 2>&1); then
    echo "❌ Assertion Failed: rotkeeper.sh $cmd --help exited non-zero."
    contract_failed=true
  fi
  if [[ -z "$help_out" ]]; then
    echo "❌ Assertion Failed: rotkeeper.sh $cmd --help produced no output."
    contract_failed=true
  fi

  after_tree="$(tree_snapshot)"
  if [[ "$before_tree" != "$after_tree" ]]; then
    echo "❌ Assertion Failed: rotkeeper.sh $cmd --help mutated the workspace (help must be non-mutating and must not start a workflow)."
    contract_failed=true
  fi

  if ! ver_out=$(./rotkeeper.sh "$cmd" --version 2>&1); then
    echo "❌ Assertion Failed: rotkeeper.sh $cmd --version exited non-zero."
    contract_failed=true
  fi
  if [[ ! "$ver_out" =~ v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    echo "❌ Assertion Failed: rotkeeper.sh $cmd --version did not print a semver version: $ver_out"
    contract_failed=true
  fi
done

if [[ "$contract_failed" == true ]]; then
  echo "❌ COMMAND CONTRACT ASSERTIONS FAILED."
  exit 134
fi
echo "✅ ALL COMMAND CONTRACT ASSERTIONS PASSED."

echo "======================================================================"
echo "--- DIP regression: clean dry-run, non-mutating, no absolute paths ---"

# DIP must run from a clean inventory (fsbook generated on demand), the
# dry-run must be non-mutating (matrix unchanged), and the published matrix
# must stay free of host-specific absolute paths.

./rotkeeper.sh book --fsbook > /dev/null

DIP_MATRIX="$ROOT_DIR/home/content/docs/dip-matrix.md"
matrix_before="$(rk_sha256 "$DIP_MATRIX" 2>/dev/null | cut -d' ' -f1 || true)"

if ! dip_out=$(./rotkeeper.sh dip --dry-run 2>&1); then
  echo "❌ Assertion Failed: dip --dry-run exited non-zero."
  exit 135
fi
if ! grep -q 'DIP finished' <<< "$dip_out"; then
  echo "❌ Assertion Failed: dip --dry-run did not finish cleanly."
  exit 136
fi

matrix_after="$(rk_sha256 "$DIP_MATRIX" 2>/dev/null | cut -d' ' -f1 || true)"
if [[ "$matrix_before" != "$matrix_after" ]]; then
  echo "❌ Assertion Failed: dip --dry-run mutated the DIP matrix (dry-run must be non-mutating)."
  exit 137
fi
if grep -q "$ROOT_DIR" "$DIP_MATRIX"; then
  echo "❌ Assertion Failed: DIP matrix contains host-specific absolute paths."
  exit 138
fi
echo "✅ DIP regression passed."

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
