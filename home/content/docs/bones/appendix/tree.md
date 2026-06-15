---
title: "File Tree Structure"
slug: tree
description: "Directory layout and tomb structure for the Rotkeeper ritual system."
version: "0.2.3-pre"
updated: "2025-05-31"
tags:
  - rotkeeper
  - structure
  - filesystem
  - reference
asset_meta:
  name: "tree.md"
  version: "0.2.3-pre"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# 🌲 File Tree Structure

This document outlines the core directory structure used by Rotkeeper to organize tombs, configs, logs, and rendered outputs.

## 📁 Core Layout

```
rotkeeper/
├── bones/                  # Main tomb registry
│   ├── meta/               # Manuals, docbooks, and reference guides
│   ├── scripts/            # Ritual scripts (`rc-*.sh`)
│   ├── logs/               # Changelogs, scan reports, commit trails
│   ├── config/             # YAML configuration files
│   ├── archive/            # Packed `.tar.gz` tombs
│   └── appendices/         # Tree, formats, flags, glossary
├── tombs/                  # User-defined tombs and content
├── output/                 # Rendered HTML output
├── home/                   # Source Markdown for documentation
└── rc-utils.sh             # Shared logic for all ritual scripts
```

## 🪦 Notes

- All rituals are initiated from the root directory.
- `bones/` is version-controlled; `tombs/` may be .gitignored depending on your privacy preferences.
- `output/` should be considered disposable or publishable.
- All logs are plain text or YAML for human and undead readability.

> 🗂️ Structure is sacred. Rotkeeper walks the same tree in life and decay.