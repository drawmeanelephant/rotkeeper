---
title: "🌐 rc-webbook.sh Reference"
slug: rc-webbook
template: rotkeeper-doc.html
version: "0.2.5-pre"
updated: "2025-06-02"
status: "draft"
description: "Generates a Markdown book of rendered HTML pages for static web use. Deprecated in favor of rc-book.sh."
tags:
  - rotkeeper
  - scripts
  - web
  - documentation
asset_meta:
  name: "rc-webbook.md"
  version: "0.2.5-pre"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# 🌐 rc-webbook.sh

**Script Path:** `bones/scripts/rc-webbook.sh`

## Purpose
- Bundle selected Markdown files into a multi-page website with table of contents.
- Generate navigation links, next/prev buttons, and search index.
- Apply web-friendly layout, CSS, and responsive behaviors.
- Note: This script is deprecated in favor of `rc-book.sh`.

## CLI Interface

```bash
rc-webbook.sh [--input <dir>] [--output <dir>] [--css <file>] [--search] [--help]
```

Supported flags:
- `--help`, `-h`
  Show this help page and exit.
- `--input <dir>`
  Directory containing source Markdown files (defaults to `home/content/`).
- `--output <dir>`
  Destination for generated HTML web-book (defaults to `output/webbook/`).
- `--css <file>`
  Path to a custom CSS file to include.
- `--search`
  Enable client-side search index generation.

## Workflow Steps

1. **Verify Environment**
   - Ensure `pandoc`, `yq`, `find`, `mkdir`, and `cat` are available.

2. **Collect Sources**
   - Read Markdown files from the input directory in sorted order.

3. **Build TOC**
   - Parse frontmatter titles and headings to construct a JSON or HTML table of contents.

4. **Render Pages**
   - Convert each Markdown to HTML with navigation controls (`prev`/`next`).

5. **Inject Assets**
   - Copy or link CSS and JS assets into the output directory.

6. **Generate Search Index**
   - If `--search` is enabled, build a JSON index of page content.

7. **Serve or Preview (Optional)**
   - Optionally launch a local server for preview (e.g., `python -m http.server`).

8. **Deprecated Notice**
   - Log a warning that `rc-webbook.sh` is deprecated and suggest using `rc-book.sh` instead.

## Dependencies

- `bash` (≥5.0)
- `pandoc` (≥2.11)
- `yq` (≥4.2)
- `find`, `mkdir`, `cat`, `tar` (standard Unix tools)

## Examples

- **Generate Web-Book**
  ```bash
  ./bones/scripts/rc-webbook.sh --input home/content/ --output public/webbook
  ```
  Creates a multi-page HTML site under `public/webbook`.

- **Include Custom CSS**
  ```bash
  ./bones/scripts/rc-webbook.sh --input home/content/ --output public/webbook --css assets/book.css
  ```

- **Enable Search Index**
  ```bash
  ./bones/scripts/rc-webbook.sh --input home/content/ --output public/webbook --search
  ```

- **Display Help**
  ```bash
  ./bones/scripts/rc-webbook.sh --help
  ```

## 🛣️ Navigation

- For details on book generation, see `rc-book.md`.
- To view frontmatter conventions, visit `yaml.md`.