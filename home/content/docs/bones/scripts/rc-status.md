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

### Design

Reports version provenance, caller working directory and Git context, script inventory, bound-book sizes, release ZIPs, recent tarballs, content counts, render freshness, and selected configuration fields. Restores the caller’s output streams after shared bootstrap so reports remain visible. Short mode emits a single summary; JSON mode emits the full section data. Reporting writes a run log but does not generate content or repair state.

### Limits

Script health assigns the loaded canonical version to each discovered script; it does not execute script versions or run Bash syntax checks. Freshness compares the newest source mtime with the newest HTML mtime, not each source/output pair, templates, or assets. Stub/draft counts use literal status-line matches. Missing Git context becomes `[no git]` in human output and null fields in JSON, not a fatal Git dependency failure.

### Cautions

An “output is current” result is a coarse freshness heuristic, not proof that every page exists or matches its source. Git queries use the caller’s working directory, and release discovery uses a root-relative path, so run from the repository root for repository-wide results. `--dry-run` is a no-op report flag and does not suppress logging. `--json` takes precedence over `--short` when both are supplied.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

No matching entries in CHANGELOG.md.
