---
title: "🛤️ Contribution Roadmap"
slug: roadmap-contribution
template: rotkeeper-doc.html
version: "0.2.3-pre"
updated: "2025-06-01"
description: "An open roadmap and contribution guide for future Rotkeeper tasks and feature tracking."
tags:
  - rotkeeper
  - roadmap
  - contribution
  - planning
asset_meta:
  name: "roadmap-contribution.md"
  version: "0.2.3-pre"
  author: "Filed Systems"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# 🛤️ Roadmap & Contribution

Rotkeeper is a modular, undead-friendly project. We welcome contributions from other decaying minds.

## 📅 Roadmap

Core features we’re tracking:

- `rc-pack.sh` → embed full tomb metadata inside `.tar.gz`
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