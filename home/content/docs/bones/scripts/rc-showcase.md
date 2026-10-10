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
Template variables get sample frontmatter values except internal tokens; descriptions alternate present/absent across themes. A fixed sample body exercises headings, emphasis, quotes, tables, and code. When Oliver is available, an empty template stops the run with exit 1 before its page is written; without Oliver the command warns and continues.
The gallery HTML is a direct preview write, not a rendered page. Run `bash rotkeeper.sh render` after scaffolding to render showcase sources. Manual changes to generated showcase files are replaced on the next real run; dry-run previews only.

## Side effects

- **write:** creates home/content/showcase if missing
- **write:** overwrites home/content/showcase/showcase-<theme>.md (frontmatter + demo body)
- **write:** overwrites home/content/showcase/index.md gallery source
- **write:** creates output/showcase/ and overwrites its index.html

## Notes
<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->

### Design

Discovers top-level HTML templates in the active `TEMPLATE_DIR`, scaffolds `CONTENT_DIR/showcase/showcase-<name>.md`, and writes both a gallery source index and an immediate static gallery at `OUTPUT_DIR/showcase/index.html`. Names remove the `.html` suffix and optional `theme-` prefix. Sample frontmatter is derived from template tokens; a common body exercises headings, lists, quotes, tables, and code.

### Limits

Does not render the individual showcase pages; run render afterward to populate their linked HTML. The template-directory existence check is explicit. The optional Oliver check only tests whether a template is non-empty when an executable renderer is discoverable; it never invokes Oliver or validates the template dialect. An empty template stops the run with exit 1 before its page is written (also in dry-run), leaving later templates and the gallery indexes unwritten. The source gallery contains raw HTML, and per-template scaffolds do not automatically select XHTML profiles.

### Cautions

Real runs replace generated showcase sources and both gallery indexes, so manual additions there are lost. Templates whose names differ only by the removed `theme-` prefix map to the same showcase filename. Dry-run skips the showcase directory, page, and index writes but still writes bootstrap logs. The direct gallery output is a preview write, not a render-manifest update.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

No matching entries in CHANGELOG.md.
