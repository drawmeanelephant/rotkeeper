---
title: "♻️ rc-reseed.sh Reference"
slug: rc-reseed
version: "v0.2.3-pre"
updated: "2025-06-01"
description: "Rebuilds a full Rotkeeper project structure from markdown ritual books or archive tombs using rc-reseed.sh."
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


---

## 🧠 Purpose

`rc-reseed.sh` is a resurrection utility that reconstructs a full Rotkeeper project structure.

It can:
- Unpack a `.tar.gz` tomb archive (legacy mode)
- Rehydrate scripts, docs, and configs from structured markdown binders created by `rc-book.sh`

This script is the inverse ritual of `rc-book.sh`, enabling round-trip rebuilds from curated documentation.

---

## 🌀 Usage

```bash
# Full reseed from all binders
./scripts/rc-reseed.sh --all

# Restore from a specific binder file
./scripts/rc-reseed.sh --input rotkeeper-docbook.md

# Dry run
./scripts/rc-reseed.sh --input rotkeeper-configbook.md --dry-run
```

---

## ⚙️ Flags

| Flag           | Description                                                                 |
|----------------|-----------------------------------------------------------------------------|
| `--all`        | Rehydrate from all known binders (`scriptbook-full`, `docbook`, `configbook`) |
| `--input FILE` | Restore from a specific markdown binder                                      |
| `--dry-run`    | Preview actions without writing files                                       |
| `--help`, `-h` | Show usage information and exit                                             |

---

## 📦 Example

```bash
# Restore the full site structure from binder books
./scripts/rc-reseed.sh --all

# Dry run on a specific binder
./scripts/rc-reseed.sh --input rotkeeper-configbook.md --dry-run
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

<!-- 🎴 Reseed Ritual:
From scriptbook to script, from docbook to prose,
From config to template the resurrection flows.
No database. No runtime.
Just bones. Just bash. Just right.
-->
## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-06-29T21:12:31Z -->


### Bones of the Code
A necromantic resurrection spell that attempts to reconstruct source files from a compiled binder. It tears a single file apart and scatters the pieces back into the directory structure.

### Restless Spirits
The regex used to split the binder is a ticking time bomb. If the source material coincidentally contains the delimiter pattern, the script will violently shred the file at the wrong seams, leaving you with mangled, corrupted code.

### Ritual Warnings
Pray that your code never resembles the delimiter. The reconstruction process is only as reliable as the uniqueness of its markers.
