---
title: "🔍 Scan Reports"
slug: scan-reports
template: rotkeeper-doc.html
version: "v0.2.3-pre"
updated: 2025-06-01
description: "Archive of historical scan outputs and SHA256 digests"
tags:
  - rotkeeper
  - scan
  - digests
asset_meta:
  name: "scan-reports.md"
  version: "v0.2.3-pre"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# 🔍 Scan Reports

<!-- The council’s ledger of all scan report artifacts -->

The `scan-reports` archive contains chronological records of each `rc-scan.sh` run, including lists of orphans, missing files, and SHA256 digests.

## Location

- Directory: `/scan-reports/`
- Naming: `scan-report-YYYYMMDD-HHMMSS.json` and `.md`

## Contents

- **JSON files**: raw data with `missing`, `orphans`, and `digests`.
- **Markdown files**: human-readable summaries with sections:
  - Orphaned files
  - Missing entries
  - Checksum tables

## 🧭 Usage

<!-- How to browse the archived scan reports -->

To view the latest report:

```bash
less archive/scan-reports/scan-report-$(date +%Y%m%d-)*.md
```

To diff two reports:

```bash
diff archive/scan-reports/scan-report-20250526-*.md archive/scan-reports/scan-report-20250527-*.md
```

## 🛣️ Navigation

<!-- Quick links within Archive -->
- [Archive Index](index.html)
- [Changelog](CHANGELOG.html)
- [Manifest Backups](manifests.html)

## Future Additions

<!-- Aspirational rites for scan reports -->
- Add tag-based filtering (e.g., only show `missing` sections).
- Graphical summaries of changes over time.
- Automated report pruning after N days.