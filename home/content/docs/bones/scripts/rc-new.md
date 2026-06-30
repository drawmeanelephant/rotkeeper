---
title: "✨ rc-new.sh Reference"
slug: rc-new
version: "0.3.0.15"
updated: "2026-06-15"
description: "Scaffold a new markdown file with YAML frontmatter."
tags:
  - rotkeeper
  - scripts
  - scaffold
  - content
asset_meta:
  name: "rc-new.md"
  version: "0.3.0.15"
  author: "Rotkeeper Ritual Council"
---

# `rc-new.sh`

**Script Path:** `bones/scripts/rc-new.sh`

**Purpose:** Rapidly scaffold a new markdown file within `home/content/` (or its subdirectories) with the appropriate Rotkeeper YAML frontmatter.

## Usage
Through the Rotkeeper dispatcher:
```bash
./rotkeeper.sh new path/to/my-page.md
```

Directly:
```bash
./bones/scripts/rc-new.sh path/to/my-page.md
```

## Details
The script automatically generates proper frontmatter keys (`title`, `slug`, `template`, `version`, `updated`, etc.) so the page is immediately ready for Pandoc rendering.

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-06-30T17:53:41Z -->


### Bones of the Code
A glorified form filler that generates new markdown 'tombs' and slaps YAML frontmatter on them. It takes user input and attempts to coerce it into a valid filename.

### Restless Spirits
It is hopelessly naive about character escaping. Feed it a title with quotes, colons, or other exotic characters, and watch it generate malformed frontmatter and unreadable filenames. It's a breeding ground for syntax errors.

### Ritual Warnings
Stick to alphanumeric titles unless you enjoy manually untangling broken YAML and shell-escaped horrors.
