---
reference_contract: rotkeeper.command-reference.v1
title: rc-book.sh
slug: rc-book
target_file: bones/scripts/rc-book.sh
template: rotkeeper-doc.html
status: active
version: 0.8.1
author: Rotkeeper DIP
project: Rotkeeper
description: Bind documentation reports cleanly inside authorized boundaries
---

# rc-book.sh

## Overview

Bind documentation reports cleanly inside authorized boundaries

Source: `bones/scripts/rc-book.sh`.

## Usage

```bash
rotkeeper.sh book <mode> [options]
```

## Options

```text
Modes:
--fsbook          Filesystem catalog consumed by DIP for core-file discovery
--docbook         Bind documentation pages
--docbook-clean   Bind documentation pages, cleaning stale targets
--scriptbook-full Bind active scripts
--configbook      Bind configuration and templates
--contentbook     Bind content pages
--contentmeta     Emit content metadata
--collapse        Collapse a book or content tree
--all             Run all modes in sequence
--force-bind      Allow larger than safe default bind

--strip-frontmatter Strip frontmatter from applicable book bodies
--config FILE  Set the optional config argument
--dry-run      Preview the bind without writing
--verbose      Detailed output
--help, -h     Show help
--version, -v  Show version and quit
```

## Examples

```bash
bash rotkeeper.sh book --fsbook                          # Filesystem catalog for DIP
bash rotkeeper.sh book --docbook-clean --strip-frontmatter
bash rotkeeper.sh book --configbook --dry-run            # Preview config bind
```

## Exit codes

```text
0         Success
1         Bind failure or size safeguard refusal
3         Write-boundary violation
```

## Reads and writes

**Environment:** reads ARCHIVE_DIR, BONES_DIR, BOOK_REPORT_DIR, CONFIG_DIR, CONTENT_DIR, DOCS_DIR, DRY_RUN, LOG_DIR, OUTPUT_DIR, REPORT_DIR, ROOT_DIR, SCRIPT_DIR, TEMPLATE_DIR, TMP_DIR, VERSION (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.

**Working directory:** No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.

**Inputs and outputs:** reads scripts, documentation, content, configuration, templates, or the filesystem inventory according to the selected mode. Requires Bash and GNU awk; writes only under `BOOK_REPORT_DIR`.
Outputs are `rotkeeper-scriptbook-full.md`, `rotkeeper-docbook.md`, `rotkeeper-docbook-clean.md`, `rotkeeper-configbook.md`, `rotkeeper-contentbook.md`, `rotkeeper-contentmeta.yaml`, `rotkeeper-files.md`, and `collapsed-content.yaml`. Existing outputs are replaced, not archived.
Bound sections use START/END comments with source paths and a per-run random suffix. Books are retrieval aids, not authoritative policy. Filesystem catalogs exclude generated trees, Git data, logs, temporary files, and `.DS_Store`.
Documentation/content books accept `.md`, `.textile`, and `.cook`; clean documentation output strips frontmatter and adds page headings. Content metadata is a YAML list keyed by path; collapse emits title/subtitle/body block scalars.
Write-boundary violations exit 3. A documentation/content corpus over 5 MB requires `--force-bind`. All modes honor `--dry-run`; shared bootstrap logging still writes a run log.

## Side effects

- **write:** creates bones/book-reports if missing
- **write:** overwrites bones/book-reports/rotkeeper-scriptbook-full.md
- **write:** creates bones/book-reports if missing
- **write:** overwrites bones/book-reports/rotkeeper-docbook.md
- **write:** creates bones/book-reports if missing
- **write:** overwrites bones/book-reports/rotkeeper-docbook-clean.md
- **write:** creates bones/book-reports if missing
- **write:** overwrites bones/book-reports/rotkeeper-configbook.md
- **write:** creates bones/book-reports if missing
- **write:** overwrites bones/book-reports/rotkeeper-contentbook.md
- **write:** creates bones/book-reports if missing
- **write:** overwrites bones/book-reports/rotkeeper-contentmeta.yaml; entries appended below
- **write:** creates bones/book-reports if missing
- **write:** overwrites bones/book-reports/rotkeeper-files.md
- **write:** creates bones/book-reports if missing
- **write:** overwrites bones/book-reports/collapsed-content.yaml; bodies appended below
- **write:** creates bones/book-reports before any binder runs

## Notes
<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->

### Bones of the Code
This script binds scattered markdown souls into a single, monstrous RAG Tome. It agglomerates documentation, code, and whatever else it finds into one massive file, like a flesh golem made of text.

### Restless Spirits
Including raw configs and logs is a fool's errand. The token weight of this monstrous book will crush any LLM that attempts to read it. Furthermore, collapsing huge projects into a single shell variable or stream may invoke the dreaded OOM killer, as the shell's memory limits buckle under the weight of the project's ego.

### Ritual Warnings
Keep the project small, or watch this script choke on its own creation. Never feed the resulting tome to a language model without a robust token budget, lest you bankrupt your API account.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

### [0.4.1] - 2026-07-22

- Hardened strict-mode and quoting behavior across `rc-assets.sh`,
  `rc-book.sh`, `rc-dip.sh`, and `rc-glue.sh`.

### [v0.2.6-pre] - 2025-06-05

- `rc-book.sh` now supports `--all` mode and YAML collapse output

- Unified all binder generation into `rc-book.sh` (removes `rc-docbook.sh`, `rc-webbook.sh`)
