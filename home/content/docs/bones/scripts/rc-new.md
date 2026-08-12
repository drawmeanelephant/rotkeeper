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
The script automatically generates proper frontmatter keys (`title`, `slug`, `template`, `version`, `updated`, etc.) so the page is immediately ready for Apex rendering.

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
<!-- DIP-HELP-EXTRACTED: 2026-08-12T12:26:46Z -->

```text
rc-new.sh — Scaffold a new markdown file with required YAML frontmatter

Usage: rotkeeper.sh new <file>

Options:
  --title "Title"        Override auto-derived title; skip slug-from-filename
  --author "Name"        Override config-derived author
  --tags "tag1,tag2"     Comma-separated tags; rendered as YAML list
  --template "file.html" Override the configured default template
  --description "text"   Frontmatter description field
  --body "text"          Starting body content
  --url "https://..."    A URL to embed in the document (creates source skeleton)
  --subdir "path"        Directory under home/content/ to place the file
  --version, -v          Show script version and quit
  --help, -h             Show this help message and exit
  --dry-run              Preview actions without writing files
  --verbose              Enable detailed debug logging
```
