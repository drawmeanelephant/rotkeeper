---
title: "🧾 rc-assets.sh Reference"
slug: rc-assets
target_file: "bones/scripts/rc-assets.sh"
date: "2026-08-26"
template: "rotkeeper-doc.html"
status: "active"
version: "0.5.1"
author: "Rotkeeper Ritual Council"
project: "Rotkeeper"
description: "Mirrors home/assets/ into output/assets/ and generates a SHA256 checksum manifest at bones/asset-manifest.yaml, pruning stale generated assets."
tags:
  - rotkeeper
  - scripts
  - assets
  - manifest
---


# 🖼️ rc-assets.sh

<!-- The sacred rite of asset manifest generation -->

**Script Path:** `bones/scripts/rc-assets.sh`

## Purpose
<!-- Core objectives of rc-assets.sh -->
- Enumerate every file under `home/assets/` (no HTML scanning — assets are mirrored by source tree, not discovered from rendered output)
- Copy each asset into `output/assets/`, preserving the directory layout
- Prune stale generated assets from `output/assets/` when the output tree is marked generated, so deleted source assets do not linger
- Emit a YAML manifest of path → SHA256 pairs to `bones/asset-manifest.yaml`, archiving any prior manifest to `bones/archive/`

## CLI Interface
```bash
rc-assets.sh [--dry-run] [--verbose] [--help]
```

Supported flags:
- `--help`, `-h`
  Show usage information and exit.
- `--dry-run`
  Preview actions without writing output.
- `--verbose`
  Show detailed logs.

## Workflow Steps
1. **Verify Dependencies**: `require_bins bash rsync` and `require_sha256` (sourced from `rc-utils.sh`).
2. **Archive Prior Manifest**: Move any existing `bones/asset-manifest.yaml` to `bones/archive/asset-manifest-<timestamp>.yaml`.
3. **Discover Assets**: Enumerate files under `home/assets/` (`find`, excluding `.DS_Store`), sorted by relative path.
4. **Prune Stale Output**: When the output tree is marked generated, delete `output/assets/` entries with no source counterpart.
5. **Sync & Checksum**: Validate each relative path for traversal/illegal characters, `rsync` into `output/assets/`, and compute SHA256.
6. **Assemble & Write Manifest**: Append `- path:` / `  sha256:` entries to the report, copy it to `bones/asset-manifest.yaml`, and mark the output tree generated.

## Exit Codes
<!-- Symbolic outcomes of incantation -->
- `0` — Manifest generated successfully.
- Nonzero — dependency failure (`require_bins` exits 2 when `rsync` is missing) or an I/O error under strict mode.

### Environment assumptions

- **Reads:** `ASSETS_DIR` (source tree), `OUTPUT_DIR`, `BONES_DIR`, `ARCHIVE_DIR`, `REPORT_DIR`; requires the output ownership marker (`.rotkeeper-generated`) before pruning.
- **Writes:** `output/assets/` mirror, `bones/asset-manifest.yaml` (prior manifest archived to `bones/archive/asset-manifest-<timestamp>.yaml`), timestamped report under `bones/reports/`.
- **Dependencies:** `bash`, `rsync`, and a SHA-256 tool (`sha256sum` or `shasum`).
- **CWD:** none — all paths are environment-derived.

## Dangerous operations

- **Prunes stale files from `output/assets/`** — any generated asset with no source counterpart is deleted, but only when the output tree carries the `.rotkeeper-generated` ownership marker; unmarked trees are never touched.
- Rotates the asset manifest by moving the previous one into `bones/archive/`; history is preserved, never merged.
- Relative asset paths are validated against traversal and character allowlists before copy; violations are logged as errors and skipped, not copied.

## Examples
```bash
# Generate full manifest
./bones/scripts/rc-assets.sh

# Preview without writing
./bones/scripts/rc-assets.sh --dry-run --verbose

# Show help
./bones/scripts/rc-assets.sh --help
```


## Manifest Format

The output manifest is a YAML file with entries like:

```yaml
- path: "images/rotkeeper-splash.png"
  sha256: "abc123..."
```

If no assets are found, the manifest is a single comment line: `# assets: []`.

## 🛣️ Navigation
<!-- Quick navigation links -->
- [Scripts Index](index.html)
- [Assets Reference](rc-assets.html)
- [Bones Home](../index.html)

<!--
Limerick 1:
In corridors of icons and sprites aligned,
rc-assets carves metadata refined.
With digest aflame,
It catalogs each name,
And preserves each relic assigned.

Limerick 2:
A scroll of YAML in spectral light,
Records each asset’s secret might.
It tracks size and date,
In tabular fate,
Ensuring no file fades from sight.
-->
## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-07-04T15:41:00Z -->


### Bones of the Code
This script trudges through the asset graveyard, cataloging artifacts and blindly copying them to `output/assets/`. It performs SHA256 checksum mapping, presumably because someone once trusted a file and paid the price. It's a glorified `cp` command with delusions of grandeur.

### Restless Spirits
The reliance on `sha256sum` or `shasum` preflights is a fragile pact; if the host lacks these, the ritual fails silently or spectacularly. More terrifyingly, it naively trusts asset filenames. A malicious filename could easily trigger a path traversal vulnerability, exfiltrating assets to wherever the dark forces desire.

### Ritual Warnings
Do not feed it untrusted zip files or chaotic directory structures unless you enjoy directory traversal exploits. Ensure `sha256sum` or `shasum` is bound to the environment before invoking this fragile magic.
## Ritual History
<!-- DIP-HISTORY-EXTRACTED: 2026-07-23T10:54:47Z -->

- - Hardened strict-mode and quoting behavior across `rc-assets.sh`,
-   fixes** — strict-mode and quoting hardening across `rc-assets.sh`,
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
