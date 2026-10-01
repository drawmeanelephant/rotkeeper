---
reference_contract: rotkeeper.command-reference.v1
title: rc-test.sh
slug: rc-test
target_file: bones/scripts/rc-test.sh
template: rotkeeper-doc.html
status: active
version: 0.8.1
author: Rotkeeper DIP
project: Rotkeeper
description: Multi-Pass Layout Integration Test Suite aligned for single distribution zip archives
---

# rc-test.sh

## Overview

Multi-Pass Layout Integration Test Suite aligned for single distribution zip archives

Source: `bones/scripts/rc-test.sh`.

## Usage

```bash
rotkeeper.sh test|smoke [--dry-run]
```

## Options

```text
--dry-run      Run only the removed-command regression checks
--help, -h     Show help
--version, -v  Show version and quit
```

## Examples

```bash
bash rotkeeper.sh test               # Full multi-layout harness matrix
bash rotkeeper.sh test --dry-run     # Removed-command regressions only
```

## Exit codes

```text
0         All harness assertions passed
nonzero   A harness assertion failed (the code identifies the suite)
```

## Reads and writes

**Environment:** reads OUTPUT_DIR, RK_OLIVER_BIN, RK_RENDERER, ROOT_DIR, ROTKEEPER_VERSION, SCRIPT_DIR, VERSION (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.

**Working directory:** No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.

**Inputs and outputs:** full test builds crypt/busy/sterile fixtures under `bones/tmp/rotkeeper-test-env`, runs the pipeline, verifies canonical release contents and absent legacy tiers, and checks renderer, JSON, command, DIP, and removed-command contracts.
Reads the release version from `bones/config/version` or `ROTKEEPER_VERSION`; requires jq and the tested commands dependencies. EXIT/INT/TERM cleanup removes fixtures only through `rk_guard_delete`.
`--dry-run` runs only the ingest/sync-inbox/cleanup/reseed removal checks, not the full matrix. The full harness also generates the fsbook retrieval catalog. Report macOS `realpath -m` portability failures without weakening assertions.

## Side effects

- **delete:** recursively removes the entire bones/tmp/<test-root> fixture tree on any exit
- **delete:** wipes any leftover test root under bones/tmp before the run starts
- **write:** creates the test fixture root under bones/tmp; every layout
  pass below builds and mutates its fixtures exclusively inside this boundary

## Notes
<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->

### Bones of the Code
The torturer. It subjects the scripts to Bats unit tests and dry-run sweeps, demanding perfection from an inherently flawed system.

### Restless Spirits
Its syntax validation is merely a surface-level scan, and its environment config checks often miss deeper semantic errors. It gives a false sense of security, allowing deeply nested bugs to slip through the cracks while it proudly reports a passing grade.

### Ritual Warnings
A passing test suite here merely means the code compiles; it does not mean the code is sane.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

No matching entries in CHANGELOG.md.
