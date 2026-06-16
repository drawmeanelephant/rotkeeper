---
title: "🗺️ rc-sitemap.sh Reference"
slug: rc-sitemap
version: "0.3.0.15"
updated: "2026-06-15"
description: "Extract sitemap and navigation info from the most recent render log."
tags:
  - rotkeeper
  - scripts
  - sitemap
  - navigation
asset_meta:
  name: "rc-sitemap.md"
  version: "0.3.0.15"
  author: "Rotkeeper Ritual Council"
---

# `rc-sitemap.sh`

**Script Path:** `bones/scripts/rc-sitemap.sh`

**Purpose:** Extracts sitemap and navigation information by parsing the output from the most recent rendering pass. It helps track and organize the overall structure of the generated HTML pages.

## Usage
Through the Rotkeeper dispatcher:
```bash
./rotkeeper.sh sitemap
```

Directly:
```bash
./bones/scripts/rc-sitemap.sh
```

## Details
The script scans the rendering logs and writes structural index files to map the markdown equivalents against their rendered HTML paths.
