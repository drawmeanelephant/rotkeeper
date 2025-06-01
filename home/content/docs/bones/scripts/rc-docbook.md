---
title: "📖 rc-docbook.sh Reference"
slug: rc-docbook
template: rotkeeper-doc.html
version: "v0.2.3-pre"
updated: "2025-06-01"
description: "Converts Markdown files with Rotkeeper frontmatter into DocBook XML chapters. Pending deprecation in favor of rc-book.sh."
tags:
  - rotkeeper
  - scripts
  - docbook
  - legacy
status: "deprecating"
asset_meta:
  name: "rc-docbook.md"
  version: "v0.2.3-pre"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---
<!-- Begin Ritual Script Documentation -->

# 📖 rc-docbook.sh

<!-- Converts Markdown with Rotkeeper frontmatter into DocBook XML for offline manuals -->

## Purpose
<!-- Core objectives of rc-docbook.sh -->
- Transform curated Markdown pages into valid DocBook XML chapters.
- Preserve metadata and section structure (frontmatter, headings, code blocks).
- Facilitate generation of cohesive PDF/HTML manuals.

## CLI Interface
<!-- How to invoke the DocBook ritual -->
```bash
rc-docbook.sh [--input <dir>] [--output <file>] [--toc <level>] [--help]
```

## Workflow Steps
<!-- Sequential rites performed by the script -->
1. **Verify Dependencies**
   - Ensure `pandoc` with DocBook support is installed.
2. **Gather Sources**
   - Read Markdown files from `<input>` directory.
3. **Extract Metadata**
   - Parse frontmatter for title, author, version.
4. **Convert to DocBook**
   - Invoke `pandoc` to produce DocBook XML.
   - Inject `<toc>` sections up to the specified level.
5. **Post-process**
   - Apply XSLT transforms if configured.
   - Validate resulting XML.
6. **Write Output**
   - Write combined XML to `<output>` path.

## Exit Codes
<!-- Symbolic outcomes of incantation -->
- `0` — Conversion succeeded without errors.
- `1` — Missing input files or directories.
- `2` — Pandoc or dependencies not found.
- `3` — XML validation errors.

## Examples
<!-- Sample invocations for celebratory rites -->
```bash
# Generate a complete manual XML
./bones/scripts/rc-docbook.sh --input docs/bones --output build/manual.xml --toc 2

# Produce a single-chapter XML
./bones/scripts/rc-docbook.sh --input docs/bones/scripts --output build/scripts.xml --toc 1
```


<!-- 🎴 Limerick 1:
From markdown’s plains to DocBook high,
rc-docbook lets your manuals fly.
It reads every note,
From frontmatter’s quote,
And crafts XML that won’t lie.
-->

<!-- 🎴 Limerick 2:
When manual builds felt dreary and long,
this script sang a transformation song.
With pandoc in play,
It led the way,
And made your docs sturdy and strong.
-->