---
reference_contract: rotkeeper.command-reference.v1
title: rc-release.sh
slug: rc-release
target_file: bones/scripts/rc-release.sh
template: rotkeeper-doc.html
status: active
version: 0.8.1
author: Rotkeeper DIP
project: Rotkeeper
description: Streamline multi-tier models down to a single-tier canonical framework distribution zip
---

# rc-release.sh

## Overview

Streamline multi-tier models down to a single-tier canonical framework distribution zip

Source: `bones/scripts/rc-release.sh`.

## Usage

```bash
rotkeeper.sh release <VERSION> [options]
```

## Options

```text
Arguments:
VERSION        Semver-style version for the distribution name (e.g. 0.8.0)

--dry-run      Preview the release without writing archives
--verbose      Detailed output
--help, -h     Show help
--version, -v  Show version and quit
```

## Examples

```bash
bash rotkeeper.sh release 0.8.0              # Package the distribution
bash rotkeeper.sh release 0.8.0 --dry-run    # Preview without writing
```

## Exit codes

```text
0    Success
1    Invalid usage or packaging failure
3    Write-boundary violation
```

## Reads and writes

**Environment:** reads ARCHIVE_DIR, BONES_DIR, BOOK_REPORT_DIR, CONFIG_DIR, CONTENT_DIR, DRY_RUN, LOG_DIR, OUTPUT_DIR, RELEASE_DIR, REPORT_DIR, ROOT_DIR, SCRIPT_DIR, TMP_DIR, VERBOSE, VERSION (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.

**Working directory:** No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.

**Inputs and outputs:** requires Bash, rsync, zip, and zipinfo. Reads the repository through exclusions and stages a framework distribution under `TMP_DIR`; it is not a full author-content backup.
Generates `bones/config/release-manifest.txt` with version, model, ruleset, and sorted entries. Tests the zip and verifies a root allowlist, required framework spine, and forbidden paths/artifacts including output, caches, reports, credentials, and editor backups.
Promotes only a verified archive to `RELEASE_DIR/rotkeeper-<version>.zip`, replacing an existing same-version archive. EXIT/INT/TERM cleanup uses `rk_guard_delete` to prune staging and removes the in-flight zip. Dry-run previews without archiving.

## Side effects

- **delete:** removes bones/tmp/release-staging-<pid> on any exit path
- **delete:** removes the in-flight zip temp file (no-op after successful mv)
- **write:** creates bones/archives/releases and bones/tmp/release-staging-<pid>
- **write:** copies the repo (minus exclusions) into the staging tree
- **write:** writes the entry list scratch file under bones/tmp
- **write:** generates release-manifest.txt inside the staged tree
- **delete:** removes the entry list scratch file
- **archive:** zips the staged tree to <release>.zip.tmp.$$ (temp name)
- **write:** promotes the verified temp zip to bones/archives/releases/rotkeeper-<version>.zip

## Notes
<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->

### Design

Stages a single framework distribution under `bones/tmp/release-staging-<pid>/rotkeeper`, using rsync exclusions. Generates `bones/config/release-manifest.txt` inside that staged tree, tests ZIP integrity, and checks archive entries against a root-entry allowlist, required framework files, forbidden runtime trees, and forbidden artifact patterns. Only a verified archive is promoted to `bones/archive/releases/rotkeeper-<version>.zip`.

### Limits

There are no lite or full tiers. This distribution is not a complete backup of author content. The allowlist constrains root entries, not every descendant file; the artifact checks cover the listed patterns rather than all possible private data. An omitted positional version uses the loaded version; the parser does not enforce the semver-style form advertised by help.

### Cautions

A successful release replaces an existing archive with the same name. Review staged content and the exclusion/verification rules before distributing it. Cleanup guards staging deletion and removes the in-flight ZIP. Dry-run still loads the environment, checks required tools, and writes bootstrap logs, but does not stage files, generate the manifest, or build and verify an archive.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

No matching entries in CHANGELOG.md.
