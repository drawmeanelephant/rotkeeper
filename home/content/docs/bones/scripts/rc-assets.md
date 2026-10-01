---
reference_contract: rotkeeper.command-reference.v1
title: rc-assets.sh
slug: rc-assets
target_file: bones/scripts/rc-assets.sh
template: rotkeeper-doc.html
status: active
version: 0.8.1
author: Rotkeeper DIP
project: Rotkeeper
description: Mirror the source asset tree and generate a YAML manifest of relative paths and SHA-256 checksums.
---

# rc-assets.sh

## Overview

Mirror the source asset tree and generate a YAML manifest of relative paths and SHA-256 checksums.

Source: `bones/scripts/rc-assets.sh`.

## Usage

```bash
bash rotkeeper.sh assets [options]
```

## Options

```text
--dry-run        Preview asset changes; only bootstrap logs are written
--verbose        Show detailed logs
--help, -h       Show this help message and exit
--version, -v    Show script version and quit
```

## Examples

```bash
bash rotkeeper.sh assets                # Generate the asset manifest
bash rotkeeper.sh assets --dry-run      # Preview asset changes
bash rotkeeper.sh assets --dry-run --verbose
bash rotkeeper.sh assets --help         # Show help without starting a run
```

## Exit codes

```text
0    Success
1    Configuration or environment validation failure
2    Missing required dependency
nonzero    I/O failures propagate the failing command's exit status
```

## Reads and writes

**Environment:** reads `ASSETS_DIR`, `OUTPUT_DIR`, `BONES_DIR`, `ARCHIVE_DIR`, `REPORT_DIR`, `CONFIG_DIR`, `LOG_DIR`, `ROOT_DIR`, `SCRIPT_DIR`, `TMP_DIR`, `DRY_RUN`, `VERBOSE`, `VERSION` through `rk_load_env`; `ROTKEEPER_VERSION` can override the version. Requires `bash`, `rsync`, and either `sha256sum` or `shasum`.

**Working directory:** none; paths come from the active layout through `rk_load_env`, not the working directory.

**Inputs and outputs:** reads every regular file under `ASSETS_DIR` except `.DS_Store`, sorted by relative path; does not scan HTML or content references. Writes the `OUTPUT_DIR/assets` mirror, `BONES_DIR/asset-manifest.yaml`, `ARCHIVE_DIR/asset-manifest-<timestamp>.yaml`, and `REPORT_DIR/asset-report-<timestamp>.yaml`. Reports progress and errors through the shared logger. `--dry-run` previews asset changes without changing assets, manifests, reports, or the output ownership marker; bootstrap logging still writes under `LOG_DIR`.

## Side effects

- **write:** creates `OUTPUT_DIR/assets`, `ARCHIVE_DIR` (`bones/archive` by default), and `REPORT_DIR` (`bones/reports` by default) if missing
- **delete+write:** moves the previous `bones/asset-manifest.yaml` into `ARCHIVE_DIR/asset-manifest-<timestamp>.yaml`; does not merge manifests
- **write:** truncates `REPORT_DIR/asset-report-<timestamp>.yaml` (real runs only)
- **delete:** removes files under `OUTPUT_DIR/assets` that have no source counterpart, only when the output tree carries `.rotkeeper-generated`
- **write:** records an empty manifest entry in the report
- **write:** copies each valid source asset into `OUTPUT_DIR/assets` via `rsync`
- **write:** appends `path`/`sha256` entries to `REPORT_DIR/asset-report-<timestamp>.yaml`
- **write:** publishes the report as `BONES_DIR/asset-manifest.yaml`
- **write:** creates or truncates `OUTPUT_DIR/.rotkeeper-generated` through `mark_output_generated`; skipped during `--dry-run`

## Notes
<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->

### Design

The command verifies `bash`, `rsync`, and a SHA-256 tool before processing
assets. It archives the previous manifest, enumerates source files, prunes
stale generated assets, copies valid paths with `rsync -a`, computes checksums,
and publishes the timestamped report as the current manifest. It then marks
the output tree as generated.

The default `crypt` layout reads `home/assets/` and writes `output/assets/`.
Other layouts use their environment-derived asset and output directories.
Directory structure is preserved. Every source file is considered, whether
or not a content page references it.

Related pages: [Scripts index](index.html) and
[Bones documentation](../index.html).

The manifest and report contain YAML entries in this form:

```yaml
- path: "images/rotkeeper-splash.png"
  sha256: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
```

When no source files are found, the manifest contains the single comment
line `# assets: []`. Archives and reports use timestamps in
`YYYY-MM-DD_HHMM` format.

### Limits

Relative paths containing `../` or characters outside `[a-zA-Z0-9/._-]` are
logged as errors and skipped before copying. This includes spaces and
non-ASCII characters. These checks do not make the command a general
validator for untrusted directory trees.

Discovery uses `find -type f`, so symbolic links are not enumerated as assets.
Files named `.DS_Store` are excluded. The manifest records paths and
checksums, not sizes, dates, or reference counts. A successful exit does not
mean every discovered path was accepted.

### Cautions

Stale output files are deleted only when the output tree already contains
`.rotkeeper-generated`. An unmarked tree is not pruned, but valid source
assets are still copied into it and the command marks it as generated.

Prior manifests are moved to `bones/archive/` by default, not
`bones/archives/`. Archive and report names have minute resolution; repeated
runs in the same minute can replace files with the same timestamp.

`--dry-run` leaves assets, manifests, reports, and the output ownership marker
unchanged. Shared bootstrap logging still creates a run log. `--help` and
`--version` exit before starting the asset workflow.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

### [0.4.1] - 2026-07-22

- Hardened strict-mode and quoting behavior across `rc-assets.sh`,
  `rc-book.sh`, `rc-dip.sh`, and `rc-glue.sh`.
