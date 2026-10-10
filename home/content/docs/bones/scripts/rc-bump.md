---
reference_contract: rotkeeper.command-reference.v1
title: rc-bump.sh
slug: rc-bump
target_file: bones/scripts/rc-bump.sh
template: rotkeeper-doc.html
status: active
version: 0.8.1
author: Rotkeeper DIP
project: Rotkeeper
description: Explicit semver version bump against the single canonical version file
---

# rc-bump.sh

## Overview

Explicit semver version bump against the single canonical version file

Source: `bones/scripts/rc-bump.sh`.

## Usage

```bash
rotkeeper.sh bump [--major|--minor|--patch|--to X.Y.Z] -m MESSAGE [options]
```

## Options

```text
--major            Bump major segment: 0.5.1 -> 1.0.0
--minor            Bump minor segment: 0.5.1 -> 0.6.0
--patch            Bump patch segment: 0.5.1 -> 0.5.2
--to VERSION       Set an explicit semver-style version (X.Y.Z)
--message, -m MSG  Update message recorded in CHANGELOG.md and the roadmap
--commit           Stage changes and commit them to git
--dry-run          Preview changes without saving or committing
--verbose          Detailed output
--help, -h         Show help
--version, -v      Show version and quit
```

## Examples

```bash
bash rotkeeper.sh bump --patch -m "Fix wrap bug"                 # Patch bump
bash rotkeeper.sh bump --to 0.8.0 -m "UX pass" --commit          # Explicit version + commit
bash rotkeeper.sh bump --minor -m "..." --dry-run                # Preview only
```

## Exit codes

```text
0    Success
1    Invalid input or bump failure
```

## Reads and writes

**Environment:** reads BONES_DIR, CONFIG_DIR, DOCS_DIR, DRY_RUN, LOG_DIR, QUIET, ROOT_DIR, SCRIPT_DIR, TMP_DIR, VERBOSE, VERSION (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.

**Working directory:** No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.

**Inputs and outputs:** reads the validated semver in `bones/config/version`; the bump calculation does not use `ROTKEEPER_VERSION`. Exactly one of major/minor/patch or `--to` is required; major/minor selectors reset lower segments.
Stages the timestamped message after the first `LIVING_BUILDLOG_START` in `DOCS_DIR/road-to-bones/index.md`, a dated CHANGELOG release, and the canonical version as scratch files beside their targets, then moves them into place with the version file last. A missing anchor or `## [` header, or any staging failure, exits 1 with no file changed.
`--commit` stages the version, changelog, and roadmap and commits from `ROOT_DIR`; it never pushes. A dirty worktree is warned about rather than rejected. Dry-run previews all updates and Git actions without writes and fails on the same missing anchors.

## Side effects

- **delete:** removes any <target>.tmp.$$ scratch file a failed run left behind
- **write:** creates <target>.tmp.$$ beside the target (dry-run writes nothing)
- **write:** replaces the roadmap, CHANGELOG.md, then bones/config/version with their scratch files via mv
- **git:** stages the version file, CHANGELOG.md, and roadmap index
- **git:** creates a commit "bump: <version> - <message>" (no push)

## Notes
<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->

### Design

Uses the canonical `bones/config/version` file for the bump calculation, independently of the display-version override. Updates that file, inserts the message after the first roadmap buildlog anchor under `DOCS_DIR/road-to-bones/index.md`, and prepends a release section before the first `## [` heading in `CHANGELOG.md`. Every update is rendered into a scratch file beside its target before any target is replaced, and the version file is replaced last. Major and minor bumps reset lower version segments.

### Limits

Requires exactly one version selector and a non-empty message. Versions have three numeric segments; prerelease and build suffixes are not accepted. Missing roadmap or changelog files produce warnings rather than blocking the version update. A roadmap without the buildlog anchor, or a changelog without a `## [` heading, fails the bump (dry-run included) before any file changes. The final replacements are separate same-directory renames, not one transaction; a rename failure after staging can still leave the roadmap or changelog ahead of the version file, which is never moved early.

### Cautions

Committing is opt-in with `--commit`; there is no automatic commit or push. A dirty working tree is warned about, not rejected. Staging includes existing changes in the three touched files, and the commit includes any other already-staged changes. Dry-run previews payload updates without applying them, but shared bootstrap logging still writes; its commit preview is printed even without `--commit`.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

No matching entries in CHANGELOG.md.
