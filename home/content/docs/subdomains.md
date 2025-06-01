---
title: "🌐 Rotkeeper Subdomains"
slug: subdomains
template: rotkeeper-doc.html
version: "0.2.3-pre"
updated: "2025-06-01"
description: "Lists and explains the various functional subdomains of the Rotkeeper project, including content, config, and rendering layers."
tags:
  - rotkeeper
  - structure
  - domains
  - architecture
asset_meta:
  name: "subdomains.md"
  version: "0.2.3-pre"
  author: "Filed Systems"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# 📖 Rotkeeper Documentation Index

This is the internal documentation hub for all Rotkeeper rituals, scripts, formats, and failures. Start here if you’re already entombed in the CLI.

***

## 📁 Contents

### 1. 🔍 Overview & Lore
- [What is Rotkeeper?](rotkeeper.md)
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
- [`rc-bless.sh`](bones/scripts/rc-bless.md)
- [`rc-assets.sh`](bones/scripts/rc-assets.md)
- [`rc-record.sh`](bones/scripts/rc-record.md)
- [`rc-status.sh`](bones/scripts/rc-status.md)
- [`rc-reseed.sh`](bones/scripts/rc-reseed.md)

### 4. 🔧 Configuration
- [`render-flags.yaml`](bones/config/render-flags.md)
- [`rotkeeper-bom.yaml`](bones/config/rotkeeper-bom.md)
- [Template Expectations](bones/templates/index.md)

### 5. 🪵 Logs, Echoes & Reports
- [Log Outputs](bones/logs/index.md)
- [Bless Logs & Changelogs](bones/logs/changelog.md)
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

🕯️ **First time decaying?** Begin with the [Quickstart Guide](technology/quickstart-guide.md)
⚙️ **Returning cryptkeeper?** Jump to [rc-render.sh](bones/scripts/rc-render.md)

<!--
Sora prompt: “A glitching wiki carved into obsidian, with glowing CLI runes etched in rust.”
-->