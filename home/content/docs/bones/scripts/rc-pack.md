---
title: "📦 rc-pack.sh Reference"
slug: rc-pack
target_file: "bones/scripts/rc-pack.sh"
date: "2026-08-26"
template: "rotkeeper-doc.html"
status: "active"
version: "0.5.1"
author: "Rotkeeper Ritual Council"
project: "Rotkeeper"
description: "Ritual compression packager: seals rendered output (or source content, or the whole system) into integrity-checked tombs with embedded metadata, plus a Markdown-to-JSON export."
tags:
  - rotkeeper
  - scripts
  - packing
  - tombs
---

# 🪦 rc-pack.sh

<!-- The sacred rite of tomb sealing and export -->

**Script Path:** `bones/scripts/rc-pack.sh`

## Overview

`rc-pack.sh` is the embalmer: it turns living trees into self-describing archives under `bones/archive/`. Three mutually exclusive modes:

1. **Default** — packs `OUTPUT_DIR` into `tomb-<timestamp>.tar.gz`. Before compression, a generated `metadata.json` (name, SHA256 of the uncompressed tar, timestamp, mode, file count) is appended into the archive so every tomb carries its own provenance. The compressed archive is integrity-checked with `gzip -t`, and its checksum is recorded in `bones/manifest.txt`. The default pass also **exports Markdown to JSON**: every `.md` under `CONTENT_DIR` becomes an entry (`absolute_path`, `relative_path`, parsed `frontmatter`, full `source_markdown`) in `tomb-export-<timestamp>.json`, validated with `jq` before being installed.
2. **`--content`** — packs `CONTENT_DIR` only (excluding `help/` and `*_temp.md`) into `tomb-content-<timestamp>.tar.gz`, preserving author sources separately from rendered output.
3. **`--self`** — packs the entire system (`rotkeeper.sh`, `bones/`, content, output; excluding the archive directory itself) into `tombkit-<timestamp>.tar.gz`, also with embedded metadata.

Archive names carry a timestamp plus a per-process random tag, so two packs within the same second never collide. A cleanup hook removes any half-written archive if a pack fails mid-flight — no truncated `.tar` or `.gz` survives.

## CLI Usage

```bash
rotkeeper.sh pack [options]

# Options:
#   --self       Archive the full Rotkeeper system (dispatcher, bones/, home/, output/)
#   --content    Archive only home/content (source preservation)
#   --dry-run    Preview actions without writing files
#   --verbose    Detailed logs
#   --help, -h   Show usage help
```

### Environment assumptions

- **Reads:** `OUTPUT_DIR` (default mode requires it to exist), `CONTENT_DIR`, `BONES_DIR` (manifest).
- **Writes:** archives and JSON exports under `ARCHIVE_DIR`; appends archive lines to `bones/manifest.txt`; scratch space under `TMP_DIR` (metadata staging dirs are removed through `rk_guard_delete`).
- **Dependencies:** `bash`, `jq`, `tar`, `gzip`, a SHA-256 tool, `yq` v4.
- **CWD:** none.

## Dangerous operations

- Appends to `bones/manifest.txt` (the same ledger `scan` audits).
- Deletes its own scratch directories and partial archives — the scratch `rm -rf` is gated through `rk_guard_delete`, and interrupted packs clean up after themselves rather than leaving truncated tombs.
- Archives are additive; nothing outside `ARCHIVE_DIR`, `TMP_DIR`, and the manifest is ever modified.

## 🛣️ Navigation

<!-- Quick navigation links -->

- [Scripts Index](index.html)
- [Pack Reference](rc-pack.html)
- [Bones Home](../index.html)

<!--
Limerick 1:
In cryptic halls, the tombs were bound,
rc-pack wrapped each sacred mound.
With JSON in hand,
And tarball at command,
The archive was sealed and crowned.

Limerick 2:
Across dusty files where Markdown lay,
rc-pack called forth their text array.
It bundled and scribed,
Then logged what survived,
Ensuring no relic would stray.
-->

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-07-04T15:41:00Z -->


### Bones of the Code
The embalmer. It wraps the project's remains in a tarball and shoves JSON metadata in alongside it, hoping the next entity to find it can make sense of the mess.

### Restless Spirits
Its absolute reliance on `jq` means that without it, the metadata creation process crashes and burns. Furthermore, the formatting of the JSON metadata is prone to breaking if shell variables contain unescaped quotes or newlines.

### Ritual Warnings
Ensure `jq` is installed and functioning. Beware of injecting raw, unescaped text into the JSON metadata fields.

## Ritual History
<!-- DIP-HISTORY-EXTRACTED: 2026-08-12T00:38:36Z -->

- - Formalized `source_markdown` export contract in `rc-pack.sh` for decentralized payload packaging.
- - Update rc-pack.sh to include all config variations.
- - Enhance rc-pack.sh compression algorithm for smaller tarballs.
- - Update rc-pack.sh to handle content flag natively.
- `CHANGELOG.md` records parallel `rc-render.sh` processing, smaller `rc-pack.sh`

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
