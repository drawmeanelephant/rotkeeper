---
title: "⚰️ rc-autopsy.sh Reference"
slug: rc-autopsy
target_file: "bones/scripts/rc-autopsy.sh"
date: "2026-08-26"
template: "rotkeeper-doc.html"
status: "active"
version: "0.5.1"
author: "Rotkeeper Ritual Council"
project: "Rotkeeper"
description: "Dissects the ritual scripts into reference reports: extracts every --help text and catalogs file-write operations with resolved paths."
tags:
  - rotkeeper
  - scripts
  - audit
  - reports
---

# ⚰️ rc-autopsy

**Script Path:** `bones/scripts/rc-autopsy.sh`

## Overview

`rc-autopsy.sh` produces the two self-describing reference reports that other tooling consumes:

1. **Help report** (`--help-report`, default) — invokes `bash <script> --help` on every known `rc-*.sh` plus `rotkeeper.sh` (with the environment load suppressed via `ROT_SKIP_ENV=true`) and stitches each help text into `bones/reports/autopsy-help.md`. Scripts that fail to answer `--help` fall back to grepping their flag strings, logged as `[WARN]`. A hardcoded allowlist of permitted rituals guarantees no rogue or stray script is ever executed during extraction. DIP stitches this report's blocks into per-script doc pages.
2. **Output report** (`--output-report`, default) — scans each script for file-write operations (`>`, `>>`, `tee`, `mv`, `cp`, `tar -cf/-ff`) and catalogs them in `bones/reports/autopsy-outputs.md` as a line-numbered table per script, with `$VAR` paths resolved against the live environment where possible. DIP uses this report to exclude generated artifacts from its audits.

With no mode flag both reports run (`--all` is explicit).

## CLI Usage

```bash
rotkeeper.sh autopsy [mode] [options]

# Modes:
#   --help-report    Extract --help output from all rc-*.sh into a reference report
#   --output-report  Scan scripts for file-write operations and catalog outputs
#   --all            Run both reports (default)

# Options:
#   --dry-run        Preview without writing
#   --verbose        Detailed logging
#   --help, -h       Show usage help
```

### Environment assumptions

- **Reads:** every script under `SCRIPT_DIR` plus `ROOT_DIR/rotkeeper.sh`; the exported `*_DIR` variables for path resolution in the output report.
- **Writes:** `bones/reports/autopsy-help.md` and `bones/reports/autopsy-outputs.md`.
- **CWD:** none.

## Dangerous operations

- **Executes project scripts** (`bash <script> --help`) — bounded by the hardcoded ritual allowlist; anything else under the scripts directory is skipped with a warning rather than run.
- Both reports are rewritten wholesale on each run.
- Everything else is read-only analysis; nothing in the content or output trees is touched.

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-07-04T15:41:00Z -->


### Bones of the Code
An undertaker for dead processes. It attempts deep logging and error parsing by scraping raw text files. It's essentially a glorified `grep` wrapped in a burial shroud, pretending to understand the final cries of dying code.

### Restless Spirits
Runaway log files are the hungry ghosts here, waiting to devour every last byte of your disk space if left unchecked. Furthermore, its regex-based parsing of multi-line stack traces is comically inadequate. It will slice a stack trace in half and present you with a meaningless limb.

### Ritual Warnings
Monitor your disk space, or this script will fill it with the endless screaming of past errors. Do not trust its interpretation of multi-line errors; it only understands the simplest of death rattles.

###### CLI Usage
<!-- DIP-HELP-EXTRACTED: 2026-08-15T15:43:55Z -->

*Not found: autopsy help report missing (`bones/reports/autopsy-help.md`). Run: ./rotkeeper.sh autopsy --help-report*

## Ritual History
<!-- DIP-HISTORY-EXTRACTED: 2026-07-23T10:54:47Z -->

*Not found: no changelog/history entries matching `rc-autopsy.sh`.*

## Environment
<!-- DIP-ENV-EXTRACTED: 2026-08-12T00:38:36Z -->

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
