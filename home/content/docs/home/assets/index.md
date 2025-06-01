---
title: "Assets"
slug: assets
template: rotkeeper-doc.html
version: "0.2.3-pre"
updated: "2025-06-01"
description: "Describes the local assets directory used during rendering and archiving, including CSS, images, and remote fetches."
tags:
  - rotkeeper
  - assets
  - rendering
  - static
  - css
asset_meta:
  name: "assets.md"
  version: "0.2.3-pre"
  author: "Filed Systems"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# 📦 Local Assets

This directory contains any static files used in the rendering of tomb pages.

These may include:
- CSS files (e.g. `hiq.css`, `rotkeeper.css`)
- Images used in Markdown (referenced as `/assets/images/...`)
- Static icons, JavaScript, or fonts

## 🧩 Folder Layout

```
home/assets/
├── css/
├── images/
└── remote/         ← files fetched by `rc-api.sh`
```

Files within `home/assets/` may be selectively copied into `output/assets/` during rendering, based on actual references found in HTML.

## 🔄 Workflow Integration

- `rc-assets.sh`: scans HTML output for asset links and builds a manifest
- `rc-verify.sh`: checks presence and integrity of each asset listed
- `rc-pack.sh`: can archive these assets into tomb bundles

## 🚫 Git Policy

Most files in this directory **can be committed** if they are part of your tomb.

The exception is:
- `home/assets/remote/` — which is reserved for dynamically fetched, git-ignored files

## 🔗 Related Pages

- [`rc-assets.sh`](../../bones/scripts/rc-assets)
- [`rc-verify.sh`](../../bones/scripts/rc-verify)
- [`remote-assets`](./remote)
