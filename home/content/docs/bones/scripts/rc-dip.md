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

**Inputs and outputs:** reads the fsbook core inventory, script headers/static help/side-effect annotations, sidecars, CHANGELOG, documentation ownership, dip-whitelist.txt, and git commit dates. Generates a missing catalog on demand; a degraded inventory cannot authorize obsolete moves.
Rebuilds missing or explicitly owned script references under `DOCS_DIR` with the command-reference v1 contract. Authored task guides are not replaced. Non-command mirrors retain authored prose while Notes/History and marker-owned runtime sections are migrated.
Refreshes the opt-in command-index block in `DOCS_DIR/index.md` from dispatcher help and script mappings. Reports explicitly authored guides in docs/help separately, including review dates and placeholders.
Obsolete moves require explicit target_file evidence and honor bare whitelist paths; exempt: target | reason entries suppress stubs and stitching. Publishes `DOCS_DIR/dip-matrix.md`; `--json` retains `rotkeeper.dip-matrix.v1` with additive section, placeholder, sidecar coverage/orphan, exemption, and staleness fields. Dry-run previews doc/matrix mutations; shared bootstrap logging still writes.

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

### Design

Builds a core-file inventory from `bones/book-reports/rotkeeper-files.md`, excluding runtime artifacts, content, assets, and metadata. Generates a missing catalog on a real run. Creates missing or empty references and regenerates explicitly owned shell-script references from source headers, static help, side-effect annotations, sidecar notes, and matching CHANGELOG bullets. Publishes the audit matrix at `DOCS_DIR/dip-matrix.md`.

Refreshes only the opt-in marked command table in the existing Docs index,
using dispatcher help and script mappings without executing them. Explicit
`doc_type: guide` pages with no core ownership under Docs or Help are
author-managed and have a separate review-date and placeholder report.

### Limits

Sidecars supply documentation prose, not executable behavior, and do not enter the expected-document ownership map. Recursive generated tails are removed when harvesting their bodies; empty or absent notes receive a factual fallback. Non-empty unowned script pages are preserved. Non-command mirrors retain authored prose while marker-owned sections are updated. Core staleness compares committed timestamps, not checkout mtimes. The whitelist only exempts obsolete moves, not all reporting or stitching.

The command index requires one ordered marker pair and agreement between
dispatcher help and script-backed case arms. Unmarked indexes are untouched.
Guide review state checks recorded calendar dates against the guide's own
known committed edit date, not every script a guide may discuss. Unknown
path history cannot establish an edit after review. Guide metadata does not
override a mapped core reference or exempt a target from sidecar coverage.

### Cautions

An obsolete move requires explicit `target_file` evidence that its target is absent from the core inventory; a missing filesystem catalog disables those moves. Destinations are under the content parent’s `obsolete/docs` tree, not `bones/obsolete`. Existing catalogs are consumed rather than automatically refreshed, so regenerate the catalog when inventory changes. Dry-run avoids document/matrix publication and catalog generation but still writes bootstrap logs; `--json` also creates and removes a scratch file and emits the computed `rotkeeper.dip-matrix.v1` envelope alongside normal console output.

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
