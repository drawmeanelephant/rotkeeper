---
title: "Roadmap & Contribution"
description: "Guide for contributing to Rotkeeper's ritual ecosystem."
version: "0.2.3-pre"
template: rotkeeper-doc.html
updated: "2025-05-31"
---

# 🛤️ Roadmap & Contribution

Rotkeeper is a modular, undead-friendly project. We welcome contributions from other decaying minds.

## 📅 Roadmap

Core features we’re tracking:

- `rc-pack.sh` → embed full tomb metadata inside `.tar.gz`
- `rc-unpack.sh` → verify archive contents & restore to correct path
- `rc-expand.sh` → support multiple tombs per config
- `rc-render.sh` → validate frontmatter, purge bad metadata
- `rc-help.sh` → centralized help dispatcher across scripts
- Obsidian + VSCode integration (`.vscode/tasks.json`, URI schemes)

## 🔧 Contributing

Ways to decay with us:

- Fork the repo and branch from `dev/`
- All scripts must support `--help`, `--dry-run`, and `--debug`
- Maintain the ritual tone in comments and documentation
- Submit PRs with changelog entries under `bones/logs/changelog.md`
- Open issues for broken glyphs, ritual loops, or void regressions

## 🕳️ Long-Term Rites

Dreams for later resurrection:

- A full CLI wizard (`rc-wizard.sh`)
- Ritual test suite using tomb fixtures
- Support for non-markdown decay objects (PDF, plaintext)
- A visual graveyard viewer (html/js front-end)

> 💀 All merges must pass the rotcheck. No exceptions.