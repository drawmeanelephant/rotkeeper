---
title: "🌱 rc-expand.sh Reference"
slug: rc-expand
template: rotkeeper-doc.html
version: "v0.2.3-pre"
updated: "2025-06-01"
description: "Expands the rotkeeper-bom.yaml into scaffolded markdown stubs and file structures, preparing tombs for ritual population."
tags:
  - rotkeeper
  - scripts
  - expansion
  - stubs
asset_meta:
  name: "rc-expand.md"
  version: "v0.2.3-pre"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---
<!--
🎨 Sora Prompt:
"A spectral workshop where ancient BOM scrolls unroll themselves into blank Markdown templates, awaiting the scribe’s ritual incantations."
-->
<!-- Begin Ritual Script Documentation -->

# 🌱 rc-expand.sh

<!-- The sacred rite of content stub generation -->

## Purpose
<!-- Core objectives of rc-expand.sh -->
- Read `rotkeeper-bom.yaml` to identify tomb sections and asset patterns.
- Generate initial Markdown files and directory structures for each section.
- Populate frontmatter and stub headers for future content.

## CLI Interface
<!-- How to invoke the expansion ceremony -->
```bash
rc-expand.sh [--dry-run] [--verbose] [--help]
```

Supported options:
- `--help`, `-h`
  Show usage information and exit.
- `--dry-run`
  Preview actions without writing stubs.
- `--verbose`
  Show detailed logs.

## Workflow Steps
<!-- Sequential rites performed by the script -->
1. **Parse Flags & Setup**: Handle `--dry-run`, `--verbose`, `--help`.
2. **Determine BOM Path**: Resolve `rotkeeper-bom.yaml` relative to script.
3. **Generate Stubs**: Create directories and markdown files with frontmatter.
4. **Copy Scripts & Resources**: Replicate scripts, configs, templates.
5. **Finalize**: Copy BOM for future runs and log completion.

## Exit Codes
<!-- Symbolic outcomes of incantation -->
- `0` — Stubs generated successfully.
- `1` — BOM file not found or parse error.
- `2` — I/O error during directory or file creation.

## Examples
<!-- Sample invocations for celebratory rites -->
```bash
# Default expansion
./bones/scripts/rc-expand.sh

# Preview expansion without changes
./bones/scripts/rc-expand.sh --dry-run

# Verbose expansion with detailed logs
./bones/scripts/rc-expand.sh --verbose

# Show help
./bones/scripts/rc-expand.sh --help
```

<!--
Limerick 1:
From BOM’s deep vaults, the stubs emerge,
rc-expand guides each hollow dir’s surge.
It weaves frontmatter light,
In the still of the night,
And readies pages for lore’s great purge.

Limerick 2:
In corridors of YAML decree,
rc-expand unlocks each MD entry.
It scaffolds with grace,
Then vanishes its trace,
Leaving blank tomes for scribes to decree.
-->