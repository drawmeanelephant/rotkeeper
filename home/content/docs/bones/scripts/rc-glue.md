---
reference_contract: rotkeeper.command-reference.v1
title: rc-glue.sh
slug: rc-glue
target_file: bones/scripts/rc-glue.sh
template: rotkeeper-doc.html
status: active
version: 0.8.1
author: Rotkeeper DIP
project: Rotkeeper
description: Generate navigation glue (index.md) for unindexed directories
---

# rc-glue.sh

## Overview

Generate navigation glue (index.md) for unindexed directories

Source: `bones/scripts/rc-glue.sh`.

## Usage

```bash
rotkeeper.sh glue [options]
```

## Options

```text
--path DIR       Limit glue to a directory under home/content/
--force          Refresh existing auto-generated indexes
--dry-run        Preview changes without writing
--verbose        Show detailed logs
--help, -h       Show this help message
--version, -v    Show script version and quit
```

## Examples

```bash
bash rotkeeper.sh glue                                # Glue all unindexed directories
bash rotkeeper.sh glue --path journal                 # One directory
bash rotkeeper.sh glue --force --dry-run              # Preview refresh
```

## Exit codes

```text
0    Success
1    Generation failure
```

## Reads and writes

**Environment:** reads BONES_DIR, CONFIG_DIR, CONTENT_DIR, DOCS_DIR, DRY_RUN, LOG_DIR, META_DIR, QUIET, ROOT_DIR, SCRIPT_DIR, TMP_DIR, VERBOSE (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.

**Working directory:** No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.

**Inputs and outputs:** reads directories and immediate `.md`, `.textile`, and `.cook` children under `CONTENT_DIR`, or a canonicalized `--path` subtree. Requires yq v4+ and GNU awk; destinations outside the content boundary are rejected.
Creates missing `index.md` files using the resolved default template and directory-sidecar frontmatter, with child links between ROTKEEPER-GLUE-START/END markers. Generated indexes carry `rotkeeper_glued: true`; `--force` removes and regenerates only those marked indexes.
Custom indexes keep their authored prose. An ordered single marker pair is replaced through a temporary file; otherwise glue is appended. Rewrite failures preserve the original. Dry-run previews writes without changing indexes.

## Side effects

- **delete:** removes the auto-glued index before regenerating it
- **write:** rewrites the glue block through <index>.tmp.$$ scratch, promoted by mv below
- **delete:** removes the scratch file on rewrite failure
- **write:** appends a fresh glue block to the custom index
- **write:** creates a new index.md with frontmatter and navigation glue

## Notes
<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->

### Bones of the Code
The dark arts of code injection and template stitching. It relies heavily on `awk` and `sed` to find markers and cram new organs into existing corpses. It's a butcher shop masquerading as a templating engine.

### Restless Spirits
String replacements using `awk` or `sed` are fundamentally fragile. Throw in a stray ampersand, an unescaped slash, or nested brackets, and the whole operation turns to mush. It will happily inject malformed code and leave you with a syntax error wrapped in an enigma.

### Ritual Warnings
Sanitize your inputs. If your injected code contains special characters, prepare for the regex parser to summon something unholy.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

### [0.4.1] - 2026-07-22

- Hardened strict-mode and quoting behavior across `rc-assets.sh`,
  `rc-book.sh`, `rc-dip.sh`, and `rc-glue.sh`.

### [0.3.0.9] - 2026-06-15

- fix: updated rc-glue.sh to support non-destructive overwriting using rotkeeper_glued frontmatter
