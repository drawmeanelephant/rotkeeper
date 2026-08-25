---
title: "🦴 rc-a11y.sh Reference"
slug: rc-a11y
target_file: "bones/scripts/rc-a11y.sh"
date: "2026-08-25"
template: "rotkeeper-doc.html"
status: "active"
version: "0.5.1"
author: "Rotkeeper Ritual Council"
project: "Rotkeeper"
description: "Audit theme accessibility — WCAG contrast across palette scopes, focus states, and narrow-viewport table/code legibility — recorded per theme."
tags:
  - rotkeeper
  - scripts
  - audit
  - accessibility
---

# 🦴 rc-a11y.sh

**Script Path:** `bones/scripts/rc-a11y.sh`

## Overview

`rc-a11y.sh` audits every theme stylesheet reachable from `bones/templates/*.html` (following `@import` chains inside the assets CSS directory) and records results per theme:

1. **Contrast** — WCAG 2.x ratios for semantic color pairs (body text on page background and surface, code text on code background, secondary text and accent links on the page background) in *every* palette scope a stylesheet declares: default tokens, `prefers-color-scheme: dark` overrides, and opt-in `.palette-*` terminal variants. A heuristic sweep also flags hardcoded `color`/`background` pairs declared inside the same rule, which token-level checks cannot see.
2. **Focus states** — interactive elements must have `:focus` rules that paint a visible indicator; suppressed outlines without a `:focus-visible` replacement are flagged.
3. **Narrow-viewport legibility** — spot-checks that wide tables and code blocks declare an `overflow-x` or `pre-wrap` strategy.

Verdicts: hard pairs (body/code text) fail below WCAG AA 4.5:1; soft pairs (secondary text, accent links, accent fills) warn between 3.0:1 and 4.5:1 and fail below 3.0:1. Exit status is nonzero when any theme fails, so **new themes can be gated on passing**: `bash rotkeeper.sh a11y` belongs in pre-merge checks whenever templates or palettes change.

The audit is fully static — no browser is required.

## CLI Usage

```bash
rotkeeper.sh a11y [options]

# Options:
#   --css-dir DIR    Theme CSS directory (defaults to ASSETS_DIR/css)
#   --report FILE    Report destination (defaults to bones/reports/a11y-report-*.md)
#   --json           Emit machine-readable JSON to stdout instead of markdown
#   --dry-run        Run the audit without writing the report
#   --verbose        Show detailed log output
#   --help, -h       Show usage help
```

## Environment

<!-- DIP-ENV-EXTRACTED -->

## Environment
<!-- DIP-ENV-EXTRACTED: 2026-08-25T12:57:35Z -->

- **$ROOT_DIR**: .
- **$OUTPUT_DIR**: output
- **$CONTENT_DIR**: home/content
- **$ASSETS_DIR**: home/assets
- **$DOCS_DIR**: home/content/docs
- **$HELP_DIR**: home/content/help
- **$BONES_DIR**: bones
- **$SCRIPT_DIR**: bones/scripts
- **$CONFIG_DIR**: bones/config
- **$LOG_DIR**: bones/logs
- **$TMP_DIR**: bones/tmp
- **$ARCHIVE_DIR**: bones/archive
- **$REPORT_DIR**: bones/reports
- **$BOOK_REPORT_DIR**: bones/book-reports
- **$TEMPLATE_DIR**: bones/templates
- **$META_DIR**: bones/meta
- **$WEB_DIR**: output
###### CLI Usage
<!-- DIP-HELP-EXTRACTED: 2026-08-25T12:57:35Z -->

*Not found: autopsy help report missing (`bones/reports/autopsy-help.md`). Run: ./rotkeeper.sh autopsy --help-report*
## Ritual History
<!-- DIP-HISTORY-EXTRACTED: 2026-08-25T12:57:35Z -->

*Not found: no changelog/history entries matching `rc-a11y.sh`.*

<!-- DIP-SOUL-EXTRACTED: 2026-08-25T13:00:50Z -->

*Not found: no soul sidecar for `bones/scripts/rc-a11y.sh`.*
