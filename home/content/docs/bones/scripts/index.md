---
title: "📜 Ritual Scripts Index"
slug: scripts-index
version: "0.1.0"
updated: "2026-06-27"
description: "Reference guide for all executable CLI commands and Lua filters in the scripts folder."
template: "rotkeeper-doc.html"
status: "complete"
author: "Rotkeeper DIP"
project: "Rotkeeper"
---

# 📜 Ritual Scripts

This folder contains the core shell scripts that run Rotkeeper's commands.

## Scripts Overview

- **[rc-init.sh](rc-init.html)**: Prepares the directory layouts and template configurations.
- **[rc-render.sh](rc-render.html)**: Invokes Pandoc to compile Markdown files into HTML.
- **[rc-assets.sh](rc-assets.html)**: Scans HTML and generates the SHA256 assets manifest.
- **[rc-scan.sh](rc-scan.html)**: Audits file integrity and metadata drift.
- **[rc-pack.sh](rc-pack.html)**: Packages directories into a compressed archive.
- **[rc-dip.sh](rc-dip.html)**: Runs the Document Improvement Project to build and stitch documentation.
- **[rc-status.sh](rc-status.html)**: Checks system health and version alignment.
- **[rc-showcase.sh](rc-showcase.html)**: Renders templates using standard test pages.
- **[rewrite-links.lua](rewrite-links.html)**: Lua script used by Pandoc to map internal `.md` links to `.html`.

<!-- ROTKEEPER-GLUE-START -->
- [rc-assets](rc-assets.html)
- [rc-autopsy](rc-autopsy.html)
- [rc-book](rc-book.html)
- [rc-bump](rc-bump.html)
- [rc-cleanup-bones](rc-cleanup-bones.html)
- [rc-dip](rc-dip.html)
- [rc-env](rc-env.html)
- [rc-glue](rc-glue.html)
- [rc-ingest](rc-ingest.html)
- [rc-init](rc-init.html)
- [rc-new](rc-new.html)
- [rc-pack](rc-pack.html)
- [rc-release](rc-release.html)
- [rc-render](rc-render.html)
- [rc-reseed](rc-reseed.html)
- [rc-scan](rc-scan.html)
- [rc-showcase](rc-showcase.html)
- [rc-status](rc-status.html)
- [rc-sync-inbox](rc-sync-inbox.html)
- [rc-test](rc-test.html)
- [rc-utils](rc-utils.html)
- [rewrite-links](rewrite-links.html)
<!-- ROTKEEPER-GLUE-END -->
