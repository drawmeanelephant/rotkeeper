---
reference_contract: rotkeeper.command-reference.v1
title: rc-showcase.sh
slug: rc-showcase
target_file: bones/scripts/rc-showcase.sh
template: rotkeeper-doc.html
status: active
version: 0.8.1
author: Rotkeeper DIP
project: Rotkeeper
description: Auto-scaffolds test pages for all HTML templates
---

# rc-showcase.sh

## Overview

Auto-scaffolds test pages for all HTML templates

Source: `bones/scripts/rc-showcase.sh`.

## Usage

```bash
rotkeeper.sh showcase [options]
```

## Options

```text
--dry-run        Preview generated showcase pages without writing
--verbose        Show detailed logs
--help, -h       Show this help message
--version, -v    Show script version and quit
```

## Examples

```bash
bash rotkeeper.sh showcase --dry-run      # Preview gallery scaffolding
bash rotkeeper.sh showcase                # Generate showcase content
```

## Exit codes

```text
0    Success
1    Generation failure
```

## Reads and writes

**Environment:** reads CONTENT_DIR, DRY_RUN, OLIVER_BIN, OUTPUT_DIR, RK_OLIVER_BIN, ROOT_DIR, SCRIPT_DIR, TEMPLATE_DIR (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.

**Working directory:** No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.

**Inputs and outputs:** reads every HTML template in `TEMPLATE_DIR`; overwrites generated `CONTENT_DIR/showcase/showcase-<theme>.md` sources, the gallery index source, and `OUTPUT_DIR/showcase/index.html`.
Template variables get sample frontmatter values except internal tokens; descriptions alternate present/absent across themes. A fixed sample body exercises headings, emphasis, quotes, tables, and code. Available Oliver validates templates; without it the command warns and continues.
The gallery HTML is a direct preview write, not a rendered page. Run `bash rotkeeper.sh render` after scaffolding to render showcase sources. Manual changes to generated showcase files are replaced on the next real run; dry-run previews only.

## Side effects

- **write:** creates home/content/showcase if missing
- **write:** overwrites home/content/showcase/showcase-<theme>.md (frontmatter + demo body)
- **write:** overwrites home/content/showcase/index.md gallery source
- **write:** creates output/showcase/ and overwrites its index.html

## Notes
<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->

### Bones of the Code
The template showcase generator. It loops through all theme templates under `bones/templates/` and spits out a static markdown file `showcase-${theme}.md` filled with nested headers, list elements, table patterns, and code fences. Its main purpose is to feed the rendering machine synthetic bodies to test layout aesthetics.

### Restless Spirits
This script is a vanity project for templates. It naively assumes `TEMPLATE_DIR` exists and contains standard files. It performs no safety check when stripping the `theme-` prefix, meaning a poorly named template could output files in unpredictable places.

### Ritual Warnings
Ensure `TEMPLATE_DIR` contains valid `.html` layouts. The output markdown is rewritten each run, meaning manual annotations added to the showcase files will be crushed.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

No matching entries in CHANGELOG.md.
