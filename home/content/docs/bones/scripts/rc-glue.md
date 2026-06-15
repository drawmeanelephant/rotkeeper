---
title: "🧴 rc-glue.sh Reference"
slug: rc-glue
version: "0.3.0"
updated: "2026-06-15"
description: "Generates missing index.md files for directories in home/content/ to create navigation glue."
tags:
  - rotkeeper
  - scripts
  - navigation
  - glue
asset_meta:
  name: "rc-glue.md"
  version: "v0.3.0"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

<!--
🎨 Sora Prompt:
"A ghostly librarian frantically binding loose pages together with glowing spectral glue inside a dark, infinite archive."
-->

# 🧴 rc-glue.sh

<!-- The rite of binding the unindexed tombs -->
**Script Path:** `bones/scripts/rc-glue.sh`

## Purpose
- Recursively scans the `home/content/` directory.
- Identifies any directory that does not currently possess an `index.md` file.
- Automatically generates a structural `index.md` containing links to all immediate markdown files and sub-directories.
- Provides the critical "navigation glue" required to ensure that nested or ingested content is actually discoverable on the compiled site.

## CLI Interface
```bash
./rotkeeper.sh glue
```

## Workflow Steps
1. **Discover Directories**
   - Scans `home/content/` bottom-up using `find`.
2. **Check for Index**
   - For every directory, checks if `index.md` exists. If it does, the directory is skipped.
3. **Generate Glue**
   - If missing, a new `index.md` is generated.
   - It is populated with the Golden Path YAML frontmatter (`template: rotkeeper-blog.html`).
   - Links to all local `.md` files and subdirectories are appended as a markdown list.

## 🛣️ Navigation
- [Scripts Index](index.html)
- [Bones Home](../index.html)

<!--
Limerick:
An orphaned tomb deep in the night,
Had no index to step to the light.
The glue script was run,
The linking was done,
And the pages were all bound up tight.
-->
