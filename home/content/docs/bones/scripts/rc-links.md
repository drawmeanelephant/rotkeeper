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
