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

### Architectural Intent
The primary dispatcher for the Rotkeeper system. It acts as the gateway cli to bootstrap the environment, invoke scripts like `rc-init.sh`, `rc-render.sh`, `rc-dip.sh`, and `rc-release.sh`, and coordinate test suites.

### Directory / File Schema Expectations
It is a wrapper with high expectations. It requires `rc-utils.sh` and `rc-env.sh` to exist in the same directory, failing immediately if the environment variables are not populated. If child scripts exit with unhandled errors, it occasionally fails to report the specific failure origin. Always execute `rotkeeper.sh` from the workspace root or ensure script directories are accessible. Verify environment paths, or the dispatcher will fail to bootstrap.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

### [0.5.0] - 2026-07-23

- Added dispatcher link audit tool (`rc-links.sh` / `./rotkeeper.sh links`) for link checking and local asset verification with angle-bracket compatibility.
