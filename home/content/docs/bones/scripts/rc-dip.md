---
reference_contract: rotkeeper.command-reference.v1
title: rc-dip.sh
slug: rc-dip
target_file: bones/scripts/rc-dip.sh
template: rotkeeper-doc.html
status: active
version: 0.8.1
author: Rotkeeper DIP
project: Rotkeeper
description: Document Improvement Project - audits and fixes docs
---

# rc-dip.sh

## Overview

Document Improvement Project - audits and fixes docs

Source: `bones/scripts/rc-dip.sh`.

## Usage

```bash
rotkeeper.sh dip [options]
```

## Options

```text
--dry-run      Preview actions without moving or writing docs
--verbose      Detailed output
--quiet        Suppress informational output
--json         Emit a machine-readable DIP matrix JSON on stdout
--help, -h     Show help
--version, -v  Show version and quit
```

## Examples

```bash
bash rotkeeper.sh dip --dry-run     # Audit without moving or writing docs
bash rotkeeper.sh dip               # Full audit and matrix publication
bash rotkeeper.sh dip --json | jq . # Machine-readable matrix output
```

## Exit codes

```text
0         Audit completed (findings live in the matrix report)
nonzero   Audit could not complete
```

## Reads and writes

**Environment:** reads ARCHIVE_DIR, ASSETS_DIR, BONES_DIR, BOOK_REPORT_DIR, CONFIG_DIR, CONTENT_DIR, DEBUG, DOCS_DIR, DRY_RUN, HELP_DIR, LOG_DIR, META_DIR, OUTPUT_DIR, QUIET, REPORT_DIR, ROOT_DIR, SCRIPT_DIR, TEMPLATE_DIR, TMP_DIR, WEB_DIR (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.

**Working directory:** No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.

**Inputs and outputs:** reads the fsbook core inventory, script headers/static help/side-effect annotations, sidecars, CHANGELOG, and documentation ownership. Generates a missing catalog on demand; a degraded inventory cannot authorize obsolete moves.
Rebuilds missing or explicitly owned script references under `DOCS_DIR` with the command-reference v1 contract. Authored task guides are not replaced. Non-command mirrors retain authored prose while Notes/History and marker-owned runtime sections are migrated.
Obsolete moves require explicit target_file evidence and honor the whitelist; ambiguous pages are reported unowned. Publishes `DOCS_DIR/dip-matrix.md`; `--json` adds the unchanged `rotkeeper.dip-matrix.v1` envelope to stdout. Dry-run previews doc/matrix mutations; shared bootstrap logging still writes.

## Side effects

- **write:** creates the destination directory, writes <dest>.tmp.$$, then
  replaces <dest> atomically via mv; removes the temp file on write failure.
- **delete+write:** drops the extracted-content scratch file and replaces the
  stitched doc in place with the rewritten temp file
- **delete/move:** relocates an obsolete doc under bones/obsolete (source is
  consumed by the move); never clobbers an existing destination
- **write:** creates the doc directory and writes a stub doc in place
- **write:** creates a bones/tmp scratch file for stdout JSON assembly
- **write:** appends the stdout JSON object to the per-run log
- **delete:** removes the stdout JSON scratch file after emit
- **delete:** discards the identical matrix scratch copy

## Notes
<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->

### Bones of the Code
The so-called Document Improvement Project engine. It ingests path-mirrored Necronotes to 'improve' things. It's a parasitic entity that feeds on sidecar files to alter the behavior or documentation of the host scripts.

### Restless Spirits
The newly refactored ingestion logic is a snake eating its own tail. It is highly susceptible to recursive stitching loops, where a note improves a note that improves a note, ad infinitum. Empty sidecars might also cause it to stumble and collapse, unable to process the void.

### Ritual Warnings
Do not feed it self-referential sidecars. Handle empty notes with care, or the engine will lock itself in a state of endless contemplation.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

### [0.4.1] - 2026-07-22

- Hardened strict-mode and quoting behavior across `rc-assets.sh`,
  `rc-book.sh`, `rc-dip.sh`, and `rc-glue.sh`.

### [0.4.0.4] - 2026-07-01

- Fix rc-dip.sh to properly stitch empty sidecars.

### [0.4.0.5] - 2026-07-01

- Streamline rc-dip.sh parsing logic.

### [0.4.0.3] - 2026-06-30

- Refactor rc-dip.sh to extract ritual history reliably.
