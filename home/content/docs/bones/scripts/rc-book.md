---
title: "rc-book — binder ritual for compiling and collapsing Rotkeeper books"
slug: rc-book
template: rotkeeper-doc.html
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

`rc-book.sh` is the singular binder ritual for Rotkeeper. It replaces `rc-scriptbook.sh`, `rc-docbook.sh`, and `rc-webbook.sh`, providing a unified interface for compiling or collapsing documentation into canonical reports.

## 🧰 Usage

```bash
./bones/scripts/rc-book.sh [--scriptbook|--docbook|--webbook|--all|--collapse] [--config FILE]
```

## 🧾 Flags

- `--scriptbook` — Extract script comments into `rotkeeper-manual.md`
- `--docbook` — Gather documentation into `rotkeeper-docbook.md`
- `--webbook` — Bind public content into `rotkeeper-webbook.md`
- `--all` — Run all three rituals (scriptbook, docbook, webbook)
- `--collapse` — Convert markdown reports into `collapsed-content.yaml`, with fallback title support
- `--config FILE` — Optional config for future inclusion/exclusion logic
- `--help` — Show help text

## 📦 Outputs

Each mode writes to `bones/reports/`:

- `rotkeeper-scriptbook.md`
- `rotkeeper-docbook.md`
- `rotkeeper-webbook.md`
- `rotkeeper-docbook-clean.md` (frontmatter-stripped, collapse-friendly)

## 🔮 Future Work

- `--collapse` will eventually reverse `.md` output into `rotkeeper-bom.yaml`
- Support for `book-config.yaml` is planned to guide filtering and section control