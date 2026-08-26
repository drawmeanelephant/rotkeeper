---
title: "🦴 rc-init.sh Reference"
slug: rc-init
target_file: "bones/scripts/rc-init.sh"
date: "2026-08-26"
template: "rotkeeper-doc.html"
status: "active"
version: "0.5.1"
author: "Rotkeeper Ritual Council"
project: "Rotkeeper"
description: "Non-destructive environment initialization: blesses scripts executable, verifies dependencies, creates core directories, and serializes the canonical path cache into rotkeeper.yaml."
tags:
  - rotkeeper
  - scripts
  - init
  - bootstrap
---

# 🦴 rc-init.sh

**Script Path:** `bones/scripts/rc-init.sh`

## Overview

`rc-init.sh` backs the `init` dispatcher command: the first ritual run on a new repository, and the repair tool whenever path validation complains. It is deliberately **non-destructive** and idempotent — safe to run repeatedly on a live tomb.

What it actually does, in order:

1. **Blesses scripts** — `chmod +x` on every `rc-*.sh` and `rc-*.bats` under `SCRIPT_DIR`.
2. **Verifies dependencies** — requires `bash` and mikefarah `yq` v4+ (`require_yq_version`).
3. **Creates core directories** — `mkdir -p` for `CONTENT_DIR`, `OUTPUT_DIR`, and `CONFIG_DIR` only; everything else is derived or already exists.
4. **Serializes the path cache** — writes the full canonical path mapping into the `paths` block of `bones/config/rotkeeper.yaml` in a *single* `yq` transaction, so a mid-write crash cannot leave the partially populated block that strict validation treats as fatal. A `--profile=<style>` argument also sets `.layout_style`. Afterwards it forces a strict environment reload (`FORCE_ENV_RELOAD=true`) to validate what was just written.
5. **Optional extras** — `--with-sample` writes a starter `test-file.md` into `CONTENT_DIR` (only when absent — existing files are never touched), `--with-assets` chains `rc-assets.sh`, `--with-render` chains `rc-render.sh --verbose`, `--full` enables all three plus `rc-scan.sh`.

## CLI Usage

```bash
rotkeeper.sh init [options]

# Options:
#   --profile=STYLE  Layout style for .layout_style (crypt | busy | sterile)
#   --with-sample    Generate starter content at $CONTENT_DIR/test-file.md
#   --with-assets    Run the assets ritual after initialization
#   --with-render    Run the render ritual after initialization
#   --full           Sample + assets + render + scan
#   --dry-run        Preview actions without writing
#   --verbose        Show detailed logs
#   --help, -h       Show usage help
```

### Environment assumptions

- **Reads:** `--profile` is exported as `LAYOUT_STYLE` before loading; standard `RK_*` flag defaults via `rk_init_script`.
- **Requires:** `ROOT_DIR`, `BONES_DIR`, `SCRIPT_DIR`, `CONFIG_DIR`, `LOG_DIR`, `TMP_DIR`, `CONTENT_DIR`, `DOCS_DIR`, `OUTPUT_DIR`, `RELEASE_DIR`.
- **Writes:** `bones/config/rotkeeper.yaml` (frontmatter title seed when missing, optional `layout_style`, full `paths` block); `$CONTENT_DIR/test-file.md` with `--with-sample`; log file under `LOG_DIR`.
- **CWD:** none — root-relative throughout.

## Dangerous operations

The gentlest ritual, but it does hold the pen that writes the path cache:

- The `paths` block in `rotkeeper.yaml` is overwritten wholesale. Because every other ritual trusts that cache (and exits rather than guessing when it looks wrong), a bad write here poisons the whole system — hence the single-transaction write followed by an immediate strict reload.
- Delegated rituals (`assets`, `render`, `scan`) perform their own writes/deletes; see their pages.
- Nothing is ever deleted by this script, and existing content files are never overwritten.

<!-- 🎴 Limerick 1:
A tomb with no bones is just lore,
So `init` lays the ground on the floor.
With each mkdir trace,
It prepares the ghost's place,
And beckons what scripts come before.
-->

<!-- 🎴 Limerick 2:
When the skeleton screeched for a scheme,
rc-init emerged like a dream.
It carved out each path,
From home to the math,
And ensured your rot cycle’s theme.
-->

## Related Rituals

- [`rc-new.sh`](rc-new.md) — scaffolds new content files
- [`rc-render.sh`](rc-render.md) — renders output after structure is seeded
- [`rc-book.sh`](rc-book.md) — generates documentation reports after init

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-07-04T15:41:00Z -->


### Bones of the Code
The Genesis script. It copies templates, blesses scripts, and bootstraps the project. It's the overly enthusiastic cult leader welcoming you to the compound.

### Restless Spirits
Its zealotry knows no bounds. When invoked with `--force`, it will violently overwrite existing configurations and clobber active directories without a second thought. It respects nothing that came before it.

### Ritual Warnings
Use `--force` only when you are entirely prepared to salt the earth and start anew. Keep backups of your configuration.

## Ritual History
<!-- DIP-HISTORY-EXTRACTED: 2026-07-04T15:41:00Z -->

- - fix: correct home/content path resolution in rc-init.sh

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
