---
title: "🖼️ rc-assets.sh Reference"
slug: rc-assets
template: rotkeeper-doc.html
version: "0.2.1"
updated: "2025-05-29"
---


# 🖼️ rc-assets.sh

<!-- The sacred rite of asset manifest generation -->

**Script Path:** `bones/scripts/rc-assets.sh`

## Purpose
<!-- Core objectives of rc-assets.sh -->
- Crawl the `home/assets/` directory to discover all static resources.
- Compute metadata: filename, path, SHA256 digest, size, and modification timestamp.
- Emit a consolidated YAML manifest for downstream tools.

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
2. **Discover Assets**: Locate files in `home/assets/`.
3. **Compute Metadata**: Gather path, size, digest, and timestamp.
4. **Assemble & Write Manifest**: Structure and write to `bones/asset-manifest.yaml` or preview under dry-run.

## Exit Codes
<!-- Symbolic outcomes of incantation -->
- `0` — Manifest generated successfully.
- `1` — Dependencies missing or I/O error.
- `2` — No assets found.

## Examples
```bash
# Generate full manifest
./bones/scripts/rc-assets.sh

# Preview without writing
./bones/scripts/rc-assets.sh --dry-run --verbose

# Show help
./bones/scripts/rc-assets.sh --help
```


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