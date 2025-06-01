---
title: "♻️ rc-reseed.sh Reference"
slug: rc-reseed
template: rotkeeper-doc.html
version: "v0.2.3-pre"
updated: "2025-06-01"
description: "Restores a full Rotkeeper project structure from a packed archive tomb using rc-reseed.sh."
tags:
  - rotkeeper
  - scripts
  - restore
  - tombs
asset_meta:
  name: "rc-reseed.md"
  version: "v0.2.3-pre"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# `rc-reseed.sh`

This script restores a full project directory from a previously packed `.tar.gz` tomb archive. It can be used to repopulate the `home/`, `bones/`, and `output/` structure from a historical version.

---

## 🧠 Purpose

To resurrect an archived site state—useful for regression testing, audits, or timeline divergence. It is the opposite of `rc-pack.sh`.

---

## 🌀 Usage

```bash
./scripts/rc-reseed.sh --archive bones/archive/tomb-0.2.0.tar.gz
```

If no archive is provided, the script may prompt or exit with error.

---

## ⚙️ Flags

| Flag          | Description                                               |
|---------------|-----------------------------------------------------------|
| `--archive`   | Path to `.tar.gz` archive to unpack                       |
| `--dry-run`   | Preview actions without extracting files                  |
| `--verbose`   | Show detailed logs                                        |
| `--help`, `-h`| Show usage information and exit                           |

---

## 📦 Example

```bash
./scripts/rc-reseed.sh --archive bones/archive/tomb-0.1.9.tar.gz
```

<!-- 🎴 Limerick 1:
When old tombs lie silent and cold,
rc-reseed brings life untold.
It unpacks the past,
In memories vast,
And scripts from the archive unfold.
-->

<!-- 🎴 Limerick 2:
Should history’s bones need a spark,
this ritual revives each dark mark.
With tar’s gentle sweep,
It calls from the deep,
And lights up the shadows so stark.
-->