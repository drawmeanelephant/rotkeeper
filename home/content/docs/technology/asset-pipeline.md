---
title: "📦 Asset Pipeline"
slug: asset-pipeline
template: rotkeeper-doc.html
version: "0.2.5-pre"
updated: "2025-06-03"
description: "Explains how assets like CSS, images, and JS are discovered, linked, and verified in the Rotkeeper system."
tags:
  - rotkeeper
  - pipeline
  - assets
  - rendering
asset_meta:
  name: "asset-pipeline.md"
  version: "0.2.5-pre"
  author: "Filed Systems"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# 📦 Asset Pipeline

Rotkeeper's asset pipeline governs how static files are copied, versioned, and injected into the tomb environment. It also defines how `asset-meta` tags are tracked and maintained throughout the build cycle.

***

## 📁 Asset Sources

Assets are typically sourced from:

```
home/assets/
home/themes/
home/icons/
```

These folders are expected to exist prior to running `rc-assets.sh` and are recursively scanned.

***

## 🔃 Copy Mechanisms

The primary tool for copying assets is `rc-assets.sh` (formerly ASSETELLA). It handles:

- Recursively copying from declared source folders
- Maintaining folder structure
- Logging each copied file into `bones/manifest.txt`
- Ensuring injected assets are recorded with `asset-meta`

You can run it standalone or via the main CLI:

```bash
./rotkeeper assets
```

Or directly:

```bash
./scripts/rc-assets.sh
```

***

## 📑 `asset-meta` Headers

Every tracked script, template, or asset should include an `asset-meta:` header — either as shell comment, HTML comment, or YAML frontmatter. These tags are required for changelog visibility and audit inclusion:

```bash
# --- asset-meta ---
# file: scripts/rc-render.sh
# version: 0.1.2
# tomb-version: 0.1.7.5
# tracked: true
# injected: 2025-05-12
# --- end-meta ---
```

These tags allow `rc-scan.sh` and `rc-pack.sh` to:

- Detect stale, duplicated, or unversioned assets
- Validate integrity during packing
- Confirm changelog eligibility

---

## 📂 Folders Typically Managed

| Folder | Description |
|--------|-------------|
| `scripts/` | Core and auxiliary `rc-*` scripts |
| `templates/` | HTML and partials for rendering |
| `assets/` | Static files like CSS, JS, fonts |
| `themes/` | Theme folders (e.g. HiQ) |
| `icons/` | SVG or emoji sets (e.g. OpenMoji) |

***

## ⚠️ Notes on Pipeline Behavior

- The pipeline **does not** deduplicate—it's your job to manage redundant files
- Files without `asset-meta` may be skipped during archive verification
- If a file is missing from `bones/manifest.txt`, it won’t be packed
- Use `rc-scan.sh` to validate what’s missing or untracked

***

## 🧪 Example Flow

```bash
./rotkeeper init         # creates structure
./rotkeeper assets       # injects static files
./rotkeeper render       # builds output
./rotkeeper pack         # archives everything in manifest.txt
```

***

Continue to [Template Library](template-library.md)
Back to [Configuration Reference](configuration-reference.md)

<!--
LIMERICK

The pipeline injected with grace,
Each asset assigned to its place.
With headers and tags,
It zipped into bags—
And logged its own rot with no trace.

SORA PROMPT

"a spectral asset pipeline copying ancient static files into a tomb, file paths glowing as they settle, digital ink bleeding from metadata"
-->