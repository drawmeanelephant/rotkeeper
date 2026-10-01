---
reference_contract: rotkeeper.command-reference.v1
title: rc-init.sh
slug: rc-init
target_file: bones/scripts/rc-init.sh
template: rotkeeper-doc.html
status: active
version: 0.8.1
author: Rotkeeper DIP
project: Rotkeeper
description: Minimal, non-destructive environment initialization
---

# rc-init.sh

## Overview

Minimal, non-destructive environment initialization

Source: `bones/scripts/rc-init.sh`.

## Usage

```bash
rotkeeper.sh init [options]
```

## Options

```text
--with-sample    Generate starter test-file.md
--with-assets    Run assets generation
--with-render    Run the render ritual
--full           Perform full sample, assets, render, and scan
--profile=STYLE  Set layout style (crypt, busy, sterile)
--dry-run        Preview actions without writing
--verbose        Show detailed logs
--help, -h       Show this help message and exit
--version, -v    Show script version and quit
```

## Examples

```bash
bash rotkeeper.sh init                        # Initialize with defaults
bash rotkeeper.sh init --full                 # Sample content + assets + render + scan
bash rotkeeper.sh init --with-sample --dry-run
```

## Exit codes

```text
0    Success
1    Initialization failure
```

## Reads and writes

**Environment:** reads ARCHIVE_DIR, ASSETS_DIR, BONES_DIR, BOOK_REPORT_DIR, CONFIG_DIR, CONTENT_DIR, DOCS_DIR, DRY_RUN, HELP_DIR, LAYOUT_STYLE, LOG_DIR, META_DIR, OUTPUT_DIR, RELEASE_DIR, REPORT_DIR, ROOT_DIR, SCRIPT_DIR, TEMPLATE_DIR, TMP_DIR, VERBOSE, WEB_DIR (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.

**Working directory:** No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.

**Inputs and outputs:** requires Bash and mikefarah yq v4+, marks command scripts/tests executable, and creates the content, output, and configuration directories without deleting existing content.
Writes `bones/config/rotkeeper.yaml`: seeds missing configuration, applies the selected layout, and serializes the full paths cache in one yq transaction, followed by a forced strict environment reload. This repairs relocation/layout-cache validation failures.
`--with-sample` creates `CONTENT_DIR/test-file.md` only if absent; `--with-assets` and `--with-render` delegate to those commands. `--full` includes sample, assets, render, and scan. Delegated commands retain their own write/delete contracts. Dry-run previews changes.

## Side effects

- **write:** creates home/content, output, and bones/config if missing
- **write:** seeds bones/config/rotkeeper.yaml when absent or empty
- **write:** rewrites rotkeeper.yaml in place with the serialized paths cache
- **write:** scaffolds home/content/test-file.md starter content

## Notes
<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->

### Bones of the Code
The Genesis script. It copies templates, blesses scripts, and bootstraps the project. It's the overly enthusiastic cult leader welcoming you to the compound.

### Restless Spirits
Its zealotry knows no bounds. When invoked with `--force`, it will violently overwrite existing configurations and clobber active directories without a second thought. It respects nothing that came before it.

### Ritual Warnings
Use `--force` only when you are entirely prepared to salt the earth and start anew. Keep backups of your configuration.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

### [0.3.0.17] - 2026-06-15

- fix: correct home/content path resolution in rc-init.sh
