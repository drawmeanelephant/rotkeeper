---
target_file: "bones/scripts/rc-preflight.sh"
date: "2026-08-26"
template: "rotkeeper-doc.html"
status: "active"
version: "0.5.1"
author: "Rotkeeper Ritual Council"
project: "Rotkeeper"
description: "Single renderer health check: discovers the Oliver binary, asserts it is executable, and proves it runs via a live smoke render through the real CLI."
tags:
  - rotkeeper
  - scripts
  - preflight
  - renderer
---

# rc-preflight

**Script Path:** `bones/scripts/rc-preflight.sh`

## Overview

`rc-preflight.sh` backs the `preflight` dispatcher command and is **the** Oliver renderer health check. `render` routes through the same gate, so a passing preflight is the contract for "rendering is ready" (see `home/content/docs/oliver-contract.md`).

The check is deliberately deeper than "does the binary exist":

1. **Discovery** — `RK_OLIVER_BIN` override first, then `oliver` on `PATH`.
2. **Executability** — a found-but-not-executable binary fails with a targeted message.
3. **Live smoke render** — an empty document is piped through the real CLI (`oliver render --from <input_format>`, plus `--to xhtml` when `render_profile` selects it). A binary that exits nonzero or produces empty output fails, which is what catches incompatible Oliver builds — the CLI is provisional, so only a live render proves compatibility.

Exit status is `0` when rendering is ready and `1` with one actionable setup message otherwise (including copy-pasteable diagnosis of what was tried). Because Oliver has no stable release, setup instructions point at the pinned-build installer in `setup.sh`.

## CLI Usage

```bash
rotkeeper.sh preflight [options]

# Options:
#   --version, -v    Show script version and quit
#   --verbose        Show detailed findings
#   --dry-run        Report the check without invoking the Oliver binary
#   --help, -h       Show usage help
```

### Environment assumptions

- **Reads:** `RK_OLIVER_BIN` (binary override), `INPUT_FORMAT` and `RENDER_PROFILE` (smoke-render flags mirror the active config), `TMP_DIR` for smoke artifacts.
- **Writes:** three short-lived smoke files under `TMP_DIR` (`oliver-preflight-smoke.{md,html,log}`), removed again within the same run.
- **CWD:** none.

## Dangerous operations

None. The ritual writes and cleans up only its own smoke files in `TMP_DIR`; in `--dry-run` mode the Oliver binary is not invoked at all.

###### CLI Usage
<!-- DIP-HELP-EXTRACTED: 2026-08-15T15:43:55Z -->

*Not found: autopsy help report missing (`bones/reports/autopsy-help.md`). Run: ./rotkeeper.sh autopsy --help-report*

## Environment
<!-- DIP-ENV-EXTRACTED: 2026-08-13T10:51:03Z -->

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

## Ritual History
<!-- DIP-HISTORY-EXTRACTED: 2026-08-13T10:51:03Z -->

*Not found: no changelog/history entries matching `rc-preflight.sh`.*

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-08-13T10:51:03Z -->

*Not found: no soul sidecar for `bones/scripts/rc-preflight.sh`.*
