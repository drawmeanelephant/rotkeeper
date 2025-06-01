---
title: "🧾 render-flags.yaml Reference"
slug: render-flags
template: rotkeeper-doc.html
version: "v0.2.3-pre"
updated: "2025-06-01"
description: "Explanation of all supported flags in render-flags.yaml for Pandoc behavior, output selection, and styling control."
tags:
  - rotkeeper
  - yaml
  - rendering
  - config
asset_meta:
  name: "render-flags.md"
  version: "v0.2.3-pre"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---
<!-- asset-meta:
     name:        "render-flags.yaml"
     version:     "v0.1.0"
     description: "Flags and options for rc-render.sh"
     author:      "Rotkeeper Ritual Council"
-->

# 🚩 render-flags.yaml

<!-- Settings that drive the Pandoc pipeline in rc-render.sh -->

| Flag           | Default      | Description                                    |
|----------------|--------------|------------------------------------------------|
| `template`     | `default.html` | Which HTML template to apply                 |
| `css`          | `styles.css` | Comma-separated list of CSS files to include   |
| `toc`          | `false`      | Generate a table of contents                   |
| `math`         | `true`       | Enable MathJax support                         |
| *…*            | *…*          | *…*                                            |

## 🛠️ Usage

```bash
rc-render.sh --config render-flags.yaml