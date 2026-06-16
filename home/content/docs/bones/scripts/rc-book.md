---
title: "rc-book — binder ritual for compiling and collapsing Rotkeeper books"
slug: rc-book
status: stable
version: "v0.2.5"
updated: 2025-06-03
description: "Centralizes all documentation binding; compiles or collapses Rotkeeper books from markdown and script rituals."
tags:
  - rotkeeper
  - scripts
  - docs
  - binders
asset_meta:
  name: "rc-book.md"
  version: "v0.2.5"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

`rc-book.sh` is the singular binder ritual for Rotkeeper. It replaces all prior book scripts (`rc-scriptbook.sh`, `rc-docbook.sh`, `rc-configbook.sh`) and now produces canonical markdown reports for resurrection, rendering, or collapse.

It supports generation of scriptbooks, docbooks (clean and full), and configbooks, and can output a collapsed YAML form of all content.

## 🧰 Usage

```bash
./bones/scripts/rc-book.sh [--scriptbook-full|--docbook|--docbook-clean|--configbook|--collapse|--all] [--dry-run]
```

## 🧾 Flags

- `--scriptbook-full` — Bind full scripts into `rotkeeper-scriptbook-full.md`
- `--docbook` — Bind all site documentation into `rotkeeper-docbook.md`
- `--docbook-clean` — Same as docbook but with stripped frontmatter (for collapse)
- `--configbook` — Bind configuration and template files into `rotkeeper-configbook.md`
- `--collapse` — Output all binders into a single collapsed YAML file
- `--all` — Run all binder modes (scriptbook, docbook, docbook-clean, configbook)
- `--dry-run` — Print what would be generated without writing files
- `--help` — Show help text

## 📦 Outputs

All binders are written to `bones/reports/`:

- `rotkeeper-scriptbook-full.md`
- `rotkeeper-docbook.md`
- `rotkeeper-docbook-clean.md`
- `rotkeeper-configbook.md`
- `collapsed-content.yaml`

## 🔮 Future Work

- Support for `book-config.yaml` to define inclusion/exclusion
- Better collapse metadata (e.g., tags, titles, sections)
- Potential for binder diffing or validation modes