---
title: "📦 rc-release.sh Reference"
slug: rc-release
target_file: "bones/scripts/rc-release.sh"
date: "2026-08-26"
template: "rotkeeper-doc.html"
status: "active"
version: "0.5.1"
author: "Rotkeeper Ritual Council"
project: "Rotkeeper"
description: "Packages one canonical framework-distribution zip with an explicit allowlist, required spine, forbidden-path rules, and post-build archive verification."
tags:
  - rotkeeper
  - scripts
  - packaging
  - distribution
---

<!--
🎨 Sora Prompt:
"A conveyor belt in a dark factory dropping one heavy, perfectly sealed metal lockbox into a bottomless pit, stamped with a single canonical version."
-->

# 📦 rc-release.sh

<!-- The rite of distribution -->
**Script Path:** `bones/scripts/rc-release.sh`

## Overview

`rc-release.sh` backs `release <VERSION>`: it collapses every packaging model into **one canonical framework distribution zip** — dispatcher, bones system, templates, configuration, and project docs. A release is explicitly *not* a site-source archive or a full backup: author content outside the framework spine is out of contract, and caches/logs/temp/output/archives/reports/credentials are forbidden.

The pass:

1. **Staging** — the repository is rsynced into a per-run staging directory under `TMP_DIR` with strict exclusions (`.git/`, `.github/`, `.vscode/`, output, logs, tmp, the whole bones archive/report/book-report trees, `content/messages/`, `.DS_Store`, `*_temp.md`).
2. **Manifest generation** — the staged tree gets a generated `bones/config/release-manifest.txt`: version, model line, ruleset identifier, and the complete sorted entry list.
3. **Archive & verify** — the staged `rotkeeper/` tree is zipped to a temp name, `zip -T`-tested, then verified against **allowlist v1**: every entry must live under `rotkeeper/`; root-level entries must match an explicit allowlist; five spine entries are required (`rotkeeper.sh`, `rotkeeper.yaml`, `version`, `release-manifest.txt`, `rc-utils.sh`); forbidden prefixes (git, output, logs, tmp, archives, reports, book-reports, messages) and forbidden artifacts (`.env`, keys, `.pem/.p12`, `.pyc`, `id_rsa`, `.npmrc`, editor backups) fail the build.
4. **Install & cleanup** — only a fully verified archive is renamed into place at `$ARCHIVE_DIR/releases/rotkeeper-$VERSION.zip`. The EXIT/INT/TERM trap prunes staging through `rk_guard_delete`.

## CLI Usage

```bash
rotkeeper.sh release <VERSION> [options]

# Arguments:
#   VERSION       Semver-style version for the distribution name (e.g. 0.5.2)

# Options:
#   --dry-run     Preview the release without writing archives
#   --verbose     Detailed output
#   --help, -h    Show usage help
```

### Environment assumptions

- **Reads:** the whole repository tree (subject to exclusions); requires `ROOT_DIR` … `RELEASE_DIR` canonical paths.
- **Writes:** `bones/archive/releases/rotkeeper-$VERSION.zip` (installed atomically from a temp name) plus scratch space under `TMP_DIR`.
- **Dependencies:** `bash`, `rsync`, `zip`, `zipinfo`.
- **CWD:** none (staging-relative `cd` is internal).

## Dangerous operations

- **Overwrites any existing archive at the exact destination name** for the target version.
- Deletes its own staging directory in the exit trap — guarded by `rk_guard_delete` against `$TMP_DIR`, so a refused guard skips cleanup rather than deleting unsafely.
- Verification failures leave no artifact behind: the zip is installed only after integrity and allowlist checks pass.

## 🛣️ Navigation
- [Scripts Index](index.html)
- [Bones Home](../index.html)

<!--
Limerick:
The archives were growing too fat,
So one canonical coffin was sat.
The volatile dead,
Were left out instead,
And one versioned zip left the flat.
-->

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-07-23T10:54:47Z -->


### Bones of the Code
The merchant of death, packaging distribution zip files for the masses. It uses exclusion lists to decide what gets left behind in the crypt.

### Restless Spirits
The exclusion lists are a brittle defense. If a sensitive file gets created that doesn't match the hardcoded patterns, it will be happily zipped up and shipped to production. Its assumptions about the target environments are equally perilous.

### Ritual Warnings
Audit the exclusion lists regularly. Never assume that 'lite' means 'safe'—sensitive data will slip through if you aren't paying attention.

## Ritual History
<!-- DIP-HISTORY-EXTRACTED: 2026-07-23T10:54:47Z -->

*Not found: no changelog/history entries matching `rc-release.sh`.*

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
