---
title: "🔒 rc-verify.sh Reference"
slug: rc-verify
template: rotkeeper-doc.html
version: "0.2.2"
updated: "2025-05-30"
---
<!-- Begin Ritual Script Documentation -->
# 🔒 rc-verify.sh
<!-- The sacred rite of checksum validation -->

**Version:** v0.2.2
**Script Path:** `bones/scripts/rc-verify.sh`

## Purpose
<!-- Core validation objectives -->

- Enforce file integrity by recomputing SHA256 checksums for each file listed in `asset-manifest.yaml` and comparing them to recorded values.
- Prevent unblessed or tampered files from persisting by failing on any mismatch.

## CLI Interface
<!-- How to invoke the validation ceremony -->

```bash
rc-verify.sh [--dry-run] [--verbose] [--help] [--warn-only] [--update] [--manifest-path PATH]
```

Supported flags:

- `--help`, `-h`
  Show usage information and exit.

- `--dry-run`
  Preview actions without writing changes.

- `--verbose`, `-v`
  Show detailed logs.

- `--warn-only`
  Log mismatches without non-zero exit.

- `--update`
  Update manifest entries with computed checksums.

- `--manifest-path PATH`
  Specify alternate manifest file.

## Workflow Steps
<!-- Sequential rites performed by the script -->

1. **Setup & Configuration**
   - Locate `asset-manifest.yaml` and ensure `logs/` directory exists.
   - Parse CLI flags for custom behavior.

2. **Load Manifest**
   - Use `yq` to read each asset `path` and `sha256` value from the manifest.

3. **Verification Loop**
   For each manifest entry, recompute SHA256, compare, log `OK` or `ERROR`; on mismatches respect `--warn-only`.

   Skip any entries where the `path` is empty or malformed.

4. **Manifest Update (optional)**
   - If `--update` is used, replace expected SHA values in the manifest with computed ones.

5. **Completion & Exit**
   - If any mismatches occurred and not in `--warn-only`, exit code `1`.
   - On success or `--warn-only`, exit code `0`.

## Exit Codes
<!-- Symbolic outcomes of incantation -->

- `0` — All files verified (or mismatches only logged in `--warn-only` mode).
- `1` — One or more mismatches detected.
- `2` — Manifest not found, or tracked file is missing.

## Examples
<!-- Sample invocations for celebratory rites -->

```bash
# Standard verify
./bones/scripts/rc-verify.sh

# Preview without writing
./bones/scripts/rc-verify.sh --dry-run --verbose

# Warn-only mode
./bones/scripts/rc-verify.sh --warn-only

# Update manifest
./bones/scripts/rc-verify.sh --update

# Custom manifest
./bones/scripts/rc-verify.sh --manifest-path config/custom-manifest.yaml
```


<!-- 🎴 Limerick 1:
There once was a tool named rc-verify,
Whose checks kept the bad bytes awry.
It scanned every file,
With a timestamped style,
And bid any rogue hash goodbye.
-->

<!-- 🎴 Limerick 2:
In the tombs where old bytes lie low,
rc-verify makes tamperers go.
With SHA at its core,
It reveals every flaw,
So your site’s integrity will glow.
-->