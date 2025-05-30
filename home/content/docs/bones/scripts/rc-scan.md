---
title: "🔍 rc-scan.sh Reference"
slug: rc-scan
template: rotkeeper-doc.html
version: "0.2.1"
updated: "2025-05-29"
---

<!-- Begin Ritual Script Documentation -->

# 🔍 rc-scan.sh

<!-- The sacred rite of tomb inspection -->

**Script Path:** `bones/scripts/rc-scan.sh`

## Purpose
<!-- Core objectives of rc-scan.sh -->
- Traverse the file tree to identify orphan files (not in manifest) and missing artifacts (in manifest but absent).
- Compute and record SHA256 checksums for all valid files.
- Produce machine-readable JSON and human-readable Markdown summaries.

## CLI Interface
<!-- How to invoke the scanning ceremony -->
```bash
rc-scan.sh [--dry-run] [--verbose] [--help]
```

Supported flags:
- `--help`, `-h`
  Show usage information and exit.
- `--dry-run`
  Preview actions without writing reports.
- `--verbose`
  Show detailed logs.

## Workflow Steps
<!-- Sequential rites performed by the script -->
1. **Parse Flags & Setup**: Handle `--dry-run`, `--verbose`, and `--help`.
2. **Verify Dependencies**: `check_deps find sha256sum yq`.
3. **Load Manifest**: Read asset-manifest.yaml into `manifest_list`.
4. **Scan Files**: Walk `home/assets/` (or specified dir) into `disk_list`.
5. **Classification & Checksums**: Identify missing, orphan files, compute SHA256.
6. **Report Generation**: Write JSON and Markdown reports or preview under dry-run.

## Exit Codes
<!-- Symbolic outcomes of incantation -->
- `0` — Scan completed (even if orphans/missing found).
- `1` — Critical error (missing manifest, dependencies).
- `2` — No files found to scan.

## Examples
<!-- Sample invocations for celebratory rites -->
```bash
# Standard scan
./bones/scripts/rc-scan.sh

# Preview scan without writing
./bones/scripts/rc-scan.sh --dry-run --verbose

# Show help
./bones/scripts/rc-scan.sh --help
```

## 🛣️ Navigation
<!-- Quick navigation links -->
- [Scripts Index](scripts/index.html)
- [Scan Reference](scripts/rc-scan.html)
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