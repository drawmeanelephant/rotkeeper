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

No sidecar notes are documented for `bones/scripts/rc-a11y.sh`.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

No matching entries in CHANGELOG.md.
