---
title: "🖨️ rc-render.sh Reference"
slug: rc-render
template: rotkeeper-doc.html
version: "v0.2.3-pre"
updated: "2025-06-01"
description: "Main rendering engine for converting Markdown tombs into HTML using Pandoc and custom templates."
tags:
  - rotkeeper
  - scripts
  - rendering
  - pandoc
asset_meta:
  name: "rc-render.md"
  version: "v0.2.3-pre"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

<!--
🎨 Sora Prompt:
"A cryptic ritual hall illuminated by rows of glowing <code>pandoc</code> invocations, candles flickering on terminal screens, as rc-render.sh weaves Markdown into spectral HTML pages."
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
- Renders Markdown pages from `home/content/` to HTML in `output/rendered/`
- Uses the `rotkeeper-doc.html` Pandoc template (if available)

## CLI Interface
<!-- How to invoke the rendering ceremony -->
```bash
rc-render.sh [--dry-run] [--verbose] [--help]
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
1. **Check Dependencies**
   - Ensure `pandoc`, `find`, `xargs`, and `date` are available.
2. **Initialize Logging**
   - Write to `bones/logs/rc-render.log`. All stdout and stderr are captured.
3. **Discover Markdown Files**
   - Recursively locate `*.md` pages to render.
   - Searches `home/content/` recursively for `.md` files.
4. **Render Files**
   - Process each Markdown file sequentially using Pandoc.
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
```

## 🛣️ Navigation
<!-- Quick navigation links -->
- [Scripts Index](scripts/index.html)
- [Render Reference](scripts/rc-render.html)
- [Bones Home](index.html)

<!--
Limerick 1:
A chorus of pandoc calls in sync,
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