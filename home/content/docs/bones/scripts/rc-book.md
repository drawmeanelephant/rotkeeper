---
title: "rc-book — binder ritual for compiling and collapsing Rotkeeper books"
slug: rc-book
template: rotkeeper-doc.html
status: stable
version: "v0.2.3-pre"
updated: 2025-06-01
description: "Compiles documentation and script comments into report books; supports collapse back into structured YAML."
tags:
  - rotkeeper
  - scripts
  - docs
  - binders
asset_meta:
  name: "rc-book.md"
  version: "v0.2.3-pre"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

`rc-book.sh` is the central ritual binder for Rotkeeper. It consolidates multiple documentation and markdown rituals into a single interface, enabling project-wide compilation or collapse.

## 🧰 Usage

```bash
./bones/scripts/rc-book.sh [--scriptbook|--docbook|--webbook|--all|--collapse] [--config FILE]
```

## 🧾 Flags

- `--scriptbook` — Extract script comments into `rotkeeper-manual.md`
- `--docbook` — Gather documentation into `rotkeeper-docbook.md`
- `--webbook` — Bind public content into `rotkeeper-webbook.md`
- `--all` — Run all three rituals (scriptbook, docbook, webbook)
- `--collapse` — (WIP) Convert markdown back into structured YAML
- `--config FILE` — Optional config for future inclusion/exclusion logic
- `--help` — Show help text

## 📦 Outputs

Each mode writes to `bones/reports/`:

- `rotkeeper-scriptbook.md`
- `rotkeeper-docbook.md`
- `rotkeeper-webbook.md`

## 🔮 Future Work

- `--collapse` will eventually reverse `.md` output into `rotkeeper-bom.yaml`
- Support for `book-config.yaml` is planned to guide filtering and section control