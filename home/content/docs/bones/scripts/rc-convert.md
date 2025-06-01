---
title: "🔄 rc-convert.sh Reference"
slug: rc-convert
template: rotkeeper-doc.html
version: "v0.2.3-pre"
updated: "2025-06-01"
description: "Utility to convert between supported formats (Markdown, JSON, DocBook); preserves metadata and supports multi-step rituals."
tags:
  - rotkeeper
  - scripts
  - conversion
  - formats
asset_meta:
  name: "rc-convert.md"
  version: "v0.2.3-pre"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---
<!--
🎨 Sora Prompt:
"An alchemical chamber where rc-convert.sh transmutes files—Markdown, JSON, and DocBook scrolls swirl in a glowing circle of conversion runes."
-->
<!-- Begin Ritual Script Documentation -->

# 🔄 rc-convert.sh

<!-- The sacred rite of document transmutation -->

**Script Path:** `bones/scripts/rc-convert.sh`

## Purpose
<!-- Core objectives of rc-convert.sh -->
- Convert documentation files between supported formats: Markdown, JSON, and DocBook XML.
- Preserve metadata and frontmatter during conversion.
- Facilitate downstream processing by other Rotkeeper tools.

## CLI Interface
<!-- How to invoke the conversion ceremony -->
```bash
rc-convert.sh --input <file> --from <md|json|xml> --to <md|json|xml> [--output <file>] [-h|--help]
```

Supported options:
- `--input <file>`
  Source file path to convert.
- `--from <format>`
  Source format (`md`, `json`, `xml`).
- `--to <format>`
  Target format (`md`, `json`, `xml`).
- `--output <file>`
  Output file path (default: overwrite input).
- `-h, --help`
  Show usage and exit.

## Workflow Steps
<!-- Sequential rites performed by the script -->
1. **Verify Dependencies**
   - Ensure `pandoc`, `jq`, and `xmllint` are installed.
2. **Validate Input**
   - Check file existence and correct `--from` format.
3. **Execute Conversion**
   - Invoke Pandoc or relevant parser based on formats.
4. **Post-process**
   - Re-inject frontmatter and metadata if needed.
5. **Write Output**
   - Save converted document to the output path.

## Exit Codes
<!-- Symbolic outcomes of incantation -->
- `0` — Conversion succeeded.
- `1` — Invalid arguments or missing input.
- `2` — Conversion engine error.
- `3` — Post-processing failure.

## Examples
<!-- Sample invocations for celebratory rites -->
```bash
# Markdown to DocBook
./bones/scripts/rc-convert.sh --input docs/manual.md --from md --to xml

# DocBook to JSON
./bones/scripts/rc-convert.sh --input build/manual.xml --from xml --to json --output manual.json

# JSON to Markdown in-place
./bones/scripts/rc-convert.sh --input data/notes.json --from json --to md
```

## Roadmap
<!-- Aspirational rites to come -->
- Support additional formats (e.g., EPUB, PDF metadata embedding).
- Add batch conversion mode for multiple files or directories.
- Integrate with CI to validate conversion on updates.
- Provide a `--validate` flag to check output against schemas.

## 🛣️ Navigation
<!-- Quick navigation links -->
- [Scripts Index](scripts/index.html)
- [Convert Reference](scripts/rc-convert.html)
- [Bones Home](index.html)

<!--
Limerick 1:
In runes of code and file decree,
rc-convert sets formats free.
It flows through each gate,
With metadata straight,
Ensuring no lore goes empty.

Limerick 2:
When scroll meets its destined form,
rc-convert weathers the storm.
From MD to XML,
Or JSON as well,
It crafts every page to transform.
-->