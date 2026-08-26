---
title: "🧬 rc-dip.sh Reference"
target_file: "bones/scripts/rc-dip.sh"
date: "2026-08-26"
template: "rotkeeper-doc.html"
status: "active"
version: "0.5.1"
author: "Rotkeeper Ritual Council"
project: "Rotkeeper"
description: "The Document Improvement Project audit: discovers docs, classifies ownership and staleness, stubs missing reference pages, stitches dynamic pillars, and emits the DIP matrix."
tags:
  - rotkeeper
  - scripts
  - documentation
  - audit
---

# rc-dip.sh

**Script Path:** `bones/scripts/rc-dip.sh`

## Overview

`rc-dip.sh` backs the `dip` dispatcher command — the documentation lifecycle engine. One pass performs four audits over every page under `DOCS_DIR`:

1. **Discovery & classification.** Core-file inventory comes from the FSBook catalog (`bones/book-reports/rotkeeper-files.md`, via `book --fsbook`); without it, discovery degrades and no moves/stubs are decided. Each doc is classified as *generated* (has a `target_file`), *authored* (hand-written conceptual page), *stub* (still carrying TODO placeholders), *stale* (source newer than doc), or *unowned* (reported, never silently discarded).
2. **Obsolete handling.** A generated doc whose explicit `target_file` is no longer in the core inventory is moved to the obsolete tree — but only on that strong evidence. Ambiguous cases are reported as unowned, not moved.
3. **Stub generation.** Missing expected reference pages are scaffolded with frontmatter (including `target_file`) and the canonical section skeleton.
4. **Pillar stitching & matrix.** Four dynamic pillars per page are idempotently rewritten from live extraction: `## Environment` (variable listing), `###### CLI Usage` (from the autopsy help report), `## Ritual History` (CHANGELOG entries naming the script), and Necromancer's Notes (soul sidecars under `META_DIR`). Authored prose outside those pillars is preserved untouched. Finally `dip-matrix.md` summarizes the audit.

The obsolete-document move check honors `bones/config/dip-whitelist.txt` exemptions (that whitelist is not an exemption from matrix reporting or pillar stitching).

## CLI Usage

```bash
rotkeeper.sh dip [options]

# Options:
#   --dry-run      Preview actions without moving or writing docs
#   --verbose      Detailed output
#   --quiet        Suppress informational output
#   --help, -h     Show usage help
```

### Environment assumptions

- **Reads:** the FSBook catalog and autopsy reports (degrading gracefully with `[WARN]` when absent), soul sidecars under `META_DIR`, `CHANGELOG.md`, `bones/config/dip-whitelist.txt`.
- **Writes:** stub/moved docs under `DOCS_DIR` (obsolete destination: sibling `obsolete/docs/` tree), stitched pillars in existing docs, and `DOCS_DIR/dip-matrix.md`.
- **CWD:** none.

## Dangerous operations

- **Moves and creates files inside the content tree** (`home/content/docs/`) — stub creation, pillar rewrites, and obsolete moves all mutate author-visible pages. `--dry-run` previews every such action; run it first.
- Obsolete moves happen only with an explicit `target_file` pointing outside the current inventory; anything uncertain is reported instead.
- Stitching rewrites only marker-bounded pillar blocks; authored sections are structurally off-limits to the engine.

## Details

### CLI Usage

```text
--dry-run
--verbose
--quiet
--version
```

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-07-04T15:41:00Z -->


### Bones of the Code
The so-called Document Improvement Project engine. It ingests path-mirrored Necronotes to 'improve' things. It's a parasitic entity that feeds on sidecar files to alter the behavior or documentation of the host scripts.

### Restless Spirits
The newly refactored ingestion logic is a snake eating its own tail. It is highly susceptible to recursive stitching loops, where a note improves a note that improves a note, ad infinitum. Empty sidecars might also cause it to stumble and collapse, unable to process the void.

### Ritual Warnings
Do not feed it self-referential sidecars. Handle empty notes with care, or the engine will lock itself in a state of endless contemplation.

## Ritual History
<!-- DIP-HISTORY-EXTRACTED: 2026-07-23T10:54:47Z -->

-   `rc-book.sh`, `rc-dip.sh`, and `rc-glue.sh`.
- - Fix rc-dip.sh to properly stitch empty sidecars.
- - Streamline rc-dip.sh parsing logic.
- - Refactor rc-dip.sh to extract ritual history reliably.
- streamlined `rc-dip.sh` parsing, and removal of redundant `rc-env.sh`
- stitching in `rc-dip.sh`, and revised `rc-env.sh` resolution order.
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
