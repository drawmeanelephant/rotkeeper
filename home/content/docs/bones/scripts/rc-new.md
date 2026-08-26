---
title: "✨ rc-new.sh Reference"
slug: rc-new
target_file: "bones/scripts/rc-new.sh"
date: "2026-08-26"
template: "rotkeeper-doc.html"
status: "active"
version: "0.5.1"
author: "Rotkeeper Ritual Council"
project: "Rotkeeper"
description: "Scaffolds a new markdown, Textile, or Cooklang source file with valid YAML frontmatter — plus an optional soul sidecar — ready for the render ritual."
tags:
  - rotkeeper
  - scripts
  - scaffold
  - content
---

# `rc-new.sh`

**Script Path:** `bones/scripts/rc-new.sh`

## Overview

`rc-new.sh` backs the `new <file>` dispatcher command: it scaffolds a fresh content source with correct frontmatter so the page renders on the next pass. Invoking it with no file (or `--list`) prints the available templates instead of erroring, marking the configured default and any `$palette$` support.

Scaffold behavior:

- **Format-aware** — `.md`, `.textile`, and `.cook` are accepted as-is (a bare name gets `.md`). Markdown sources get a `#` heading, Textile an `h1.`, and Cooklang none (a recipe body is its own heading; a sample ingredient line is provided instead).
- **Frontmatter** — always `title` (from `--title` or derived from the filename), `slug` (slugified title), and `template` (`--template` or `default_template` from config, fallback `theme-spooky-dark.html`). Optional keys appear only when supplied: `description` (multi-line values become a YAML block scalar), `author` (`--author` or config `author`), `tags` (`--tags`, rendered as a quoted YAML list), and `source_url`.
- **URL skeletons** — with `--url`, the body becomes a research template (`## Source` / `## Notes` / `## Summary`) with the URL embedded.
- **Souls** — `--soul` also scaffolds the DIP sidecar at `META_DIR/<relative-path>.soul.md` via the traversal-guarded sidecar mapping; an existing sidecar is warned about, never overwritten.
- **Safety** — parent-directory traversal in the filename or `--subdir` is rejected, and the final path must canonicalize inside `CONTENT_DIR`. Existing files abort with an error; nothing is ever overwritten.

## CLI Usage

```bash
rotkeeper.sh new <file> [options]
rotkeeper.sh new --list

# Options:
#   --title "Title"        Override auto-derived title
#   --author "Name"        Override config-derived author
#   --tags "tag1,tag2"     Comma-separated tags; rendered as YAML list
#   --template "file.html" Override the configured default template
#   --description "text"   Frontmatter description field
#   --body "text"          Starting body content
#   --url "https://..."    Embed a URL (creates Source/Notes/Summary skeleton)
#   --subdir "path"        Directory under $CONTENT_DIR to place the file
#   --soul                 Also scaffold bones/meta/<path>.soul.md
#   --list                 List available templates and exit
#   --dry-run              Preview without writing files
```

### Environment assumptions

- **Reads:** `CONTENT_DIR` (destination root), `META_DIR` (soul sidecars), `CONFIG_DIR/rotkeeper.yaml` (`default_template`, `author`), `TEMPLATE_DIR` (for `--list`).
- **Writes:** exactly one new source file under `CONTENT_DIR`; with `--soul`, one new sidecar under `META_DIR`.
- **CWD:** none — relative names resolve against `CONTENT_DIR`.

## Dangerous operations

None destructive: the ritual only creates files and refuses to overwrite either the target page or an existing sidecar. Its guards (traversal rejection, canonical containment inside `CONTENT_DIR`) are fail-closed.

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
<!-- DIP-HELP-EXTRACTED: 2026-08-15T15:43:55Z -->

*Not found: autopsy help report missing (`bones/reports/autopsy-help.md`). Run: ./rotkeeper.sh autopsy --help-report*
