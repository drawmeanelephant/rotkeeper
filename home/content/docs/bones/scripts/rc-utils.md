---
reference_contract: rotkeeper.command-reference.v1
title: rc-utils.sh
slug: rc-utils
target_file: bones/scripts/rc-utils.sh
template: rotkeeper-doc.html
status: active
version: 0.8.1
author: Rotkeeper DIP
project: Rotkeeper
description: Shared Rotkeeper helper functions and runtime sanity wrappers
---

# rc-utils.sh

## Overview

Shared Rotkeeper helper functions and runtime sanity wrappers

Source: `bones/scripts/rc-utils.sh`.

## Usage

Not documented in the script help block. Consult the source; no command behavior is inferred.

## Options

Not documented in the script help block. Consult the source; no command behavior is inferred.

## Examples

Not documented in the script help block. Consult the source; no command behavior is inferred.

## Exit codes

Not documented in the script help block. Consult the source; no command behavior is inferred.

## Reads and writes

**Environment:** reads ARCHIVE_DIR, ASSETS_DIR, BONES_DIR, BOOK_REPORT_DIR, CONFIG_DIR, CONTENT_DIR, DEBUG, DOCS_DIR, DRY_RUN, HELP_DIR, INPUT_FORMAT, LOG_DIR, LOG_FILE, META_DIR, OLIVER_BIN, OUTPUT_DIR, QUIET, RELEASE_DIR, RENDER_PROFILE, REPORT_DIR, RK_OLIVER_BIN, ROOT_DIR, ROTKEEPER_VERSION, SCRIPT_DIR, TEMPLATE_DIR, TMP_DIR, VERBOSE, VERSION, WEB_DIR (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.

**Working directory:** No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.

**Inputs and outputs:** shared helper library, not a dispatcher command. Sourcing defines helpers and loads the version but does not load the layout; scripts call `rk_init_script`, which parses common flags, installs traps, loads/validates the environment, opens a run log, and saves stdout on fd 3.
Provides flag/help handling, log/run wrappers, dependency gates, strict/bootstrap layout validation, source/frontmatter/sidecar helpers, version loading, portable SHA-256/mtime/find helpers, Oliver preflight, and output-ownership markers.
Canonical-path and delete guards reject empty/root/escaping destructive targets; callers must not delete after a failed guard. Strict validation exits on relocation/cache/layout/readiness failures. Oliver preflight writes and deletes only its own scratch files; other helper effects depend on callers.
Reads `ROT_SKIP_ENV`, `ROTKEEPER_VERSION`, `VERSION_FILE`, common RK_* flag defaults, `NO_COLOR`, and `TERM`; rendered navigation reads configuration. Direct execution has a no-op placeholder main.

## Side effects

- **write:** appends each message to bones/logs/<ritual>-<ts>.log
- **write:** creates bones/tmp and the smoke doc/output/stderr scratch files
- **delete:** removes the smoke scratch files under bones/tmp
- **write:** creates the output tree if missing and drops/truncates its .rotkeeper-generated marker
- **write:** creates bones/logs and a new per-run log file (one per invocation)
- **write:** rebinds stdout/stderr so everything also lands in $LOG_FILE

## Notes
<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->

### Design

Shared Bash helper library rather than a dispatcher command. Sourcing defines helpers and loads the canonical version; `rk_init_script` handles flags, traps, environment validation, per-run logs, and a saved stdout descriptor. Supplies dependency checks, path and deletion helpers, frontmatter/sidecar access, template resolution, navigation generation, portable checksum/mtime/find selection, and live Oliver preflight.

### Limits

`parse_flags` recognizes common flags anywhere in the argument list and skips command-specific arguments; callers still parse their own options from the full list. `run` suppresses only commands routed through it during dry-run, not arbitrary caller writes. Normal commands retain strict cache, relocation, layout, boundary, and readiness checks; the cache may hold only the path keys init writes, each a one-line string inside the root. Only init uses the shared bootstrap: it ignores cached destinations, validates YAML and every derived destination canonically before writes, and strictly reloads after replacing the cache. Canonical bootstrap validation requires GNU `realpath -m` or `readlink -m`. Sidecar mapping rejects escaping destinations by returning `bones/meta/null.soul.md`.

### Cautions

Canonical-path helpers have different fallback behavior, so callers must use the appropriate guard rather than assume every helper fails closed. Destructive callers must honor a failed `rk_guard_delete` result. Cleanup runs without masking the original exit status; scripts can override it. Help exits before environment/log initialization. Other initialization, including dry-run, creates logs, and Oliver preflight creates and removes its own smoke files and invokes the renderer.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

### v0.2.6-dev

- Updated `rc-utils.sh` to:
  - Respect DRY_RUN with proper logging
  - Safely export logs to both stdout and $LOG_FILE
  - Make `trap_err` shell-safe for test invocation
