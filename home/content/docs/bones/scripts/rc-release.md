---
title: "📦 rc-release.sh Reference"
slug: rc-release
version: "0.3.0"
updated: "2026-06-15"
description: "Packages the project into one canonical distribution zip file."
tags:
  - rotkeeper
  - scripts
  - packaging
  - distribution
asset_meta:
  name: "rc-release.md"
  version: "v0.3.0"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "All Rights Reserved"
---

<!--
🎨 Sora Prompt:
"A conveyor belt in a dark factory dropping one heavy, perfectly sealed metal lockbox into a bottomless pit, stamped with a single canonical version."
-->

# 📦 rc-release.sh

<!-- The rite of distribution -->
**Script Path:** `bones/scripts/rc-release.sh`

## Purpose
- Prepares the Rotkeeper framework for distribution to other users or subagents.
- Generates one canonical distribution archive.
- The archive contains the working framework while excluding temporary outputs, reports, logs, archives, messages, and `.git`.

## CLI Interface
```bash
./rotkeeper.sh release
```

## Workflow Steps
1. **Version Detection**
   - Extracts the current system version from `rotkeeper.sh`.
2. **Staging**
   - Creates a temporary staging directory in the configured temporary area.
3. **Copying**
   - Uses `rsync` to mirror the repository into the staging directories while excluding volatile folders like `.git/`, `output/`, and `bones/logs/`.
4. **Compression**
   - Writes `bones/archive/releases/rotkeeper-[version].zip`.
   - Replaces any existing archive at that exact destination.
5. **Cleanup**
   - Prunes the temporary staging files.

## 🛣️ Navigation
- [Scripts Index](index.html)
- [Bones Home](../index.html)

<!--
Limerick:
The archives were growing too fat,
So one canonical coffin was sat.
The volatile dead,
Were left out instead,
And one versioned zip left the flat.
-->

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-07-23T10:54:47Z -->


### Bones of the Code
The merchant of death, packaging distribution zip files for the masses. It uses exclusion lists to decide what gets left behind in the crypt.

### Restless Spirits
The exclusion lists are a brittle defense. If a sensitive file gets created that doesn't match the hardcoded patterns, it will be happily zipped up and shipped to production. Its assumptions about the target environments are equally perilous.

### Ritual Warnings
Audit the exclusion lists regularly. Never assume that 'lite' means 'safe'—sensitive data will slip through if you aren't paying attention.
## Ritual History
<!-- DIP-HISTORY-EXTRACTED: 2026-07-23T10:54:47Z -->

*Not found: no changelog/history entries matching `rc-release.sh`.*
## Environment
<!-- DIP-ENV-EXTRACTED: 2026-08-12T00:38:36Z -->

- **$ROOT_DIR**: .
- **$OUTPUT_DIR**: output
- **$CONTENT_DIR**: home/content
- **$ASSETS_DIR**: home/assets
- **$DOCS_DIR**: home/content/docs
- **$HELP_DIR**: home/content/help
- **$BONES_DIR**: bones
- **$SCRIPT_DIR**: bones/scripts
- **$CONFIG_DIR**: bones/config
- **$LOG_DIR**: bones/logs
- **$TMP_DIR**: bones/tmp
- **$ARCHIVE_DIR**: bones/archive
- **$REPORT_DIR**: bones/reports
- **$BOOK_REPORT_DIR**: bones/book-reports
- **$TEMPLATE_DIR**: bones/templates
- **$META_DIR**: bones/meta
- **$WEB_DIR**: output
###### CLI Usage
<!-- DIP-HELP-EXTRACTED: 2026-08-15T15:43:55Z -->

*Not found: autopsy help report missing (`bones/reports/autopsy-help.md`). Run: ./rotkeeper.sh autopsy --help-report*
