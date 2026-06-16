---
title: "Ritual Scripts"
slug: scripts-index
version: "0.2.3-pre"
updated: "2025-06-01"
description: "Directory index for all rc-*.sh scripts used in Rotkeeper. Includes manual tools, render helpers, and archival commands."
tags:
  - rotkeeper
  - scripts
  - cli
  - reference
asset_meta:
  name: "scripts-index.md"
  version: "0.2.3-pre"
  author: "Filed Systems"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# 📖 Rotkeeper Documentation Index

Welcome to Rotkeeper, the command-line necropolis for static site decay rituals.

This suite of shell scripts helps you manage dead markdown, render tombs as HTML, and archive your rot with dignity.
Whether you're new to file decay or just looking to automate your afterlife pipeline, you're in the right place.

Ritual types include:

- **Expand** – Generate Markdown stubs and configs
- **Render** – Convert Markdown into static HTML tombs
- **Scan** – Detect decay, missing metadata, or corruption
- **Pack** – Archive a versioned tomb for long-term storage
- **Record** – Commit the state of a ritual into Git & logs

> 🕯️ Every file dies. Not every file decays with style.

***

## 📁 Contents

### 1. 🔍 Overview & Lore
- [What is Rotkeeper?](rotkeeper.md)
- [Architecture & Philosophy](architecture.md)
- [Workflow Summary](technology/quickstart-guide.md)

### 2. 🚀 Getting Started
- [Installation Requirements](install)
- [Initializing the Environment](bones/scripts/rc-init.md)

### 3. ⚙️ CLI Ritual Scripts
- [`rc-init.sh`](bones/scripts/rc-init.md)
- [`rc-expand.sh`](bones/scripts/rc-expand.md)
- [`rc-render.sh`](bones/scripts/rc-render.md)
- [`rc-pack.sh`](bones/scripts/rc-pack.md)
- [`rc-scan.sh`](bones/scripts/rc-scan.md)
- [`rc-assets.sh`](bones/scripts/rc-assets.md)
- [`rc-status.sh`](bones/scripts/rc-status.md)
- [`rc-reseed.sh`](bones/scripts/rc-reseed.md)
- [`rc-glue.sh`](bones/scripts/rc-glue.md)
- [`rc-ingest.sh`](bones/scripts/rc-ingest.md)
- [`rc-bump.sh`](bones/scripts/rc-bump.md)
- [`rc-release.sh`](bones/scripts/rc-release.md)

### 4. 🔧 Configuration
- [`rotkeeper-bom.yaml`](bones/config/rotkeeper-bom.md)
- [Template Expectations](bones/templates/index.md)

### 5. 🪵 Logs, Echoes & Reports
- [Log Outputs](bones/logs/index.md)
- [Archive Reports](bones/archive/index.md)

### 6. 🌀 Advanced Flags & Edge Cases
- [`--dry-run`, `--verbose`](bones/flags.md)
- [Reseed Directory Structure](bones/reseed.md)
- [JSON Output & Metadata](bones/export.md)

### 7. 🧯 Ritual Interruptions
- [Common Errors](help/errors.md)
- [Dependency Checklist](technology/dependencies.md)

### 8. 📎 Appendix
- [Full File Tree](bones/appendix/tree.md)
- [CLI Help Reference](rotkeeper.md)
- [Manifest / Asset Format Examples](bones/appendix/formats.md)

***

**Start with**: [Getting Started](bones/install.md) or jump straight to [rc-render.sh](bones/scripts/rc-render.md)

<!--
Sora prompt: “A glitching wiki carved into obsidian, with glowing CLI runes etched in rust.”
-->