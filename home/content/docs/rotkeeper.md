---
reference_contract: rotkeeper.command-reference.v1
title: rotkeeper.sh
slug: rotkeeper
target_file: rotkeeper.sh
template: rotkeeper-doc.html
status: active
version: 0.8.1
author: Rotkeeper DIP
project: Rotkeeper
description: CLI dispatcher for aligned single framework release structures
---

# rotkeeper.sh

## Overview

CLI dispatcher for aligned single framework release structures

Source: `rotkeeper.sh`.

## Usage

```bash
rotkeeper.sh <command> [options]
```

## Options

```text
Commands:
init        Initialize environment
new <file>  Scaffold a new markdown file
render      Convert markdown into HTML tombs
pack        Archive rendered HTML into a versioned tarball
preflight   Report Oliver renderer availability and compatibility
release     Package the project into a single canonical framework zip file
bump        Record a microrelease update and synchronize version markers
test        Run the integration test harness matrix (alias: smoke)
scan        Verify manifest entries against actual files
assets      Generate asset manifest
autopsy     Catalog script help and output behavior
glue        Auto-generate navigation glue for unindexed content directories
links       Audit links and local assets in rendered HTML
a11y        Audit theme accessibility: contrast, focus states, legibility
showcase    Generate showcase content for every HTML template
dip         Audit documentation coverage via DIP
book        Generate aggregated documentation book targets
status      Display environment health status reports
```

## Examples

```bash
bash rotkeeper.sh init --full          Initialize sample env, assets, render, scan
bash rotkeeper.sh render               Render content tombs into HTML
bash rotkeeper.sh pack                 Archive rendered HTML into a tomb
bash rotkeeper.sh release 0.8.0        Package the canonical distribution
```

## Exit codes

```text
0    Success
1    Unknown command or ritual failure
```

## Reads and writes

**Environment:** reads `ROTKEEPER_VERSION` or `bones/config/version`; requires Bash and the command scripts under `bones/scripts`.

**Working directory:** none; the repository root is derived from the dispatcher location.

**Inputs and outputs:** reads command arguments and delegates to the selected script. `--help` and `--version` write only stdout; other commands have their own read/write contracts. Unknown and removed commands exit nonzero.

## Side effects

No side effects are documented in script annotations.

## Notes
<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->

### Design

The dispatcher derives the repository root from its own location and
loads `bones/scripts/rc-utils.sh` for version and help handling. It runs
command scripts with Bash. `test` and `smoke` select the same harness.
`release` supplies the current version unless a positional version is given.

### Limits

The dispatcher does not load the layout itself; command bootstraps do that.
It does not require the caller's working directory to be the repository
root. Unknown commands and the removed `ingest`, `sync-inbox`, `cleanup`,
and `reseed` commands fail.

### Cautions

Invoke project commands through `bash rotkeeper.sh <command>`, not by
executing `rc-*.sh` files directly. Subcommands have their own dependencies
and side effects. Top-level help and version output do not start a workflow.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

### [0.5.0] - 2026-07-23

- Added dispatcher link audit tool (`rc-links.sh` / `./rotkeeper.sh links`) for link checking and local asset verification with angle-bracket compatibility.
