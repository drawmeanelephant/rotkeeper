---
title: "📦 rc-pack.sh Reference"
slug: rc-pack
version: "v0.2.3-pre"
updated: "2025-06-01"
description: "Creates a tar.gz tomb archive from the rendered directory and embeds tomb metadata into the archive."
tags:
  - rotkeeper
  - scripts
  - packing
  - tombs
asset_meta:
  name: "rc-pack.md"
  version: "v0.2.3-pre"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "All Rights Reserved"
---

<!-- Begin Ritual Script Documentation -->

# 🪦 rc-pack.sh

<!-- The sacred rite of tomb sealing and export -->

**Script Path:** `bones/scripts/rc-pack.sh`

## Purpose
<!-- Core objectives of rc-pack.sh -->
- Bundle the `output/` directory into a timestamped `.tar.gz` archive and log it in `bones/manifest.txt`.
- Export all Markdown under `home/content/` into a single JSON file for AI consumption and external indexing.
- Embed archive metadata (`metadata.json`) directly into each tomb before compression for self-validation and ritual completeness.

## CLI Interface
<!-- How to invoke the packing ceremony -->
```bash
rc-pack.sh [--dry-run] [--verbose] [--self] [--json-only] [--help]
```

Supported options:
- `--help`, `-h`
  Show usage information and exit.
- `--dry-run`, `-n`
  Preview actions without writing files.
- `--verbose`, `-v`
  Show detailed logs.
- `--self`
  Include the entire Rotkeeper project in the archive.
  Includes the entire Rotkeeper repo, including scripts, configs, and source docs.
- `--json-only`
  Export Markdown to JSON only, skip tarball.

Workflow Steps

<!-- Sequential rites performed by the script -->

	1.	Verify Dependencies
	•	Check for tar and jq.
	2.	Archive Output
	•	Create bones/archive/tomb-YYYY-MM-DD_HHMM.tar.gz from output/ (excluding backups if --self).
	2.5. Embed Metadata
	•  Inject a generated `metadata.json` file into each `.tar` archive before compression. This includes name, SHA256 checksum, timestamp, archive mode, and file count.
	3.	Export Markdown
	•	Export Markdown files under `home/content/` into `tomb-export-*.json` using `jq --rawfile` to supply an explicit `source_markdown` field contract.
	4.	Log Operation
	•	Write bones/manifest.txt and bones/logs/rc-pack-YYYYMMDD-HHMMSS.log.

Exit Codes

<!-- Symbolic outcomes of incantation -->


	•	0 — Archive and export completed successfully.
	•	1 — Missing dependencies or I/O errors.
	•	2 — No files found to process.

Examples

<!-- Sample invocations for celebratory rites -->

```bash
# Standard pack
./bones/scripts/rc-pack.sh
# → Creates: bones/archive/tomb-YYYY-MM-DD_HHMM.tar.gz

# Include full project in archive
./bones/scripts/rc-pack.sh --self

# JSON export only
./bones/scripts/rc-pack.sh --json-only

# Preview actions
./bones/scripts/rc-pack.sh --dry-run --verbose

# Show help
./bones/scripts/rc-pack.sh --help

# Embed metadata in default pack (done automatically)
./bones/scripts/rc-pack.sh
```

🛣️ Navigation

<!-- Quick navigation links -->


	•	Scripts Index
	•	Pack Reference
	•	Bones Home

<!--
Limerick 1:
In cryptic halls, the tombs were bound,
rc-pack wrapped each sacred mound.
With JSON in hand,
And tarball at command,
The archive was sealed and crowned.

Limerick 2:
Across dusty files where Markdown lay,
rc-pack called forth their text array.
It bundled and scribed,
Then logged what survived,
Ensuring no relic would stray.
-->
## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-07-04T15:41:00Z -->


### Bones of the Code
The embalmer. It wraps the project's remains in a tarball and shoves JSON metadata in alongside it, hoping the next entity to find it can make sense of the mess.

### Restless Spirits
Its absolute reliance on `jq` means that without it, the metadata creation process crashes and burns. Furthermore, the formatting of the JSON metadata is prone to breaking if shell variables contain unescaped quotes or newlines.

### Ritual Warnings
Ensure `jq` is installed and functioning. Beware of injecting raw, unescaped text into the JSON metadata fields.
## Ritual History
<!-- DIP-HISTORY-EXTRACTED: 2026-08-12T00:38:36Z -->

- - Formalized `source_markdown` export contract in `rc-pack.sh` for decentralized payload packaging.
- - Update rc-pack.sh to include all config variations.
- - Enhance rc-pack.sh compression algorithm for smaller tarballs.
- - Update rc-pack.sh to handle content flag natively.
- `CHANGELOG.md` records parallel `rc-render.sh` processing, smaller `rc-pack.sh`
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
<!-- DIP-HELP-EXTRACTED: 2026-08-12T12:26:46Z -->

```text
rc-pack.sh — Ritual Compression Packager (v0.5.1)

Usage: rc-pack.sh [options]

Options:
  --version, -v    Show script version and quit
  --help, -h       Show this help message and exit
  --dry-run        Preview actions without writing files
  --self           Archive the full Rotkeeper system (rotkeeper.sh, bones/, home/, output/)
  --content        Archive only the home/content directory to preserve source files
  --verbose        Enable detailed debug logging
```
