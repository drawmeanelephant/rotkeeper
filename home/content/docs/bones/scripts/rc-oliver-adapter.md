---
target_file: "bones/scripts/rc-oliver-adapter.sh"
date: "2026-08-26"
template: "rotkeeper-doc.html"
status: "active"
version: "0.7.0"
author: "Rotkeeper Ritual Council"
project: "Rotkeeper"
description: "Pure-Bash batch adapter for the Oliver renderer: per-page metadata extraction, soul-sidecar dominance, boundary checks, and template interpolation — driven by rc-render's TSV manifest."
tags:
  - rotkeeper
  - scripts
  - rendering
  - oliver
---

# rc-oliver-adapter

**Script Path:** `bones/scripts/rc-oliver-adapter.sh`

## Overview

`rc-oliver-adapter.sh` is the execution half of the render pipeline — an internal batch worker, not a user-facing ritual. `rc-render.sh` plans a batch with `oliver plan` and invokes this adapter with a TSV manifest; one row describes one page (source, destination, template, assets root, soul sidecar, Oliver binary, directory layout, dry-run/verbose flags).

Per row, in order:

1. **Boundary assertions** — source must resolve inside `CONTENT_DIR`, destination inside `OUTPUT_DIR`, sidecar inside `META_DIR`, template inside `TEMPLATE_DIR`; any escape aborts the whole batch. The Oliver binary must exist and be executable.
2. **Metadata extraction** — `oliver meta --from <format> --format json` reads frontmatter fields (title, description, author, date, template, palette, render_profile). Input format derives from the source extension (`.textile`, `.cook`) overriding the config default for that file.
3. **Soul dominance** — when a soul sidecar exists, its metadata overrides the page's own fields.
4. **Template resolution** — the page's `template:` field selects within `TEMPLATE_DIR`; unresolved or out-of-bounds templates are fatal.
5. **Body render** — `oliver render --from <format> --frontmatter yaml` produces the body HTML snippet (plus `--to xhtml` when the profile — config default overridden by per-page `render_profile:` — selects XHTML). Failures abort with the first stderr line; the XHTML-specific raw-HTML rejection gets an explicit remediation hint (`RawHtmlNotXmlWellFormed`). Warnings are logged and accumulated into shared files keyed by `RK_RENDER_ID` so the parent render can summarize them.
6. **Interpolation** — `oliver wrap` applies the template with merged metadata (`$title$`, `$body$`, `$assets_root$`, `$if$/$endif$` gating) and writes the final HTML to the destination. Under dry-run, writes are skipped.

The authoritative renderer contract lives in `home/content/docs/oliver-contract.md`.

## CLI Usage

```bash
# Internal — invoked by rc-render.sh, not run by hand:
rc-oliver-adapter.sh <batch_manifest.tsv>
```

### Environment assumptions

- **Reads:** the TSV batch manifest; `INPUT_FORMAT` and `RENDER_PROFILE` from the environment as defaults; `TMP_DIR` for scratch.
- **Writes:** rendered pages under `OUTPUT_DIR`; short-lived scratch files under `TMP_DIR` (metadata JSON, body snippets, error logs), removed per row; warning accumulators shared with the parent render.
- **CWD:** none — all paths arrive via the manifest and are canonicalized before checks.

## Dangerous operations

- Writes HTML only at the destination paths asserted to be inside `OUTPUT_DIR`; every other mutation is confined to `TMP_DIR` scratch that the adapter deletes itself.
- Any boundary violation, missing binary, invalid metadata JSON, or failed Oliver stage exits nonzero immediately — the parent render treats that as a failed batch and surfaces the first error line.

###### CLI Usage
<!-- DIP-HELP-EXTRACTED: 2026-08-15T15:43:55Z -->

*Not found: autopsy help report missing (`bones/reports/autopsy-help.md`). Run: ./rotkeeper.sh autopsy --help-report*

## Ritual History
<!-- DIP-HISTORY-EXTRACTED: 2026-08-13T10:51:03Z -->

- - Replaced the Apex renderer with [Oliver](https://github.com/drawmeanelephant/oliver): the adapter (`rc-apex-adapter.sh` → `rc-oliver-adapter.sh`) now drives `oliver render --from markdown` (stdin → stdout body HTML, stderr = warnings) and strips a leading YAML frontmatter block before the Markdown reaches Oliver, a pure CommonMark renderer; the environment override is `RK_OLIVER_BIN` (was `RK_APEX_BIN`), and the authoritative contract moved from `apex-contract.md` to `oliver-contract.md`.

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-08-12T00:38:36Z -->

*Not found: no soul sidecar for `bones/scripts/rc-oliver-adapter.sh`.*

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
