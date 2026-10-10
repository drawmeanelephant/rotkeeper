---
reference_contract: rotkeeper.command-reference.v1
title: rc-autopsy.sh
slug: rc-autopsy
target_file: bones/scripts/rc-autopsy.sh
template: rotkeeper-doc.html
status: active
version: 0.8.1
author: Rotkeeper DIP
project: Rotkeeper
description: Script dissection and output cataloging
---

# rc-autopsy.sh

## Overview

Script dissection and output cataloging

Source: `bones/scripts/rc-autopsy.sh`.

## Usage

```bash
rotkeeper.sh autopsy [mode] [options]
```

## Options

```text
Modes:
--help-report    Extract --help output from all rc-*.sh into a reference report
--output-report  Scan scripts for file-write operations and catalog outputs
--all            Run both reports (default)

--dry-run        Preview without writing
--verbose        Detailed logging
--help, -h       Show this help message and exit
--version, -v    Show script version and quit
```

## Examples

```bash
bash rotkeeper.sh autopsy                  # Both reports (default)
bash rotkeeper.sh autopsy --help-report    # Help catalog only
```

## Exit codes

```text
0    Success
1    Report generation failure
```

## Reads and writes

**Environment:** reads BONES_DIR, CONFIG_DIR, DRY_RUN, LOG_DIR, REPORT_DIR, ROOT_DIR, SCRIPT_DIR, TMP_DIR, VERSION (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.

**Working directory:** No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.

**Inputs and outputs:** reads scripts under `SCRIPT_DIR` and the root dispatcher. With no mode, or `--all`, rewrites both `REPORT_DIR/autopsy-help.md` and `REPORT_DIR/autopsy-outputs.md`.
Help extraction invokes only PERMITTED_RITUALS with `ROT_SKIP_ENV=true`, falling back to flag-string extraction for empty help. Output analysis catalogs writes, copies, moves, tee, and tar operations with line numbers and environment-resolved paths.
DIP may use the output report for artifact exclusions, but command help is harvested directly from script comments and does not require the help report. Dry-run previews report writes.

## Side effects

- **write:** overwrites bones/reports/autopsy-help.md
- **write:** overwrites bones/reports/autopsy-outputs.md

## Notes
<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->

### Design

Catalogs command help and source-level output operations, not process logs or stack traces. Discovers top-level `rc-*.sh` files and the dispatcher; help collection executes only explicitly permitted basenames with `--help` and `ROT_SKIP_ENV=true`. Real runs replace `bones/reports/autopsy-help.md`, `bones/reports/autopsy-outputs.md`, or both.

### Limits

The output catalog uses line-oriented regular expressions for selected redirections, copies, moves, tee, and tar syntax. It substitutes exported directory variables and labels remaining variables unresolved. It is not a complete parser of shell behavior, quoting, multiline commands, or indirect writes. An empty help response falls back to flag strings found in source; captured error text can also appear in the report.

### Cautions

Verify report entries against current source before using them as operational facts. DIP may consume the output report for artifact exclusions, but harvests command help directly from source comments. `--dry-run` is honored before or after a report-mode flag; the shared parser sets it and the local mode parser ignores it. A dry-run skips report writes and help execution but still writes bootstrap logs.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

No matching entries in CHANGELOG.md.
