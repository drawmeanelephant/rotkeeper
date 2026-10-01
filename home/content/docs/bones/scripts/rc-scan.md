---
reference_contract: rotkeeper.command-reference.v1
title: rc-scan.sh
slug: rc-scan
target_file: bones/scripts/rc-scan.sh
template: rotkeeper-doc.html
status: active
version: 0.8.1
author: Rotkeeper DIP
project: Rotkeeper
description: 'Audit the render ledger vs disk: missing, output-tree orphans, ledger digests, and digest mismatches'
---

# rc-scan.sh

## Overview

Audit the render ledger vs disk: missing, output-tree orphans, ledger digests, and digest mismatches

Source: `bones/scripts/rc-scan.sh`.

## Usage

```bash
rotkeeper.sh scan [flags]
```

## Options

```text
Flags:
--manifest-only   Read only manifest file, skip the output-tree walk.
--include <ext>   Comma-separated extensions to include in the orphan walk.
--exclude <pat>   Glob pattern to exclude from the orphan walk (can repeat).
--json            Emit machine-readable JSON to stdout (report files unchanged).
--json-only       Output only JSON report.
--md-only         Output only Markdown report.
--dry-run         Show actions without writing reports.
--verbose         Print detailed logs.
-h, --help        Show this help message and exit.
--version, -v     Show script version and quit.
```

## Examples

```bash
bash rotkeeper.sh scan                                     # Full audit
bash rotkeeper.sh scan --manifest-only                     # Manifest check only
bash rotkeeper.sh scan --include md,textile --dry-run      # Filtered preview
bash rotkeeper.sh scan --json | jq .                       # Machine-readable output
```

## Exit codes

```text
0    Success
1    Environment failure
2    Manifest file missing
```

## Reads and writes

**Environment:** reads BONES_DIR, CONFIG_DIR, CONTENT_DIR, DRY_RUN, LOG_DIR, LOG_FILE, OUTPUT_DIR, REPORT_DIR, ROOT_DIR, SCRIPT_DIR, TMP_DIR, VERBOSE, VERSION (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.

**Working directory:** No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.

**Inputs and outputs:** reads `bones/manifest.txt`, ignoring blank/comment lines and normalizing paths relative to the root. Requires Bash, jq, and a SHA-256 tool. Writes timestamped Markdown/JSON reports under `REPORT_DIR`; findings never delete source or output files.
The output-tree walk excludes generated support directories and `output/assets`; its default extensions are `png jpg svg css js md html json yaml`, adjustable through `--include` and repeatable `--exclude`.
Reports classify missing ledger entries, output orphans, SHA-256 digests, and mismatches against pack entries in `<path>  <sha256>` format. Missing digest targets have `actual: null`. `--manifest-only` skips the output walk.
`--json` also emits `rotkeeper.scan.v2` on stdout without changing report files or exit codes. `--json-only` and `--md-only` select report formats. Dry-run writes neither reports nor a run log; a missing manifest with `--manifest-only` exits 2.

## Side effects

- **write:** creates bones/reports and bones/logs if missing
- **write:** opens a fresh per-run scan log under bones/logs (real runs only)
- **write:** creates a bones/tmp scratch file for stdout JSON assembly
- **write:** appends the stdout JSON object to the per-run log
- **delete:** removes the stdout JSON scratch file after emit
- **write:** writes bones/reports/scan-report-<ts>.json (real runs only)
- **write:** writes bones/reports/scan-report-<ts>.md (real runs only)

## Notes
<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->

### Bones of the Code
The paranoid auditor. It checks files against `bones/manifest.txt` to see what has been stolen or what has crawled in uninvited.

### Restless Spirits
Its reporting mechanism for missing or orphaned files is easily confused by symlinks, bizarre characters in filenames, or simple directory restructurings. It cries wolf so often that its warnings are eventually ignored.

### Ritual Warnings
Do not treat its manifest as absolute truth. It is easily fooled by the slightest deviation in the physical realm.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

### [0.4.0.4] - 2026-07-01

- Optimize rc-scan.sh to run faster on large filesystems.

### [0.4.0.5] - 2026-07-01

- Improve rc-scan.sh orphaned file reporting format.

### [0.4.0.3] - 2026-06-30

- Optimize rc-scan.sh to quickly analyze missing references.
