---
title: "🔍 rc-scan.sh Reference"
slug: rc-scan
target_file: "bones/scripts/rc-scan.sh"
date: "2026-08-27"
template: "rotkeeper-doc.html"
status: "active"
version: "0.5.1"
author: "Rotkeeper Ritual Council"
project: "Rotkeeper"
description: "Audits the render ledger (bones/manifest.txt) against disk — missing entries, output-tree orphans (assets tree exempt), ledger digests — and emits JSON plus Markdown scan reports."
tags:
  - rotkeeper
  - scripts
  - scan
  - digests
---

# 🔍 rc-scan.sh

<!-- The sacred rite of tomb inspection -->

**Script Path:** `bones/scripts/rc-scan.sh`

## Overview

`rc-scan.sh` is the integrity auditor: it reconciles what the manifest claims exists against what is actually on disk, then files a report of the discrepancies. It runs at the end of `init --full` and can be invoked any time an audit is wanted.

The audit, in order:

1. **Manifest load** — reads `bones/manifest.txt` (blank lines and `#` comments skipped), normalizing each entry to a root-relative path.
2. **Output walk** — scans `OUTPUT_DIR` only, pruning noisy subtrees (`tmp`, `logs`, `archive`, `reports`, `book-reports`) and the assets tree (`output/assets/` — owned by the assets ritual, not the ledger), filtered by extension (default allowlist: `png jpg svg css js md html json yaml`; override with `--include`, tighten further with repeatable `--exclude` glob patterns).
3. **Classification** — *missing* = listed in the ledger but absent on disk; *orphan* = under the output tree but absent from the ledger.
4. **Digests** — SHA256 for every ledger-listed file present on disk (via the portable checksum helper); entries absent from disk are already reported as missing.
5. **Reports** — timestamped JSON (`scan-report-<ts>.json`) and Markdown (`scan-report-<ts>.md`) under `bones/reports/`, each containing the missing list, orphan list, and digest table. `--json-only` / `--md-only` restrict output to one form; `--manifest-only` skips the disk walk entirely. `--json` additionally prints a schema-tagged summary object (`rotkeeper.scan.v1`) on stdout — report files, human output, and exit codes are unchanged.

## CLI Usage

```bash
rotkeeper.sh scan [options]

# Options:
#   --manifest-only   Read only the manifest file, skip the disk scan
#   --include <ext>   Comma-separated extensions to include
#   --exclude <pat>   Glob pattern to exclude (can repeat)
#   --json            Emit machine-readable JSON on stdout (reports unchanged)
#   --json-only       Write only the JSON report
#   --md-only         Write only the Markdown report
#   --dry-run         Show actions without writing reports or logs
#   --verbose         Print detailed logs
#   --help, -h        Show usage help
```

### Environment assumptions

- **Reads:** `bones/manifest.txt` (the render ledger — not the asset manifest), plus `CONTENT_DIR`, `BONES_DIR`, `OUTPUT_DIR`.
- **Writes:** two timestamped reports under `REPORT_DIR`; a per-run log under `LOG_DIR` (real runs only — `--dry-run` stays non-mutating).
- **Dependencies:** `bash`, `jq`, and a SHA-256 tool; exits 2 if `--manifest-only` is set but the manifest file is missing.

## Dangerous operations

None destructive — the ritual is read-only except for its own reports and logs. Its findings are advisory: missing/orphan classifications inform cleanup decisions but never trigger deletions themselves.

## 🛣️ Navigation
<!-- Quick navigation links -->
- [Scripts Index](index.html)
- [Scan Reference](rc-scan.html)
- [Bones Home](index.html)

<!--
Limerick 1:
In shadows where orphaned files roam,
rc-scan ushers them back home.
It marks each lone soul,
In a checksum scroll,
And guards the tomb’s spectral dome.

Limerick 2:
When manifests call out the lost,
rc-scan measures true arc cost.
With hashes in hand,
It restores the land,
Ensuring no file is at frost.
-->

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-07-04T15:41:00Z -->


### Bones of the Code
The paranoid auditor. It checks files against `bones/manifest.txt` to see what has been stolen or what has crawled in uninvited.

### Restless Spirits
Its reporting mechanism for missing or orphaned files is easily confused by symlinks, bizarre characters in filenames, or simple directory restructurings. It cries wolf so often that its warnings are eventually ignored.

### Ritual Warnings
Do not treat its manifest as absolute truth. It is easily fooled by the slightest deviation in the physical realm.

## Ritual History
<!-- DIP-HISTORY-EXTRACTED: 2026-07-23T10:54:47Z -->

- - Optimize rc-scan.sh to run faster on large filesystems.
- - Improve rc-scan.sh orphaned file reporting format.
- - Optimize rc-scan.sh to quickly analyze missing references.
- tarballs, improved `rc-scan.sh` orphan reporting, `rc-ingest.sh` validation,
- `CHANGELOG.md` records faster `rc-scan.sh`, multiple ingest sources,

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
