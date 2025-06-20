---
title: "rc-unpack.sh"
slug: rc-unpack
template: rotkeeper-doc.html
subtitle: "Unpack tomb archives and restore site state"
version: "v0.2.3-pre"
updated: "2025-06-01"
description: "Planned script for restoring rendered output or JSON from a .tar.gz tomb archive generated by rc-pack.sh."
tags:
  - rotkeeper
  - scripts
  - restore
  - tombs
  - unpack
  - archive
asset_meta:
  name: "rc-unpack.md"
  version: "v0.2.3-pre"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# 🪦 `rc-unpack.sh`

`rc-unpack.sh` is a planned restoration script that will reverse the effects of `rc-pack.sh`. It will extract archived tombs and restore either the rendered HTML (`/output/`) or exported JSON data for rehydration or inspection.

> **Status:** This script is **not yet implemented**. It is reserved for future versions of Rotkeeper.

---

## 📂 What It Will Do

When passed a `.tar.gz` archive from `rc-pack.sh`, this script will:

- Extract `/output/` contents into your local project folder
- Optionally restore logs, templates, or JSON exports
- Log its actions to `bones/logs/rc-unpack-*.log`
- Refuse to overwrite existing files unless `--force` is passed

---

## 🧬 Planned JSON Support

Rotkeeper may also support direct restoration from exported JSON files:

```plaintext
bones/archive/tomb-export-YYYY-MM-DD_HHMM.json
```

This would allow:

- Rebuilding `.md` files into `home/content/`
- Inspecting or transforming JSON records without running Pandoc

---

## 🛠 Planned Usage

```bash
bash bones/scripts/rc-unpack.sh bones/archive/tomb-2025-05-27_1113.tar.gz
```

Optional flags may include:

- `--to output/` — Target unpack destination
- `--json` — Input is a JSON file, not a `.tar.gz`
- `--dry-run` — Show changes without writing files
- `--force` — Allow overwriting existing output

---

## 🔐 Safety Features

- Prompts before overwriting `output/` or logs
- Logs all restored files to `bones/manifest.txt` and `bones/logs/`
- May use SHA256 or tomb signature to confirm archive lineage

---

## 📌 Related Files & Scripts

- [`rc-pack.sh`](rc-pack.md) — Entombs the site
- [`rc-reseed.sh`](rc-reseed.md) — Rehydrates full tombs from archive
- `bones/archive/` — Default folder for `.tar.gz` and JSON outputs
- `bones/logs/` — Where `rc-unpack` logs will go when implemented

---

<!--
A tomb once was zipped up so tight,
But rotkeeper brought it to light.
With a single unpack,
The ghosts all came back—
And output was soon back in sight.
-->
