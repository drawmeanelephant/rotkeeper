---
title: "🧾 rc-assets.sh Reference"
slug: rc-assets
template: rotkeeper-doc.html
version: "0.2.3-pre"
updated: "2025-06-01"
description: "Documents and explains the behavior of rc-assets.sh, which scans HTML for asset links and generates a manifest."
tags:
  - rotkeeper
  - scripts
  - assets
  - manifest
asset_meta:
  name: "rc-assets.md"
  version: "0.2.3-pre"
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
1. **Verify Dependencies**: `check_deps find sha256sum yq`.
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