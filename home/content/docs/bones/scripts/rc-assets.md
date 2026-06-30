---
title: "🧾 rc-assets.sh Reference"
slug: rc-assets
version: "0.2.5"
updated: "2025-06-03"
description: "Documents and explains the behavior of rc-assets.sh, which scans HTML for asset links and generates a manifest."
tags:
  - rotkeeper
  - scripts
  - assets
  - manifest
asset_meta:
  name: "rc-assets.md"
  version: "0.2.5"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---


# 🖼️ rc-assets.sh

<!-- The sacred rite of asset manifest generation -->

**Script Path:** `bones/scripts/rc-assets.sh`

## Purpose
<!-- Core objectives of rc-assets.sh -->
- Scan rendered HTML in `output/` for `<img>` or `<link>` tags referencing `assets/`
- Identify actual files used in the tomb pages
- Copy matched assets from `home/assets/` into `output/assets/`
- Emit a YAML manifest of the matched files to `bones/asset-manifest.yaml`

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
1. **Verify Dependencies**: `require_bins find sha256sum yq` (sourced from `rc-utils.sh`).
2. **Discover Assets**: Locate referenced assets in output/*.html
3. **Compute Metadata**: For each referenced asset, compute SHA256 and copy into output/assets/
4. **Assemble & Write Manifest**: Structure and write to `bones/asset-manifest.yaml` or preview under dry-run.

## Exit Codes
<!-- Symbolic outcomes of incantation -->
- `0` — Manifest generated successfully.
- `1` — Dependencies missing or I/O error.
- `2` — Critical error (e.g. missing inputs)

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

If no assets are found, an empty manifest with `assets: []` is written.

## 🛣️ Navigation
<!-- Quick navigation links -->
- [Scripts Index](scripts/index.html)
- [Assets Reference](scripts/rc-assets.html)
- [Bones Home](index.html)

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
<!-- DIP-SOUL-EXTRACTED: 2026-06-30T14:44:02Z -->


### Bones of the Code
This script trudges through the asset graveyard, cataloging artifacts and blindly copying them to `output/assets/`. It performs SHA256 checksum mapping, presumably because someone once trusted a file and paid the price. It's a glorified `cp` command with delusions of grandeur.

### Restless Spirits
The reliance on `sha256sum` or `shasum` preflights is a fragile pact; if the host lacks these, the ritual fails silently or spectacularly. More terrifyingly, it naively trusts asset filenames. A malicious filename could easily trigger a path traversal vulnerability, exfiltrating assets to wherever the dark forces desire.

### Ritual Warnings
Do not feed it untrusted zip files or chaotic directory structures unless you enjoy directory traversal exploits. Ensure `sha256sum` or `shasum` is bound to the environment before invoking this fragile magic.
