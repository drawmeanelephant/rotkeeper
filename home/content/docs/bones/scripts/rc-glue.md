---
title: "🧴 rc-glue.sh Reference"
slug: rc-glue
target_file: "bones/scripts/rc-glue.sh"
date: "2026-08-26"
template: "rotkeeper-doc.html"
status: "active"
version: "0.5.1"
author: "Rotkeeper Ritual Council"
project: "Rotkeeper"
description: "Generates navigation glue — index.md files linking sibling pages and subdirectories — for unindexed directories under the content tree."
tags:
  - rotkeeper
  - scripts
  - navigation
  - glue
---

# 🧴 rc-glue.sh

<!-- The rite of binding the unindexed tombs -->
**Script Path:** `bones/scripts/rc-glue.sh`

## Overview

`rc-glue.sh` backs the `glue` dispatcher command: it walks the content tree and makes sure every directory is navigable, generating an `index.md` wherever one is missing and refreshing machine-generated indexes when asked.

Per-directory behavior:

1. **Discovery** — every directory under the target (default `CONTENT_DIR`, or a `--path` subtree) is visited.
2. **Index triage** — three cases:
   - *No index* → generate one: frontmatter built from `default_template` in `rotkeeper.yaml` (fallback `theme-spooky-dark.html`), merged with the folder's soul sidecar (`META_DIR/<relative-path>.soul.md`) when present; body is a link list of immediate subdirectories and `.md`/`.textile`/`.cook` sources wrapped in `<!-- ROTKEEPER-GLUE-START/END -->` markers.
   - *Auto-glued index* (frontmatter carries `rotkeeper_glued: true`) → skipped unless `--force` is given, in which case it is regenerated from scratch.
   - *Custom index* → left intact; if valid start/end glue markers exist, only the block between them is rewritten via `gawk`; otherwise the generated block is appended below the author's content. Manual prose is never removed.
3. **Safety bounds** — `--path` must canonicalize inside `CONTENT_DIR` (absolute or relative); anything escaping the content tree exits with an error.

## CLI Usage

```bash
rotkeeper.sh glue [options]

# Options:
#   --path DIR    Limit glue to a directory under $CONTENT_DIR
#   --force       Refresh existing auto-glued indexes
#   --dry-run     Preview changes without writing
#   --verbose     Show detailed logs
#   --help, -h    Show usage help
```

### Environment assumptions

- **Reads:** `CONTENT_DIR`, `META_DIR`, `CONFIG_DIR` (for `default_template`), plus standard flag defaults; folder souls from `META_DIR/<rel-path>.soul.md`.
- **Requires:** `yq` v4+ and GNU `awk` (`require_gawk_version`) — the marker surgery is gawk-specific.
- **Writes:** `index.md` files inside the content tree — this ritual writes into author-managed territory, which is why custom indexes are preserved and auto-generated ones are explicitly marked `rotkeeper_glued: true`.
- **CWD:** none; `--path` values resolve against `CONTENT_DIR`.

## Dangerous operations

- With `--force`, existing auto-glued `index.md` files are deleted and regenerated (`rm` of the marked file only — custom indexes are never removed).
- Custom indexes get their `ROTKEEPER-GLUE` block rewritten in place via a temp file + `mv`; on rewrite failure the temp file is discarded and the original is left untouched.
- Boundary rule: no file outside `CONTENT_DIR` is ever touched; `--path` escapes are refused.

## 🛣️ Navigation
- [Scripts Index](index.html)
- [Bones Home](../index.html)

<!--
Limerick:
An orphaned tomb deep in the night,
Had no index to step to the light.
The glue script was run,
The linking was done,
And the pages were all bound up tight.
-->

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-07-04T15:41:00Z -->


### Bones of the Code
The dark arts of code injection and template stitching. It relies heavily on `awk` and `sed` to find markers and cram new organs into existing corpses. It's a butcher shop masquerading as a templating engine.

### Restless Spirits
String replacements using `awk` or `sed` are fundamentally fragile. Throw in a stray ampersand, an unescaped slash, or nested brackets, and the whole operation turns to mush. It will happily inject malformed code and leave you with a syntax error wrapped in an enigma.

### Ritual Warnings
Sanitize your inputs. If your injected code contains special characters, prepare for the regex parser to summon something unholy.

## Ritual History
<!-- DIP-HISTORY-EXTRACTED: 2026-07-23T10:54:47Z -->

-   `rc-book.sh`, `rc-dip.sh`, and `rc-glue.sh`.
- - fix: updated rc-glue.sh to support non-destructive overwriting using rotkeeper_glued frontmatter
-   `rc-book.sh`, `rc-dip.sh`, and `rc-glue.sh`.

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
