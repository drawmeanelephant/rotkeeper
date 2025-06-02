---
title: "🌱 rc-expand.sh Reference"
slug: rc-expand
template: rotkeeper-doc.html
version: "0.2.5-pre"
updated: "2025-06-02"
description: "Expands the rotkeeper-bom.yaml into scaffolded markdown stubs and file structures, preparing tombs for ritual population. Now filters out any tomb manifests with `status: draft`."
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


# Note: rc-expand.sh now skips tomb manifests with `status: draft`.
# Flags:
#   --dry-run (-n)  Preview actions without creating files; skips drafts.
#   --verbose (-v)  Show detailed logs.
#   --help (-h)     Show usage information and exit.

## Workflow Steps
<!-- Sequential rites performed by the script -->
0. **Lint Frontmatter and Filter Draft Tombs**
   - Invoke `rc-lint.sh` to validate frontmatter of tomb manifests.
   - Skip any tomb manifests where `status: draft`, logging a notice.
1. **Parse Flags & Setup**: Handle `--dry-run`, `--verbose`, `--help`.
2. **Determine BOM Path**: Resolve `rotkeeper-bom.yaml` relative to script.
3. **Generate Stubs**: Create directories and markdown files with frontmatter.
4. **Copy Scripts & Resources**: Replicate scripts, configs, templates.
5. **Finalize**: Copy BOM for future runs and log completion.

## Dependencies

- `bash` (≥5.0)
- `yq` (≥4.2) for parsing YAML tomb manifests.
- `rc-lint.sh` for frontmatter validation.

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

# Dry-run example (skipping drafts without writing):
./bones/scripts/rc-expand.sh --dry-run
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