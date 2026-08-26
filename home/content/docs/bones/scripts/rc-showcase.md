---
target_file: "bones/scripts/rc-showcase.sh"
date: "2026-08-26"
template: "rotkeeper-doc.html"
status: "active"
version: "0.5.1"
author: "Rotkeeper Ritual Council"
project: "Rotkeeper"
description: "Scaffolds a showcase page per HTML template into content/showcase/ and generates the static Theme Gallery index for side-by-side theme comparison."
tags:
  - rotkeeper
  - scripts
  - templates
  - showcase
---

# rc-showcase

**Script Path:** `bones/scripts/rc-showcase.sh`

## Overview

`rc-showcase.sh` backs the `showcase` dispatcher command — the template quality-assurance ritual, nicknamed the *Gallery of the Damned*. It gives every theme layout the same synthetic body so layout differences are directly comparable.

Per pass it:

1. Ensures `CONTENT_DIR/showcase/` exists.
2. For every `TEMPLATE_DIR/*.html`: scaffolds `showcase-<theme>.md` (the `theme-` prefix is stripped for the name). The frontmatter sets `title`/`slug`/`template` and adds **dummy values for every `$variable$` the template references** (except internal tokens like `body`, `endif`, `palette`, `assets_root`; `description` alternates on/off across themes so both states get exercised). The body is a fixed sample document — headings 1–6, bold/italic, blockquotes, tables, and code fences.
3. Structurally validates each template when an Oliver binary is available (`RK_OLIVER_BIN` or `PATH`): an empty template fails the run; without Oliver it warns and continues.
4. Regenerates the **Theme Gallery**: a grid-style `index.md` source in `content/showcase/` (one card per theme with a color swatch) plus a standalone hand-CSS copy written directly to `OUTPUT_DIR/showcase/index.html`.

Run `bash rotkeeper.sh render` afterwards to turn fresh showcase sources into viewable pages.

## CLI Usage

```bash
rotkeeper.sh showcase [options]

# Options:
#   --dry-run        Preview generated showcase pages without writing
#   --verbose        Show detailed logs
#   --help, -h       Show usage help
```

### Environment assumptions

- **Reads:** `TEMPLATE_DIR` (every `.html`), `CONTENT_DIR`, optional `RK_OLIVER_BIN`.
- **Writes:** `CONTENT_DIR/showcase/showcase-<theme>.md` and `CONTENT_DIR/showcase/index.md` — inside the author-managed content tree; `OUTPUT_DIR/showcase/index.html` directly.
- **CWD:** none.

## Dangerous operations

- **Rewrites all showcase files on every run** — manual edits made to `content/showcase/*.md` are crushed by the next invocation; treat that directory as generated.
- The direct write to `OUTPUT_DIR/showcase/index.html` bypasses the render pipeline (it is a preview convenience, refreshed by this ritual alone).

###### CLI Usage
<!-- DIP-HELP-EXTRACTED: 2026-08-15T15:43:55Z -->

*Not found: autopsy help report missing (`bones/reports/autopsy-help.md`). Run: ./rotkeeper.sh autopsy --help-report*

## Ritual History
<!-- DIP-HISTORY-EXTRACTED: 2026-07-23T10:54:47Z -->

*Not found: no changelog/history entries matching `rc-showcase.sh`.*

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-07-04T15:41:00Z -->


### Bones of the Code
The template showcase generator. It loops through all theme templates under `bones/templates/` and spits out a static markdown file `showcase-${theme}.md` filled with nested headers, list elements, table patterns, and code fences. Its main purpose is to feed the rendering machine synthetic bodies to test layout aesthetics.

### Restless Spirits
This script is a vanity project for templates. It naively assumes `TEMPLATE_DIR` exists and contains standard files. It performs no safety check when stripping the `theme-` prefix, meaning a poorly named template could output files in unpredictable places.

### Ritual Warnings
Ensure `TEMPLATE_DIR` contains valid `.html` layouts. The output markdown is rewritten each run, meaning manual annotations added to the showcase files will be crushed.

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
