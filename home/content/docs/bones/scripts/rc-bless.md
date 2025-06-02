---
title: "⚰️ rc-bless.sh Reference"
slug: rc-bless
template: rotkeeper-doc.html
version: "v0.2.3-pre"
updated: "2025-06-01"
description: "Emit ritual violation entries into the changelog and update the blessed manifest."
tags:
  - rotkeeper
  - scripts
  - changelog
  - blessing
asset_meta:
  name: "rc-bless.md"
  version: "v0.2.3-pre"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---
<!--
🎨 Sora Prompt:
"A moonlit catacomb where rc-bless.sh inscribes new ritual violations into the changelog, candles flickering on tombstones of forgotten versions."
-->
<!-- Begin Ritual Script Documentation -->
## Purpose

**Script Path:** `bones/scripts/rc-bless.sh`

<!-- The sacred objectives of rc-bless.sh -->

- Compare the current `asset-manifest.yaml` with the blessed `asset-manifest.yaml.prev`.
- Emit ritual violation entries into `CHANGELOG.md`.
- Update the blessed manifest to the latest state.

## CLI Interface

<!-- How to invoke the blessing ceremony -->

```bash
rc-bless.sh [--dry-run] [--verbose] [--help]
```

Supported flags:
- `--help`, `-h`
  Show usage information and exit.
- `--dry-run`
  Preview changelog update without writing to file.
- `--verbose`
  Show detailed logs during blessing.

## Workflow Steps

<!-- Sequential rites performed by the script -->

1. **Dependency Check**
   - `check_deps git date`.
2. **Prepare Logs**
   - Ensure `bones/logs/changelog.md` exists.
3. **Generate Changelog Entry**
   - Run `git diff` between HEAD~1 and HEAD, append or preview under dry-run.
4. **Update Docbook**
   - Regenerate `rotkeeper-docbook.md` and inject the latest changelog.
5. **Finalize Blessing**
   - Copy current changelog into archive if configured.

## Exit Codes

<!-- Symbolic outcomes of incantation -->

- `0` — Completed blessing (even if no violations).
- `1` — Usage error or missing flags.
- `2` — Dependency missing (e.g., `yq` not found).

## Examples

<!-- Sample invocations for celebratory rites -->

```bash
# Standard blessing
./bones/scripts/rc-bless.sh

# Preview blessing without writing
./bones/scripts/rc-bless.sh --dry-run --verbose

# Show help
./bones/scripts/rc-bless.sh --help
```

## 🛣️ Navigation
<!-- Quick navigation links -->
- [Scripts Index](scripts/index.html)
- [Bless Reference](scripts/rc-bless.html)
- [Bones Home](index.html)

<!--
Limerick 1:
There once was a tomb full of code,
Where each artifact bore a load.
When blessings were cast,
The past versions passed,
And the changelog commemorated each node.

Limerick 2:
In crypts where old manifests lie,
rc-bless makes the spirits comply.
It notes every shift,
Each version’s swift drift,
Then seals the new state by and by.
-->
