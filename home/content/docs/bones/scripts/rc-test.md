---
title: "rc-test.sh Documentation"
target_file: "bones/scripts/rc-test.sh"
date: "2026-08-26"
template: "rotkeeper-doc.html"
status: "active"
version: "0.5.1"
author: "Rotkeeper Ritual Council"
project: "Rotkeeper"
description: "Integration test harness: builds crypt/busy/sterile layout fixtures, exercises the full pipeline, asserts the release archive, and regression-checks removed commands."
tags:
  - rotkeeper
  - scripts
  - test
  - harness
---

# rc-test.sh

**Script Path:** `bones/scripts/rc-test.sh`

## Overview

`rc-test.sh` backs the `test` and `smoke` dispatcher commands (they map to the same harness). It is the release gate for the whole system.

**Full matrix run** (`rotkeeper.sh test`): for each layout mode — `crypt`, `busy`, `sterile` — the harness builds a temporary fixture under `bones/tmp/rotkeeper-test-env/`, runs `init --with-sample` against it, and exercises the rendered/packaged surface: render output shape, asset mirroring, template golden regressions (crypt pass), and the release packager. It then verifies the canonical single distribution archive and asserts the deprecated `-lite` and `-full` archives are absent, plus a battery of structural assertions across the produced trees. The release version is read from `bones/config/version`.

**Regression-only run** (`--dry-run`): executes only the removed-command checks — `ingest`, `sync-inbox`, `cleanup`, and `reseed` must each trigger their permanent-removal error; any other behavior fails with exit code 101.

Cleanup is trap-driven: on exit (including failure or interrupt) the fixture tree is pruned through `rk_guard_delete` against the `bones/tmp` boundary — if the guard refuses, the footprint is left behind with a warning rather than deleted unsafely.

On macOS, a failure at the harness's `realpath -m` preflight is a legitimate portability report, not a bug to paper over.

## CLI Usage

```bash
rotkeeper.sh test [--dry-run]
rotkeeper.sh smoke [--dry-run]

# Options:
#   --dry-run      Run only the removed-command regression checks
#   --help, -h     Show usage help
#   --version, -v  Show version and quit
```

### Environment assumptions

- **Reads:** `ROOT_DIR`, `bones/config/version` (release version under test); optional `ROTKEEPER_VERSION` override.
- **Writes:** everything under `bones/tmp/rotkeeper-test-env/` (fixtures, renders, packaged archives) plus its own console output; the tree is pruned by the exit trap.
- **Dependencies:** `bash`, `jq`; the full matrix additionally drives `init`/`render`/`pack`, so those tools' requirements apply transitively.
- **CWD:** expects invocation from the repository root (`./rotkeeper.sh …` is called directly).

## Dangerous operations

- **`rm -rf` of the test fixture tree** in the cleanup trap — strictly bounded by `rk_guard_delete` against `$ROOT_DIR/bones/tmp`; a refused guard leaves the tree in place instead of deleting outside bounds.
- The harness invokes real rituals (`init`, `render`, packager) inside its sandboxed fixture, never against the live workspace content.

## Details

### CLI Usage

```text
--dry-run
--help, -h
--version, -v
```

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-07-04T15:41:00Z -->


### Bones of the Code
The torturer. It subjects the scripts to Bats unit tests and dry-run sweeps, demanding perfection from an inherently flawed system.

### Restless Spirits
Its syntax validation is merely a surface-level scan, and its environment config checks often miss deeper semantic errors. It gives a false sense of security, allowing deeply nested bugs to slip through the cracks while it proudly reports a passing grade.

### Ritual Warnings
A passing test suite here merely means the code compiles; it does not mean the code is sane.

## Ritual History
<!-- DIP-HISTORY-EXTRACTED: 2026-07-23T10:54:47Z -->

*Not found: no changelog/history entries matching `rc-test.sh`.*

## Environment
<!-- DIP-ENV-EXTRACTED: 2026-08-12T00:38:36Z -->

- **$ROOT_DIR**: .
- **$OUTPUT_DIR**: output
- **$CONTENT_DIR**: home/content
- **$ASSETS_DIR**: home/assets
- **$DOCS_DIR**: home/content/docs
- **$HELP_DIR**: home/content/help
- **$BONES_DIR**: bones
- **$SCRIPT_DIR**: bones/scripts
- **$CONFIG_DIR**: bones/config
- **$LOG_DIR**: bones/logs
- **$TMP_DIR**: bones/tmp
- **$ARCHIVE_DIR**: bones/archive
- **$REPORT_DIR**: bones/reports
- **$BOOK_REPORT_DIR**: bones/book-reports
- **$TEMPLATE_DIR**: bones/templates
- **$META_DIR**: bones/meta
- **$WEB_DIR**: output

###### CLI Usage
<!-- DIP-HELP-EXTRACTED: 2026-08-15T15:43:55Z -->

*Not found: autopsy help report missing (`bones/reports/autopsy-help.md`). Run: ./rotkeeper.sh autopsy --help-report*
