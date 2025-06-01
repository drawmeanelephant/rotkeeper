---
title: "Home Directory"
slug: home-folder
template: rotkeeper-doc.html
version: "0.2.3-pre"
updated: "2025-06-01"
description: "Documentation for the user-controlled 'home/' directory in Rotkeeper. Explains structure, ownership, and managed behaviors."
tags:
  - rotkeeper
  - home
  - filesystem
  - docs
asset_meta:
  name: "home-index.md"
  version: "0.2.3-pre"
  author: "Filed Systems"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# 🏡 Home Folder

This is the root of user-controlled data within Rotkeeper. It contains editable tomb content, static assets, and generated reference pages.

It is organized for clarity, modifiability, and clean separation from system scripts.

## 🧭 Structure

```
home/
├── assets/       ← images, styles, downloaded remotes
├── content/      ← markdown docs, tomb files, static pages
└── docs/         ← script-generated reference pages
```

## 🔧 Managed By

These scripts reference or write into `home/`:

- `rc-render.sh` → reads from `home/content/docs/`, outputs to `output/`
- `rc-assets.sh` → scans rendered HTML and pulls from `home/assets/`
- `rc-api.sh` → downloads into `home/assets/remote/`
- `rc-docbook.sh` → emits script docs into `home/docs/`

## ⚖️ Notes

- You are encouraged to version control most of this folder — except:
  - `assets/remote/` (git-ignored)
  - anything manually test-generated

- The entire folder is user-owned and not overwritten by updates unless you allow it.

## 🧾 Related Pages

- [`rc-render.sh`](../bones/scripts/rc-render)
- [`rc-assets.sh`](../bones/scripts/rc-assets)
- [`remote-assets`](./assets/remote)
- [`script-docs`](./docs)