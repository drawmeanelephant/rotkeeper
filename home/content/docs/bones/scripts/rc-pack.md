---
title: "🪦 rc-pack.sh Reference"
slug: rc-pack
template: rotkeeper-doc.html
version: "0.2.1"
updated: "2025-05-29"
---

<!-- Begin Ritual Script Documentation -->

# 🪦 rc-pack.sh

<!-- The sacred rite of tomb sealing and export -->

**Script Path:** `bones/scripts/rc-pack.sh`

## Purpose
<!-- Core objectives of rc-pack.sh -->
- Bundle the `output/` directory into a timestamped `.tar.gz` archive and log it in `bones/manifest.txt`.
- Export all Markdown under `home/content/` into a single JSON file for AI consumption and external indexing.

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
- `--json-only`
  Export Markdown to JSON only, skip tarball.

Workflow Steps

<!-- Sequential rites performed by the script -->

	1.	Verify Dependencies
	•	Check for tar, jq, and pandoc.
	2.	Archive Output
	•	Create bones/archive/tomb-YYYY-MM-DD_HHMM.tar.gz from output/ (excluding backups if --self).
	3.	Export Markdown
	•	Use pandoc to convert .md files under home/content/ into JSON.
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

# Include full project in archive
./bones/scripts/rc-pack.sh --self

# JSON export only
./bones/scripts/rc-pack.sh --json-only

# Preview actions
./bones/scripts/rc-pack.sh --dry-run --verbose

# Show help
./bones/scripts/rc-pack.sh --help
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