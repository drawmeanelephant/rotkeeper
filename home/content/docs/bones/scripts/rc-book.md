---
title: "📚 rc-book.sh Reference"
slug: rc-book
target_file: "bones/scripts/rc-book.sh"
date: "2026-08-26"
template: "rotkeeper-doc.html"
status: "active"
version: "0.5.1"
author: "Rotkeeper Ritual Council"
project: "Rotkeeper"
description: "The binder ritual: aggregates scripts, docs, config, content, and the filesystem catalog into retrieval books under bones/book-reports, with boundary and size safeguards."
tags:
  - rotkeeper
  - scripts
  - docs
  - binders
---

# 📚 rc-book.sh

**Script Path:** `bones/scripts/rc-book.sh`

## Overview

`rc-book.sh` is the singular binder ritual behind the `book` dispatcher command. It compiles scattered sources into single retrieval artifacts — RAG tomes for humans and machines — replacing all prior per-book scripts. Every bound section is wrapped in `<!-- START <path>::<suffix> -->` / `<!-- END … -->` markers carrying a per-run random suffix.

Modes (one per run; no mode means `--all`):

- `--fsbook` — filesystem catalog (`rotkeeper-files.md`): every project file not pruned (`.git`, output/tmp/logs/reports/book-reports/archive trees, logs, `.DS_Store`, temp files). This catalog **feeds DIP's core-file discovery** — regenerate it after adding or removing files.
- `--docbook` / `--docbook-clean` — every `.md`/`.textile`/`.cook` under `DOCS_DIR` bound verbatim (`rotkeeper-docbook.md`) or frontmatter-stripped with a title heading per page (`rotkeeper-docbook-clean.md`). `--strip-frontmatter` also applies to the content book.
- `--scriptbook-full` — all active `rc-*.sh` plus the dispatcher, each in a bash fence (`rotkeeper-scriptbook-full.md`).
- `--configbook` — YAML/YML/TPL/HTML files from `CONFIG_DIR` and `TEMPLATE_DIR` (`rotkeeper-configbook.md`).
- `--contentbook` — all content sources under `CONTENT_DIR` (`rotkeeper-contentbook.md`).
- `--contentmeta` — frontmatter of every content source as a YAML list keyed by path (`rotkeeper-contentmeta.yaml`).
- `--collapse` — folds all existing `rotkeeper-*.md` books into one `collapsed-content.yaml` (title/subtitle/body block scalars).
- `--all` — runs every mode in sequence.

Safeguards:

- **Write boundary** — every destination must canonicalize inside the repository/book-report zones; violations exit with code 3.
- **Size safeguard** — when the doc+content source corpus exceeds 5 MB, binding aborts unless `--force-bind` is given explicitly.
- **Dry-run** — previews the scriptbook/docbook/contentbook/fsbook modes without writing; note that `--configbook`, `--contentmeta`, and `--collapse` currently write their outputs even under `--dry-run`.

Book outputs are generated retrieval aids, not authoritative policy — verify source scripts and configuration when a binder conflicts with them.

## CLI Usage

```bash
rotkeeper.sh book --fsbook
rotkeeper.sh book --docbook | --docbook-clean | --scriptbook-full | --configbook
rotkeeper.sh book --contentbook | --contentmeta | --collapse | --all
# Shared options:
#   --dry-run            Preview binds without writing (see caveat above)
#   --strip-frontmatter  Strip frontmatter in docbook/contentbook bodies
#   --force-bind         Proceed past the 5 MB size safeguard
#   --help, -h           Show usage help
```

### Environment assumptions

- **Reads:** `DOCS_DIR`, `CONTENT_DIR`, `CONFIG_DIR`, `TEMPLATE_DIR`, `SCRIPT_DIR`, plus the repository tree for the fsbook walk.
- **Writes:** exclusively under `BOOK_REPORT_DIR` (`bones/book-reports/`) — the binder enforces this boundary and its 5 MB size safeguard.
- **Dependencies:** GNU awk (`require_gawk_version`); `bash`.
- **CWD:** none — root-relative throughout.

## Dangerous operations

- Overwrites its eight book artifacts on every run (no archiving of previous generations) and creates `BOOK_REPORT_DIR` if absent.
- The fsbook walk `cd`s to `ROOT_DIR` for the listing but writes only inside `BOOK_REPORT_DIR`; boundary breaches exit 3 before any write.
- `--force-bind` deliberately lifts the memory-friendly size safeguard — use only when a massive tome is intentional.

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-07-04T15:41:00Z -->


### Bones of the Code
This script binds scattered markdown souls into a single, monstrous RAG Tome. It agglomerates documentation, code, and whatever else it finds into one massive file, like a flesh golem made of text.

### Restless Spirits
Including raw configs and logs is a fool's errand. The token weight of this monstrous book will crush any LLM that attempts to read it. Furthermore, collapsing huge projects into a single shell variable or stream may invoke the dreaded OOM killer, as the shell's memory limits buckle under the weight of the project's ego.

### Ritual Warnings
Keep the project small, or watch this script choke on its own creation. Never feed the resulting tome to a language model without a robust token budget, lest you bankrupt your API account.

## Ritual History
<!-- DIP-HISTORY-EXTRACTED: 2026-07-23T10:54:47Z -->

-   `rc-book.sh`, `rc-dip.sh`, and `rc-glue.sh`.
- - `rc-book.sh` now supports `--all` mode and YAML collapse output
- - Unified all binder generation into `rc-book.sh` (removes `rc-docbook.sh`, `rc-webbook.sh`)
- `rc-book.sh` gained `--all` and YAML-collapse modes. Binder generation was
- unified in `rc-book.sh`; the former expansion and webbook rituals were
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
