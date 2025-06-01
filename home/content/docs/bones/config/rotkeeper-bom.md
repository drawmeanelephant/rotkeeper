---
title: "📦 rotkeeper-bom.yaml Reference"
slug: rotkeeper-bom
template: rotkeeper-doc.html
version: "v0.2.3-pre"
updated: 2025-06-01
description: "Bill of Materials config for Rotkeeper asset and directory tracking"
tags:
  - rotkeeper
  - config
  - bom
asset_meta:
  name: "rotkeeper-bom.yaml"
  version: "v0.2.3-pre"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# 📦 rotkeeper-bom.yaml

<!-- The sacred inventory of all tomb contents -->

The `rotkeeper-bom.yaml` file lists all directories and asset patterns that Rotkeeper will manage. Each entry defines a tomb section and file globs to include.

| Key              | Pattern                       | Description                                  |
|------------------|-------------------------------|----------------------------------------------|
| `home/assets`    | `home/assets/**/*`            | All static assets to manifest                |
| `bones/scripts`  | `bones/scripts/*.sh`          | Shell scripts to document and execute        |
| `output/docs`    | `output/docs/**/*.html`       | Generated documentation pages                |
| `archive/**`     | `archive/**/*`                | Stored snapshots and artifacts               |
| *…*              | *…*                           | *Additional tomb sections*                   |

## 🛠️ Usage

<!-- How to apply the BOM in the ritual -->

Include `--bom rotkeeper-bom.yaml` when running Rotkeeper commands, or place it at the root for auto-discovery:

```bash
rc-assets.sh --bom rotkeeper-bom.yaml
rc-scan.sh --bom rotkeeper-bom.yaml
```

## 🛣️ Navigation

<!-- Quick links within configs -->
- [render-flags.yaml](render-flags.html)
- [rotkeeper-bom.yaml](rotkeeper-bom.html)

## Future Additions

<!-- Aspirational rites for BOM -->
- Support hierarchical BOM includes (e.g., import other BOM files).
- Validate patterns against actual file system entries.
- Generate visual tree diagrams of tomb structure.