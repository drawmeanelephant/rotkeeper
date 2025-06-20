---
title: "Script Docs"
slug: script-docs
template: rotkeeper-doc.html
version: "0.2.3-pre"
updated: "2025-06-01"
description: "Generated reference pages for all rc-*.sh scripts in the Rotkeeper system. Created by rc-docbook.sh and not edited manually."
tags:
  - rotkeeper
  - scripts
  - docs
  - generated
asset_meta:
  name: "script-docs.md"
  version: "0.2.3-pre"
  author: "Filed Systems"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# 📜 Script Documentation (Generated)

This directory contains reference pages for each of the `rc-*.sh` scripts included in the Rotkeeper system. These are **not handwritten** — they are automatically generated from the script source code.

## 📥 Source

The reference docs are produced by:

```bash
./bones/scripts/rc-docbook.sh
```

It parses comments from the top of each script and emits Markdown pages into this folder.

## 🧩 Purpose

- Provide quick reference for each script
- Surface usage patterns, flags, and notes
- Enable searchable, rendered docs for offline use

## 🔄 Workflow

This folder is not required for render or audit processes. It is optional and may be regenerated at any time.

- You may delete this folder without harming your tombs
- You may run `rc-docbook.sh` after changes to any script
- These pages are not typically edited by hand

## 🔧 Git Policy

This folder is typically **not git-ignored**, but changes here should only be committed if useful to the project state.

## 🔗 Related

- [`rc-docbook.sh`](../../bones/scripts/rc-docbook) — generates these pages
- [`rc-assets.sh`](../../bones/scripts/rc-assets) — includes docs in manifests (if present)