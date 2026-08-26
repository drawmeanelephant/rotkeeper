---
title: "🧩 rc-utils.sh Reference"
slug: rc-utils
target_file: "bones/scripts/rc-utils.sh"
date: "2026-08-26"
template: "rotkeeper-doc.html"
status: "active"
version: "0.5.1"
author: "Rotkeeper Ritual Council"
project: "Rotkeeper"
description: "Shared helper library sourced by every ritual: canonical environment loading, flag parsing, logging, dependency gates, path-safety guards, and portability shims."
tags:
  - rotkeeper
  - scripts
  - utils
  - shared
---

# rc-utils.sh

**Script Path:** `bones/scripts/rc-utils.sh`

## Overview

`rc-utils.sh` is the shared toolbox sourced by every `rc-*.sh` ritual. It is a library, not a ritual: executing it directly runs a placeholder `main` that does nothing. Sourcing it does not load the environment by itself — rituals call `rk_init_script`, which parses common flags, installs traps, and invokes `rk_load_env strict` (skipped only when `ROT_SKIP_ENV=true`).

What it provides:

- **Canonical environment loading** — `rk_load_env [strict|bootstrap]` sources `rc-env.sh`, then in `strict` mode asserts every layout-derived variable is set, re-validates `rotkeeper.yaml` as parseable YAML, and runs `validate_layout_alignment`. `bootstrap` mode tolerates an uninitialized tree (used by `init` before paths exist).
- **Layout validation** — `validate_layout_alignment` compares the cached `paths` block against freshly computed layout expectations, catching repository relocation and mid-flight layout changes with explicit `[ERROR]` + fix guidance.
- **Script bootstrap** — `rk_init_script NAME ARGS…` standardizes each ritual's prologue: default flags from `RK_DRY`/`RK_VERBOSE`/`RK_QUIET`/`RK_DEBUG`, common flag parsing, help dispatch, ERR/EXIT traps (`trap_err`/overridable `cleanup`), a timestamped log file under `LOG_DIR`, stdout preserved on fd 3 for `MARKER` lines, and quiet-mode redirection into the log.
- **Logging and execution** — `log LEVEL MESSAGE…` (levels `INFO`, `WARN`, `ERROR`, `DEBUG`, `DRY-RUN`, `MARKER`; `MARKER` always reaches the terminal, colorized unless `NO_COLOR` or `TERM=dumb`) and `run CMD…` (dry-run aware command wrapper).
- **Dependency gates** — `require_bins`, `require_yq_version` (mikefarah v4), `require_gawk_version` (GNU awk specifically — BSD awk is not a substitute), `require_sha256`.
- **Path safety** — `rk_canonical_path` (canonicalization that works when the leaf does not exist yet), `rk_canonical_or_raw` (lenient variant for not-yet-existing targets), `rk_guard_delete CANDIDATE BOUNDARY` (the fail-closed preflight every `rm -rf` site must pass), and `get_sidecar_path` (soul-sidecar mapping under `META_DIR` that flattens traversal attempts).
- **Portability shims** — `rk_sha256` (`sha256sum` → `shasum -a 256`), `rk_mtime` (GNU/BSD `stat`), `rk_find_command`/`rk_find_content` (prefers GNU find; NUL-delimited content discovery safe for arbitrary filenames), `rk_up_dirs`.
- **Frontmatter helpers** — `rk_strip_frontmatter`, `rk_frontmatter_field KEY FILE`, `has_frontmatter`, `get_yaml_key`.
- **Version loading** — `rk_load_version` reads `bones/config/version` (overridable by `ROTKEEPER_VERSION`), so the semver lives in exactly one place.
- **Renderer preflight** — `rk_oliver_preflight`: resolves Oliver via `RK_OLIVER_BIN` then `PATH`, asserts executability, and smoke-renders through the real CLI (honoring `INPUT_FORMAT`/`RENDER_PROFILE`) to prove the binary runs. Sets `OLIVER_BIN` on success.
- **Output ownership** — `mark_output_generated`/`output_is_generated` maintain the `.rotkeeper-generated` marker that proves an output tree was machine-produced before anything may prune it.

### Environment assumptions

- **Reads:** `ROT_SKIP_ENV`, `ROTKEEPER_VERSION`, `VERSION_FILE`, `RK_DRY`, `RK_VERBOSE`, `RK_QUIET`, `RK_DEBUG`, `NO_COLOR`, `TERM`, plus `RK_OLIVER_BIN`, `INPUT_FORMAT`, `RENDER_PROFILE`, and `TMP_DIR` inside the Oliver preflight. Strict mode requires the full canonical path set from `rc-env.sh`.
- **Sets:** `DRY_RUN`, `VERBOSE`, `QUIET`, `DEBUG`, `HELP`, `VERSION`, `SCRIPTNAME`, `LOG_FILE` (per-run log path), fd 3 (duplicate of original stdout).
- **CWD:** none — all self-location uses `BASH_SOURCE`.

## Dangerous operations

- `rk_guard_delete` exists to gate destructive deletes: it canonicalizes candidate and boundary (symlink-safe) and refuses empty candidates, `/`, and anything resolving outside the boundary. Callers must treat a non-zero return as "do not delete".
- `validate_layout_alignment` and strict loading `exit 1` on relocation mismatches, corrupted path caches, boundary escapes, or missing core directories — deliberate fail-closed behavior, not a bug.
- The library itself deletes nothing except its own Oliver smoke-render artifacts in `TMP_DIR`.

<!-- 🎴 Limerick 1:
In the shadows of scripts all combined,
rc-utils keeps helpers aligned.
With flags parsed so neat,
Logs and runs compete,
And errors are neatly defined.
-->

<!-- 🎴 Limerick 2:
When each script needs a guiding hand,
rc-utils will take a bold stand.
It checks and it logs,
Guards against clogs,
And lights up the whole Rotkeeper land.
-->

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-07-04T15:41:00Z -->


### Bones of the Code
The shared toolbox of rusty implements. It provides logging, color printing, and environment assertions for the rest of the scripts.

### Restless Spirits
Its attempts at portability often fall flat when encountering ancient or obscure shell environments. The 'robust' shell functions are one edge case away from a syntax error, especially when dealing with non-standard terminal emulators or deeply nested subshells.

### Ritual Warnings
Do not rely on these utilities in truly hostile environments. Their portability is an illusion maintained by sheer luck.

## Ritual History
<!-- DIP-HISTORY-EXTRACTED: 2026-07-23T10:54:47Z -->

- - Updated `rc-utils.sh` to:

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
