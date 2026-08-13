---
title: "🖨️ rc-render.sh Reference"
slug: rc-render
version: "0.5.0"
updated: "2026-07-23"
description: "Main rendering engine for converting Markdown tombs into HTML using Oliver and custom templates. Skips any Markdown with `status: draft`."
tags:
  - rotkeeper
  - scripts
  - rendering
  - oliver
asset_meta:
  name: "rc-render.md"
  version: "v0.5.0"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "All Rights Reserved"
---

<!--
🎨 Sora Prompt:
"A cryptic ritual hall illuminated by rows of glowing <code>oliver</code> invocations, candles flickering on terminal screens, as rc-render.sh weaves Markdown into spectral HTML pages."
-->
<!-- Begin Ritual Script Documentation -->

# 🎨 rc-render.sh

<!-- The sacred rite of tomb rendering -->
**Script Path:** `bones/scripts/rc-render.sh`

## Purpose
<!-- Core objectives of rc-render.sh -->
- Convert all Markdown documentation into HTML pages.
- Support custom templates, parallel execution, verbose logging, and dry-run previews.
- Emit detailed logs for ritual auditing.
- Renders Markdown pages from `home/content/` to HTML in `output/`
- Uses HTML templates via Oliver

## CLI Interface
<!-- How to invoke the rendering ceremony -->
```bash
rc-render.sh [--renderer oliver] [--dry-run] [--verbose] [--help]

# Note: rc-render.sh now runs lint first and skips drafts.
# Flags:
#   --dry-run (-n)  Preview actions without writing output; skips drafts and linting occurs first.
#   --verbose (-v)  Show detailed logs.
#   --help (-h)     Show usage information and exit.
```

Supported options:
- `--help`, `-h`
  Show usage information and exit.
- `--dry-run`, `-n`
  Preview actions without writing output.
- `--verbose`, `-v`
  Show detailed logs.

## Workflow Steps
<!-- Sequential rites performed by the script -->
0. **Filter Drafts**
   - Any Markdown file with `status: draft` is skipped with a log entry.
1. **Check Dependencies**
   - Ensure `find`, `xargs`, `date`, and `yq` are available.
2. **Initialize Logging**
   - Write to `bones/logs/rc-render.log`. All stdout and stderr are captured.
3. **Discover Markdown Files**
   - Recursively locate `*.md` pages to render.
   - Searches `home/content/` recursively for `.md` files.
4. **Render Files**
   - Process each Markdown file sequentially using Oliver.
5. **Log Results**
   - Record successes and failures with timestamps.
6. **Cleanup**
   - Remove temporary files on exit.

## Exit Codes
<!-- Symbolic outcomes of incantation -->
- `0` — All pages rendered successfully.
- `1` — Missing dependencies or invalid flags.
- `2` — One or more render failures.

Errors and render failures are logged to `bones/logs/rc-render.log`.

## Examples
<!-- Sample invocations for celebratory rites -->
```bash
# Default render
./bones/scripts/rc-render.sh

# Verbose output
./bones/scripts/rc-render.sh -v

# Dry-run (lint and draft skipping occur, but no output is written)
./bones/scripts/rc-render.sh --dry-run
```

## 🛣️ Navigation
<!-- Quick navigation links -->
- [Scripts Index](index.html)
- [Render Reference](rc-render.html)
- [Bones Home](index.html)

<!--
Limerick 1:
A chorus of oliver calls in sync,
rc-render fills each HTML link.
With logs signed in time,
And parallel rhyme,
It crafts each tomb page in a blink.

Limerick 2:
In Markdown crypts of silent gloom,
rc-render breathes each page to bloom.
It logs every start,
And edges apart,
Leaving no page in pending doom.
-->
## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-08-12T02:18:17Z -->


### Bones of the Code
This incantation is the beating, black heart of the Rotkeeper engine, responsible for transmuting lifeless Markdown tombs into fully fleshed HTML horrors. It sweepingly traverses the content catacombs, forcefully applies Oliver templates to the restless spirits within, and ultimately entombs the resulting digital husks in a compressed `.tar.gz` archive for safe, eternal slumber.

* **Oliver (`oliver`)**: The primary golem summoned to bend Markdown into HTML.
* **Link Rewriting (`rc-oliver-adapter.sh`)**: Rewrites internal `.md` links to `.html` during compilation.
* **YAML frontmatter extractor (`yq`)**: Used to surgically extract template preferences from the heads of corpses.
* **Tarball Archiver (`tar`)**: Compresses the resulting HTML husks into `bones/archive/tomb-*.tar.gz`.
* **Template Directory (`TEMPLATE_DIR`)**: The morgue containing the HTML layouts (e.g., `theme-light.html`, `rotkeeper-blog.html`).
* **Manifest (`MANIFEST`)**: A ledger (`bones/manifest.txt`) tracking every soul successfully rendered.

### Restless Spirits
This script is a masterclass in bureaucratic necromancy. I deeply appreciate the brutal efficiency of ignoring `output/`, `bones/`, and `docs/` using `find -prune` rather than some weak, post-processing `grep` filter. The fallback logic for when a corpse forgets to specify a template—blindly grabbing the first template it stumbles across in the dark—is exactly the kind of callous indifference to human error that I respect in a good system. The fact that it calculates its own runtime duration is just the script gloating about how quickly it can process the dead.

### Ritual Warnings
* The most glaring vulnerability is its blind trust in Oliver's handling of user-provided Markdown. If a template name is cleverly manipulated in the frontmatter to traverse directories (e.g., `../../etc/passwd`), this ritual could inadvertently attempt to read outside the `TEMPLATE_DIR`.
* The fallback template selection is reliant on whatever file globbing decides is first; one day, it will grab a template meant for internal torture rather than public display.
* If `ROOT_DIR` or `OUTPUT_DIR` somehow become unassigned or point to `/`, the recursive `mkdir -p` and path string replacements (`${mdpath#"$PROJ_ROOT"/}`) might attempt to entomb the entire operating system.
## Ritual History
<!-- DIP-HISTORY-EXTRACTED: 2026-07-23T10:54:47Z -->

- - Improve rc-render.sh error handling during template fallback.
- - Added parallel processing to rc-render.sh.
- - Strip frontmatter overrides and fix rc-render.sh to use rotkeeper.yaml
- - Fix template parsing bug in rc-render.sh using yq
- - Ensure rc-render.sh outputs proper HTML with valid tags.
- `CHANGELOG.md` records parallel `rc-render.sh` processing, smaller `rc-pack.sh`
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
<!-- DIP-HELP-EXTRACTED: 2026-08-13T10:51:03Z -->

```text
rc-render.sh — Render Markdown tombs into HTML (v0.5.3)

Usage: rc-render.sh [options]

Options:
  --version, -v    Show script version and quit
  --help, -h       Show this help message and exit
  --dry-run        Preview actions without invoking renderer
  --verbose        Show detailed logs
  --renderer NAME  Select renderer: oliver (the only supported renderer; pandoc was removed)

Examples:
  bash rotkeeper.sh render
  RK_OLIVER_BIN=/path/to/oliver bash rotkeeper.sh render --renderer oliver
```
