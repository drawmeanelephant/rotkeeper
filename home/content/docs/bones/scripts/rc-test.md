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
rotkeeper.sh test|smoke [--dry-run | --site]
```

## Options

```text
--site         Build and enforce Help/Docs gates in the current checkout
--dry-run      Run only the removed-command regression checks
--help, -h     Show help
--version, -v  Show version and quit
```

## Examples

```bash
bash rotkeeper.sh test               # Full multi-layout harness matrix
bash rotkeeper.sh test --site        # Build/check the deployable help site
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

### Design

Bash integration harness shared by the dispatcher test and smoke commands. Creates crypt, busy, and sterile fixtures beneath `bones/tmp/rotkeeper-test-env`, exercises initialization, rendering, packaging, scanning, and release, and checks output pruning, archive integrity, metadata/template contracts, documentation navigation, and command help/version behavior. Includes isolated DIP generation and migration fixtures and removed-command regressions.

The full run also initializes a disposable copy of the tracked working site,
copies it again, proves normal commands reject its stale relocation cache,
and repairs it with plain init before building. It checks that copying retains
tracked working edits and that repair/build leaves the parent configuration
byte-identical and its tracked edits unchanged. Each layout also checks copy
and physical-move repair, malformed YAML, missing/escaping caches, layout
changes, canonical symlink boundaries, and supported dry-run non-mutation.
The repaired copy builds and
enforces the Help/Docs quality gates. Fifteen isolated corruptions prove
failures for placeholders, links, accessibility, sidecars, generated command
coverage, page structure, authored guides, and degraded DIP inputs.
`test --site` runs the same build and gates in the current checkout, without
the fixture matrix. CI and publication use this mode to check the actual
deployable artifact. It regenerates source references and the DIP matrix.

### Limits

Uses fixture Oliver executables for adapter contracts, with real-renderer smoke, CommonMark, XHTML, and template-golden checks when an executable Oliver is available. `RK_STRICT=1` makes specified missing real-renderer checks, fixtures, or XML tooling fatal rather than skipped. The dry-run mode runs only the removed-command regressions; it is not a preview of the full matrix. Dry-run payload non-mutation assertions compare file counts, not all file contents.

Init relocation dry-runs compare configuration bytes and check that output
directories are not created; bootstrap logs remain an expected write.
The isolated scaffold contract checks Markdown, Textile, and Cooklang
sidecars in every layout, including null review fields, dry-run non-publication,
and preservation of existing sidecars. It also checks that glue does not
merge the dispatcher's file sidecar into the content-root index.

### Cautions

The full run generates the filesystem catalog in the working repository as well as temporary fixtures, so its effects are not limited to fixture files. `RK_REGEN_TEMPLATE_GOLDENS=1` deliberately rewrites checked-in goldens during the crypt pass; review those changes before committing. Fixture cleanup uses the shared deletion guard. A passing fixture adapter is not proof of real CommonMark fidelity; report platform/tool failures rather than weakening assertions.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

No matching entries in CHANGELOG.md.
