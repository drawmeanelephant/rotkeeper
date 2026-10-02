---
reference_contract: rotkeeper.command-reference.v1
title: rc-a11y.sh
slug: rc-a11y
target_file: bones/scripts/rc-a11y.sh
template: rotkeeper-doc.html
status: active
version: 0.8.1
author: Rotkeeper DIP
project: Rotkeeper
description: |-
  Accessibility audit for theme stylesheets — WCAG contrast
  over palette scopes, focus-state presence, narrow-viewport
  table/code legibility — recorded per theme
---

# rc-a11y.sh

## Overview

Accessibility audit for theme stylesheets — WCAG contrast
over palette scopes, focus-state presence, narrow-viewport
table/code legibility — recorded per theme

Source: `bones/scripts/rc-a11y.sh`.

## Usage

```bash
rotkeeper.sh a11y [options]
```

## Options

```text
--css-dir DIR    Theme CSS directory; defaults to ASSETS_DIR/css
--report FILE    Report destination; defaults to bones/reports/a11y-report-*.md
--json           Emit machine-readable JSON instead of the markdown report
--dry-run        Run the audit without writing the report
--verbose        Show detailed log output
--help, -h       Show this help message and exit
--version, -v    Show script version and quit
```

## Examples

```bash
bash rotkeeper.sh a11y                    # Audit all themes, write reports
bash rotkeeper.sh a11y --json             # Machine-readable findings
```

## Exit codes

```text
0    All themes pass
1    One or more themes fail, or audit error
```

## Reads and writes

**Environment:** reads ASSETS_DIR, BONES_DIR, CONFIG_DIR, DRY_RUN, LOG_DIR, LOG_FILE, REPORT_DIR, ROOT_DIR, SCRIPT_DIR, TEMPLATE_DIR, TMP_DIR, VERSION (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.

**Working directory:** No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.

**Inputs and outputs:** statically reads theme templates and their stylesheets, following CSS imports inside the asset CSS tree. Audits semantic/hardcoded color pairs across default, dark, and palette scopes, focus indicators, and overflow/pre-wrap strategies for wide tables and code.
Body/code text pairs fail below 4.5:1; softer pairs warn between 3.0:1 and 4.5:1 and fail below 3.0:1. Missing focus-visible replacements for suppressed outlines are flagged. Writes a per-theme report or emits JSON; failed themes return nonzero. No browser is required.

## Side effects

- **write:** mktemp creates a bones/tmp scratch file holding the JSON/dry-run result (removed after emit)
- **delete:** removes the bones/tmp result scratch file after emit

## Notes
<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->

### Design

The command runs an embedded Python 3 auditor. It discovers stylesheet
links in HTML templates, follows `@import url(...)` chains in import-first
order, and groups templates that share the same resolved stylesheet chain.
Findings describe CSS scopes, not rendered pages.

The auditor reads hexadecimal custom properties for semantic contrast pairs,
checks hardcoded color/background pairs, and looks for focus and overflow
rules. Its report separates passing, warning, failing, and skipped checks.
See [theme guidance](../../themes.html) and
[creating themes](../../creating-themes.html).

### Limits

This is a static, regex-based check, not a browser or full WCAG conformance
test. Missing semantic color tokens are skipped. A passing audit does not
establish that every element has usable focus, that every palette is
covered, or that a particular viewport renders correctly.

Discovery uses only the first recognized CSS link in each template. Templates
without a resolvable stylesheet chain are listed as skipped. The color parser
does not evaluate arbitrary CSS expressions or DaisyUI's oklch palettes.

Warnings alone do not produce a failing exit status. Put `--dry-run` and
`--verbose` before command-specific options: the shared flag parser stops at
the first unrecognized option.

### Cautions

`--css-dir` must resolve inside `ASSETS_DIR`, but imported paths are not
checked against that boundary. Audit trusted stylesheets.

`--report` is not restricted to `REPORT_DIR` by the implementation. Relative
report paths resolve from `ROOT_DIR`; an existing destination is overwritten.
The command does not create a missing report parent directory.

`--dry-run` runs the audit and keeps its Markdown preview in a temporary file
under `TMP_DIR`; it does not write the selected report. JSON mode removes
its result scratch file after emitting it. Both modes still write bootstrap
logs.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

No matching entries in CHANGELOG.md.
