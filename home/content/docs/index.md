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
  license: "All Rights Reserved"
---

# 📖 Rotkeeper Documentation Index

Welcome to Rotkeeper, the command-line necropolis for static site decay rituals.

This suite of shell scripts helps you manage dead markdown, render tombs as HTML, and archive your rot with dignity.
Whether you're new to file decay or just looking to automate your afterlife pipeline, you're in the right place.

The current workflow is deliberately small and local-first:

- **Render** – Convert Markdown into static HTML tombs
- **Assets** – Copy local CSS, fonts, images, and JavaScript into `output/assets/`
- **DIP** – Audit and stitch documentation from the current source tree
- **Scan** – Detect manifest drift and orphaned files
- **Test** – Run the integration and release assertions

> 🕯️ Every file dies. Not every file decays with style.

***

## 📁 Contents

### 1. 🔍 Overview & Lore
- [What is Rotkeeper?](rotkeeper.html)
- [Architecture & Philosophy](architecture.html)
- [Onboarding](onboarding.html)
- [Road to Bones](road-to-bones/index.html)

### 2. 🚀 Getting Started
- [Initializing the Environment](bones/scripts/rc-init.html)
- [First Page](../my-first-page.html)

### 3. ⚙️ CLI Ritual Scripts
- [Scripts Index](bones/scripts/index.html)
- [`rc-init.sh`](bones/scripts/rc-init.html)
- [`rc-book.sh`](bones/scripts/rc-book.html)
- [`rc-render.sh`](bones/scripts/rc-render.html)
- [`rc-pack.sh`](bones/scripts/rc-pack.html)
- [`rc-scan.sh`](bones/scripts/rc-scan.html)
- [`rc-assets.sh`](bones/scripts/rc-assets.html)
- [`rc-status.sh`](bones/scripts/rc-status.html)
- [`rc-glue.sh`](bones/scripts/rc-glue.html)
- [`rc-links.sh`](bones/scripts/rc-links.html)
- [`rc-autopsy.sh`](bones/scripts/rc-autopsy.html)
- [`rc-showcase.sh`](bones/scripts/rc-showcase.html)
- [`rc-bump.sh`](bones/scripts/rc-bump.html)
- [`rc-release.sh`](bones/scripts/rc-release.html)

### 4. 🔧 Configuration & Templates
- [`rotkeeper.yaml`](bones/config/rotkeeper.html)
- [Schemas: asset-manifest, rotkeeper.yaml, release-manifest](rotkeeper-schemas.html)
- [Template Expectations](bones/templates/index.html)
- [DIP Matrix](dip-matrix.html)

### 5. 🪵 Logs, Echoes & Reports
- [Archive Reports](bones/archive/index.html)
- [DIP Matrix](dip-matrix.html)

### 6. 🌀 Advanced Flags & Edge Cases
- [Rotkeeper Reference](rotkeeper-reference.html)
- [Rotkeeper Rituals](rotkeeper-rituals.html)
- [Writing a New Rotkeeper Ritual](new-ritual.html)
- [Pre-commit Notes](pre-commit.html)

### 7. 🧯 Ritual Interruptions
- [Patch Notes](patch.html)
- [Setup](scripts/setup.html)

### ✒️ Textile Content
- [Textile Formatting Guide](textile-guide.html)
- [Textile Showcase](textile-showcase.html)

### 🍲 Recipe Grimoire
- [Recipes](../recipes/index.html) — the dead eat well; sources are `.cook` (Cooklang)

### 8. 📎 Appendix
- [Bones Index](bones/index.html)
- [Configuration Index](bones/config/index.html)
- [Templates Index](bones/templates/index.html)

***

**Start with**: [Onboarding](onboarding.html) or jump straight to [rc-render.sh](bones/scripts/rc-render.html)

**Back to the project**: [README](README.html)

<!--
Sora prompt: “A glitching wiki carved into obsidian, with glowing CLI runes etched in rust.”
-->
<!-- ROTKEEPER-GLUE-START -->
- [.github/](<.github/index.html>)
- [bones/](<bones/index.html>)
- [road-to-bones/](<road-to-bones/index.html>)
- [scripts/](<scripts/index.html>)
- [.agentignore](<.agentignore.html>)
- [.blessed](<.blessed.html>)
- [.gitignore](<.gitignore.html>)
- [.shellcheckrc](<.shellcheckrc.html>)
- [AGENTS](<AGENTS.html>)
- [CHANGELOG](<CHANGELOG.html>)
- [CONTRIBUTING](<CONTRIBUTING.html>)
- [CREDITS](<CREDITS.html>)
- [GEMINI](<GEMINI.html>)
- [README](<README.html>)
- [architecture](<architecture.html>)
- [dip-matrix](<dip-matrix.html>)
- [new-ritual](<new-ritual.html>)
- [oliver-contract](<oliver-contract.html>)
- [onboarding](<onboarding.html>)
- [patch](<patch.html>)
- [pre-commit](<pre-commit.html>)
- [rotkeeper-reference](<rotkeeper-reference.html>)
- [rotkeeper-rituals](<rotkeeper-rituals.html>)
- [rotkeeper-schemas](<rotkeeper-schemas.html>)
- [rotkeeper](<rotkeeper.html>)
- [textile-guide](<textile-guide.html>)
- [textile-showcase](<textile-showcase.html>)
- [workflow](<workflow.html>)
<!-- ROTKEEPER-GLUE-END -->
