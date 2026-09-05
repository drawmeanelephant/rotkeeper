---
title: "Welcome to Rotkeeper"
slug: home
version: "0.5.0"
updated: "2026-07-23"
description: "A Bash-native, Oliver-driven static site and content system for Markdown, documentation, and local-first themes."
tags:
  - rotkeeper
  - homepage
  - cli
  - decay
asset_meta:
  name: "index.md"
  version: "0.3.0.4"
  author: "Filed Systems"
  project: "Rotkeeper"
  tracked: true
  license: "All Rights Reserved"
---

# Rotkeeper: A Ritual CLI for Flat-File Decay

Rotkeeper turns Markdown with YAML frontmatter into a static site with Oliver. The system is Bash-native, locally vendored, and organized around three places: `bones/` for the machinery, `home/` for authored content, and `output/` for rendered artifacts.

Each file is a tomb. Each version is a ritual. Each render is final.

***

## 🧪 Run the Pipeline

From the repository root:

```bash
bash rotkeeper.sh init --full
bash rotkeeper.sh render
bash rotkeeper.sh assets
```

Use `render` for HTML, `assets` to copy local CSS/fonts/images/JavaScript into `output/assets/`, and `status` to inspect the current environment.

***

## 🗺️ Index

### 🧾 [Docs](docs/index.html)
> Learn the layout, configuration, ritual scripts, and documentation workflow.

### 🆘 [Help](help/index.html)
> Start with the practical command and workflow notes.

### 🧰 [Rotkeeper Reference](rotkeeper/index.html)
> Read the project reference and current operating notes.

### 🎭 [Showcase](showcase/index.html)
> Compare the available themes, including the persistent Spooky dark and light variants.

### 📝 [First Page](my-first-page.html)
> See the smallest authored content example in the current tree.

## 🦴 Current Rituals

- `bash rotkeeper.sh dip` audits and stitches documentation.
- `bash rotkeeper.sh book --fsbook` builds the filesystem catalog DIP consumes.
- `bash rotkeeper.sh glue` repairs missing content indexes.
- `bash rotkeeper.sh links` audits every local link and asset reference in rendered HTML.
- `bash rotkeeper.sh showcase` generates theme showcase pages.
- `bash rotkeeper.sh autopsy --all` refreshes script help/output reports for DIP.
- `bash rotkeeper.sh scan` checks files against the asset manifest.
- `bash rotkeeper.sh test` runs the integration and release assertions.

The source documentation lives under [`home/content/docs`](docs/index.html). Generated HTML belongs under `output/`; do not edit it directly.

## 🎨 Themes

The default is `theme-spooky-dark.html`, using locally vendored Fira Sans and Fira Code. `theme-spooky-light.html`, `theme-dark.html`, `theme-light.html`, `theme-kawaii.html`, `theme-overgrown.html`, and `theme-phosphor.html` remain available for explicit page frontmatter.

New to the project? Start with the [Docs](docs/index.html). Want to compare layouts? Visit the [Showcase](showcase/index.html).

<!--
Sora prompt: "A decayed tombstone interface for Rotkeeper.com—ghostly monospaced text drifting across a glitching terminal window, rusted metal accents, and flickering OpenMoji icons."
-->
<!-- ROTKEEPER-GLUE-START -->
- [coastal-radio/](<coastal-radio/index.html>)
- [docs/](<docs/index.html>)
- [help/](<help/index.html>)
- [messages/](<messages/index.html>)
- [recipes/](<recipes/index.html>)
- [rotkeeper/](<rotkeeper/index.html>)
- [showcase/](<showcase/index.html>)
- [404](<404.html>)
- [my-first-page](<my-first-page.html>)
<!-- ROTKEEPER-GLUE-END -->
