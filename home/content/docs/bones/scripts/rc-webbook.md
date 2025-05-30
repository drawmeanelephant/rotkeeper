---
title: "🌐 rc-webbook.sh Reference"
slug: rc-webbook
template: rotkeeper-doc.html
version: "0.2.1"
updated: "2025-05-29"
---
<!-- Begin Ritual Script Documentation -->

# 🌐 rc-webbook.sh

<!-- Converts a directory of Rotkeeper Markdown into a navigable HTML web-book -->

## Purpose
<!-- Core objectives of rc-webbook.sh -->
- Bundle selected Markdown files into a multi-page website with table of contents.
- Generate navigation links, next/prev buttons, and search index.
- Apply web-friendly layout, CSS, and responsive behaviors.

## CLI Interface
<!-- How to invoke the web-book ritual -->
```bash
rc-webbook.sh [--input <dir>] [--output <dir>] [--css <file>] [--search] [--help]
```

## Workflow Steps
<!-- Sequential rites performed by the script -->
1. **Verify Environment**
   - Ensure `pandoc`, `yq`, and a basic HTTP server are available.
2. **Collect Sources**
   - Read Markdown files from the input directory in sorted order.
3. **Build TOC**
   - Parse frontmatter titles and headings to construct a JSON or HTML table of contents.
4. **Render Pages**
   - Convert each Markdown to HTML with navigation controls (`prev`/`next`).
5. **Asset Injection**
   - Copy or link CSS, JS assets into the output directory.
6. **Search Index**
   - If `--search` is enabled, build a JSON index for client-side search.
7. **Serve/Preview**
   - Optionally launch a local server for preview (`python -m http.server`).

## Exit Codes
<!-- Symbolic outcomes of incantation -->
- `0` — Web-book generated successfully.
- `1` — Missing input directory or files.
- `2` — Dependency missing or runtime error.
- `3` — Navigation index build failure.

## Examples
<!-- Sample invocations for celebratory rites -->
```bash
# Generate a full web-book
./bones/scripts/rc-webbook.sh --input docs/bones --output public/book

# Include custom CSS
./bones/scripts/rc-webbook.sh --input docs/bones --output public/book --css assets/book.css

# Enable client-side search
./bones/scripts/rc-webbook.sh --input docs/bones --output public/book --search
```

## Roadmap
<!-- Aspirational rites to come -->
- Support EPUB and MOBI export alongside HTML.
- Embed annotations/comments directly into web-book pages.
- Add incremental rebuild for large docs sets.
- Integrate with CI to auto-publish on push to `gh-pages`.

<!--
Limerick 1:
From markdown paths to a clickable tome,
rc-webbook brings chapters to roam.
It weaves link and CSS,
In labyrinthine finesse,
And publishes the ritual for home.

Limerick 2:
In HTML halls of loreful delight,
rc-webbook shines in the night.
Each page gently flows,
As the index then grows,
And the codex emerges in light.
-->