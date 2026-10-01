---
reference_contract: rotkeeper.command-reference.v1
title: rc-status.sh
slug: rc-status
target_file: bones/scripts/rc-status.sh
template: rotkeeper-doc.html
status: active
version: 0.8.1
author: Rotkeeper DIP
project: Rotkeeper
description: Output a structured, human-readable status report across environment, health, and pulse.
---

# rc-status.sh

## Overview

Output a structured, human-readable status report across environment, health, and pulse.

Source: `bones/scripts/rc-status.sh`.

## Usage

```bash
rotkeeper.sh status [options]
```

## Options

```text
--json         Emit a machine-readable JSON report
--short        One-line summary (version | pages | freshness | branch)
--dry-run      No-op flag accepted for contract consistency
--verbose      Detailed output
--help, -h     Show help
--version, -v  Show version and quit
```

## Examples

```bash
bash rotkeeper.sh status           # Full health report
bash rotkeeper.sh status --short   # One-line summary
bash rotkeeper.sh status --json    # Machine-readable report
```

## Exit codes

```text
0         Success
nonzero   Environment error
```

## Reads and writes

**Environment:** reads ARCHIVE_DIR, BONES_DIR, BOOK_REPORT_DIR, CONFIG_DIR, CONTENT_DIR, DOCS_DIR, LOG_DIR, LOG_FILE, OUTPUT_DIR, ROOT_DIR, ROTKEEPER_VERSION, SCRIPT_DIR, TMP_DIR, VERBOSE, VERSION (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.

**Working directory:** No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.

**Inputs and outputs:** reads version/configuration, Git context, scripts, content, output, archives, and book reports. Requires Bash, jq, and yq v4. Apart from its run log, it does not mutate the workspace.
Reports environment/version provenance, script syntax health, binder exports, releases, recent archives, per-format content counts, render freshness, and configuration. Freshness compares source/HTML mtimes and reports current, stale, or empty output.
Default output is a human-readable report; `--short` emits version/pages/freshness/branch on one line and `--json` emits the same sections as JSON. Restores caller stdout/stderr after bootstrap so quiet mode does not hide the report; colors respect `NO_COLOR`.

## Side effects

- **write:** creates bones/logs before the status ritual boots its logger

## Notes
<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->

### Bones of the Code
The physician examining a corpse. It attempts to provide diagnostics and status reports by probing the repository and log files.

### Restless Spirits
If Git is not installed, it panics like a lost child. If the logs are empty, it assumes everything is perfectly fine, completely blind to the fact that the logging daemon might have silently crashed days ago.

### Ritual Warnings
Do not mistake silence for health. An empty log often means the patient is already dead.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

No matching entries in CHANGELOG.md.
