---
title: "🔗 rc-links.sh Reference"
slug: rc-links
target_file: "bones/scripts/rc-links.sh"
date: "2026-07-23"
template: "rotkeeper-doc.html"
status: "active"
version: "0.5.0"
author: "Rotkeeper Ritual Council"
project: "Rotkeeper"
description: "Audit rendered HTML tombs for broken relative hyperlinks, local asset references, and angle-bracket link compatibility."
tags:
  - rotkeeper
  - scripts
  - audit
  - links
---

# 🔗 rc-links.sh

**Script Path:** `bones/scripts/rc-links.sh`

## Overview
`rc-links.sh` audits rendered HTML pages in `output/` to verify:
1. Relative HTML hyperlinks target existing pages.
2. Local asset references (`href` and `src`) exist under `output/assets/`.
3. Hyperlinks wrapped in angle brackets or Markdown formatting render without broken paths.

## CLI Usage

```bash
rotkeeper.sh links [options]

# Options:
#   --root DIR       Rendered directory to scan (defaults to output/)
#   --report FILE    Report destination (defaults to bones/reports/link-report-*.md)
#   --dry-run        Scan without writing a report
#   --verbose        Show detailed log output
#   --help, -h       Show usage help
```

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
###### CLI Usage
<!-- DIP-HELP-EXTRACTED: 2026-08-12T00:38:36Z -->

*Not found: autopsy help report missing (`bones/reports/autopsy-help.md`). Run: ./rotkeeper.sh autopsy --help-report*
## Ritual History
<!-- DIP-HISTORY-EXTRACTED: 2026-08-12T00:38:36Z -->

- - Added dispatcher link audit tool (`rc-links.sh` / `./rotkeeper.sh links`) for link checking and local asset verification with angle-bracket compatibility.

<!-- DIP-SOUL-EXTRACTED: 2026-08-12T00:39:14Z -->

*Not found: no soul sidecar for `bones/scripts/rc-links.sh`.*
