---
title: "🩺 rc-status.sh Reference"
slug: rc-status
target_file: "bones/scripts/rc-status.sh"
date: "2026-08-26"
template: "rotkeeper-doc.html"
status: "active"
version: "0.5.1"
author: "Rotkeeper Ritual Council"
project: "Rotkeeper"
description: "Read-only health snapshot across environment, script health, RAG exports, releases, recent tombs, content pulse, render freshness, and config — with --json and --short modes."
tags:
  - rotkeeper
  - status
  - audit
  - diagnostics
---

# 🩺 rc-status.sh

**Script Path:** `bones/scripts/rc-status.sh`

## Overview

`rc-status.sh` backs the `status` dispatcher command: a read-only diagnostic sweep for pre-deploy audits, post-pack confirmation, or ritual postmortems. It never mutates the workspace (its only write is its own log file).

The report walks eight sections:

1. **Environment** — canonical version and where it came from (`bones/config/version` vs `ROTKEEPER_VERSION` override), CWD, git branch and commit.
2. **Script Health** — syntax checks across every `rc-*.sh` plus the dispatcher.
3. **RAG Exports** — which binder artifacts exist under `bones/book-reports/`.
4. **Releases** / **Recent Tombs** — what has been shipped and archived lately.
5. **Content Pulse** — source counts by format (markdown/textile/cook).
6. **Render Freshness** — newest-source vs newest-HTML mtime comparison: `✓ [OK] output is current`, `✗ [STALE] content has changed since last render`, or `[EMPTY] no rendered output found`.
7. **Config Summary** — project/author/version/template/input-format/license from `rotkeeper.yaml`.

Output modes:

- **Default** — human-readable headed report with TTY color (respects `NO_COLOR`); explicitly restores the caller's stdout/stderr after shared initialization so the report is visible even in quiet mode.
- **`--short`** — one line: `rotkeeper <version> | <pages> | <freshness> | <branch>`.
- **`--json`** — one machine-readable JSON object with the same sections.

## CLI Usage

```bash
rotkeeper.sh status [--json | --short] [options]

# Options:
#   --json         Emit a machine-readable JSON report
#   --short        One-line summary (version | pages | freshness | branch)
#   --dry-run      No-op flag accepted for contract consistency
#   --verbose      Detailed output
#   --help, -h     Show usage help
```

### Environment assumptions

- **Reads:** version file, git metadata, `CONTENT_DIR`, `OUTPUT_DIR`, `ARCHIVE_DIR`, `BOOK_REPORT_DIR`, `CONFIG_DIR/rotkeeper.yaml`; requires `bash`, `jq`, `yq` v4.
- **Writes:** nothing except a per-run log under `LOG_DIR`.
- **CWD:** none; git context is read from the repository.

## Dangerous operations

None. The ritual is strictly read-only over workspace state — safe to run at any time, including mid-pipeline.

---

<!-- 🎴 Limerick 1:
To query the bones with a glance so wise,
rc-status lets no secret disguise.
It shows you the state,
Before it’s too late,
And warns of decays in disguise.
-->

<!-- 🎴 Limerick 2:
In the hush of the script’s midnight tune,
status reveals what lurks in the tomb.
With version in line,
And logs all in time,
It guides your next ritual by noon.
-->

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-07-04T15:41:00Z -->


### Bones of the Code
The physician examining a corpse. It attempts to provide diagnostics and status reports by probing the repository and log files.

### Restless Spirits
If Git is not installed, it panics like a lost child. If the logs are empty, it assumes everything is perfectly fine, completely blind to the fact that the logging daemon might have silently crashed days ago.

### Ritual Warnings
Do not mistake silence for health. An empty log often means the patient is already dead.

## Ritual History
<!-- DIP-HISTORY-EXTRACTED: 2026-07-23T10:54:47Z -->

*Not found: no changelog/history entries matching `rc-status.sh`.*

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
