---
title: "📈 rc-bump.sh Reference"
slug: rc-bump
version: "0.5.1"
updated: "2026-08-11"
description: "Explicit semver version bump against the single canonical version source."
tags:
  - rotkeeper
  - scripts
  - logging
  - versioning
asset_meta:
  name: "rc-bump.md"
  version: "v0.5.1"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "All Rights Reserved"
---

<!--
🎨 Sora Prompt:
"A mechanical monk meticulously chiseling a new version number into a monolithic stone tablet, surrounded by piles of old, dusty blueprints."
-->

# 📈 rc-bump.sh

<!-- The rite of chronicling progress -->
**Script Path:** `bones/scripts/rc-bump.sh`

## Purpose
- Advances the project version through explicit semver-style updates (major, minor, patch, or an explicit `--to` version).
- Updates the single canonical version source at `bones/config/version`; all scripts, the dispatcher, release names, tests, and docs read from it.
- Injects updates into the Living Buildlog and the `CHANGELOG.md`.
- Optionally stages and commits the changes to Git with `--commit`.

## CLI Interface
```bash
./rotkeeper.sh bump --patch -m "Your update message here"
./rotkeeper.sh bump --minor -m "New minor release"
./rotkeeper.sh bump --major -m "Breaking release"
./rotkeeper.sh bump --to 0.6.0 -m "Explicit version"
```

## Workflow Steps
1. **Version Discovery**
   - Reads the current version from `bones/config/version` (the one plain version source); `ROTKEEPER_VERSION` does not override a bump.
2. **Semver Calculation**
   - `--patch` increments the patch segment (`0.5.1` → `0.5.2`), `--minor` increments minor and zeroes patch (`0.5.1` → `0.6.0`), `--major` increments major and zeroes the rest (`0.5.1` → `1.0.0`), and `--to X.Y.Z` sets an explicit semver version. Exactly one selector is required.
3. **Canonical Version Update**
   - Writes the new version to `bones/config/version`; scripts, dispatcher output, release names, and tests pick it up automatically.
4. **Living Buildlog Injection**
   - Appends the message and timestamp directly into the `road-to-bones/index.md` buildlog.
5. **Changelog Append**
   - Adds the new version entry to the root `CHANGELOG.md`.
6. **Git Commit (optional)**
   - With `--commit`, stages the version file, changelog, and roadmap, then commits with a standardized `bump: [version] - [message]` commit message. `--dry-run` previews everything without writing.

## 🛣️ Navigation
- [Scripts Index](index.html)
- [Bones Home](../index.html)

<!--
Limerick:
The version was stuck in the past,
And updating by hand was a task.
But bump ran the string,
Changed every last thing,
And committed the code really fast.
-->

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-07-04T15:41:00Z -->


### Bones of the Code
A mindless automaton dedicated to making numbers go up. It integrates with Python3 to bump patch versions and automatically commits the results. It's the bureaucratic equivalent of a necromancer padding their body count.

### Restless Spirits
Running this in a dirty Git tree will indiscriminately swallow your uncommitted sins into the bump commit. Worse, if tied to a CI pipeline, it can easily enter a frenzied loop of automated commits on failure, spamming your repository with endless, meaningless bumps until the heat death of the universe.

### Ritual Warnings
Never invoke this ritual in a dirty working directory. If you attach this to an automated pipeline, ensure you have safeguards against infinite commit loops, or face the wrath of the repository maintainers.
## Ritual History
<!-- DIP-HISTORY-EXTRACTED: 2026-07-23T10:54:47Z -->

*Not found: no changelog/history entries matching `rc-bump.sh`.*
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
<!-- DIP-HELP-EXTRACTED: 2026-08-12T12:26:46Z -->

```text
rc-bump.sh — Explicit semver version bump

Usage:
  rotkeeper.sh bump [--major|--minor|--patch|--to X.Y.Z] -m MESSAGE [options]

Options:
  --major          Bump major segment: 0.5.1 -> 1.0.0
  --minor          Bump minor segment: 0.5.1 -> 0.6.0
  --patch          Bump patch segment: 0.5.1 -> 0.5.2
  --to VERSION     Set an explicit semver-style version (X.Y.Z)
  --message, -m MSG  Update message recorded in CHANGELOG.md and the roadmap
  --commit         Stage changes and commit them to git
  --dry-run        Preview changes without saving or committing
  --verbose        Detailed output
  --help, -h       Show help
  --version, -v    Show version and quit

Exactly one of --major, --minor, --patch, or --to is required.
```
