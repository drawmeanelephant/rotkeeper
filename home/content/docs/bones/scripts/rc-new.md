---
title: "✨ rc-new.sh Reference"
slug: rc-new
version: "0.3.0.15"
updated: "2026-06-15"
description: "Scaffold a new markdown file with YAML frontmatter."
tags:
  - rotkeeper
  - scripts
  - scaffold
  - content
asset_meta:
  name: "rc-new.md"
  version: "0.3.0.15"
  author: "Rotkeeper Ritual Council"
---

# `rc-new.sh`

**Script Path:** `bones/scripts/rc-new.sh`

**Purpose:** Rapidly scaffold a new markdown file within `home/content/` (or its subdirectories) with the appropriate Rotkeeper YAML frontmatter.

## Usage
Through the Rotkeeper dispatcher:
```bash
./rotkeeper.sh new path/to/my-page.md
```

Directly:
```bash
./bones/scripts/rc-new.sh path/to/my-page.md
```

## Details
The script automatically generates proper frontmatter keys (`title`, `slug`, `template`, `version`, `updated`, etc.) so the page is immediately ready for Pandoc rendering.

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-07-04T15:41:00Z -->


### Bones of the Code
A glorified form filler that generates new markdown 'tombs' and slaps YAML frontmatter on them. It takes user input and attempts to coerce it into a valid filename.

### Restless Spirits
It is hopelessly naive about character escaping. Feed it a title with quotes, colons, or other exotic characters, and watch it generate malformed frontmatter and unreadable filenames. It's a breeding ground for syntax errors.

### Ritual Warnings
Stick to alphanumeric titles unless you enjoy manually untangling broken YAML and shell-escaped horrors.
## Ritual History
<!-- DIP-HISTORY-EXTRACTED: 2026-07-23T10:54:47Z -->

*Not found: no changelog/history entries matching `rc-new.sh`.*
## Environment
<!-- DIP-ENV-EXTRACTED: 2026-07-23T10:54:47Z -->

- **$ROOT_DIR**: /Users/tbuddy/dev/rotkeeper
- **$OUTPUT_DIR**: /Users/tbuddy/dev/rotkeeper/output
- **$CONTENT_DIR**: /Users/tbuddy/dev/rotkeeper/home/content
- **$ASSETS_DIR**: /Users/tbuddy/dev/rotkeeper/home/assets
- **$DOCS_DIR**: /Users/tbuddy/dev/rotkeeper/home/content/docs
- **$HELP_DIR**: /Users/tbuddy/dev/rotkeeper/home/content/help
- **$BONES_DIR**: /Users/tbuddy/dev/rotkeeper/bones
- **$SCRIPT_DIR**: /Users/tbuddy/dev/rotkeeper/bones/scripts
- **$CONFIG_DIR**: /Users/tbuddy/dev/rotkeeper/bones/config
- **$LOG_DIR**: /Users/tbuddy/dev/rotkeeper/bones/logs
- **$TMP_DIR**: /Users/tbuddy/dev/rotkeeper/bones/tmp
- **$ARCHIVE_DIR**: /Users/tbuddy/dev/rotkeeper/bones/archive
- **$REPORT_DIR**: /Users/tbuddy/dev/rotkeeper/bones/reports
- **$BOOK_REPORT_DIR**: /Users/tbuddy/dev/rotkeeper/bones/book-reports
- **$TEMPLATE_DIR**: /Users/tbuddy/dev/rotkeeper/bones/templates
- **$META_DIR**: /Users/tbuddy/dev/rotkeeper/bones/meta
- **$WEB_DIR**: /Users/tbuddy/dev/rotkeeper/output
###### CLI Usage
<!-- DIP-HELP-EXTRACTED: 2026-07-23T10:54:47Z -->

*Not found: autopsy help report missing (`/Users/tbuddy/dev/rotkeeper/bones/reports/autopsy-help.md`). Run: ./rotkeeper.sh autopsy --help-scan*
