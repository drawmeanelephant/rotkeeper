---
reference_contract: rotkeeper.command-reference.v1
title: rc-env.sh
slug: rc-env
target_file: bones/scripts/rc-env.sh
template: rotkeeper-doc.html
status: active
version: 0.8.1
author: Rotkeeper DIP
project: Rotkeeper
description: Dynamic Environment Bootstrap — Portability Hardening
---

# rc-env.sh

## Overview

Dynamic Environment Bootstrap — Portability Hardening

Source: `bones/scripts/rc-env.sh`.

## Usage

Not documented in the script help block. Consult the source; no command behavior is inferred.

## Options

Not documented in the script help block. Consult the source; no command behavior is inferred.

## Examples

Not documented in the script help block. Consult the source; no command behavior is inferred.

## Exit codes

Not documented in the script help block. Consult the source; no command behavior is inferred.

## Reads and writes

**Environment:** reads ARCHIVE_DIR, ASSETS_DIR, BONES_DIR, BOOK_REPORT_DIR, CONFIG_DIR, CONTENT_DIR, DOCS_DIR, HELP_DIR, INPUT_FORMAT, LAYOUT_STYLE, LOG_DIR, META_DIR, OUTPUT_DIR, RELEASE_DIR, RENDER_PROFILE, REPORT_DIR, ROOT_DIR, SCRIPT_DIR, TEMPLATE_DIR, TMP_DIR, WEB_DIR (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.

**Working directory:** No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.

**Inputs and outputs:** internal environment library reached through `rk_load_env`, not a dispatcher command. Derives the canonical paths from `BASH_SOURCE` and configuration, exports the layout/renderer variables, and does not write files.
Reuses a paths cache only for the same root; relocation invalidates it with a warning. Crypt, busy, and sterile select their respective content/templates/assets/output paths. Unsupported input/profile values fall back to Markdown/HTML.
`ROTKEEPER_ENV_LOADED` makes repeated loading for the same root idempotent; `FORCE_ENV_RELOAD` is reserved for init after cache writes. Strict validation in rc-utils rejects corrupted caches or escaping paths.

## Side effects

No side effects are documented in script annotations.

## Notes
<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->

### Bones of the Code
The fragile foundation upon which this whole cursed architecture rests. It loads environment variables and attempts to establish 'safety bounds', as if anything here is truly safe.

### Restless Spirits
Sourcing dynamic shell scripts is basically inviting vampires in through the front door. If `ROOT_DIR` is unset or accidentally evaluates to `/`, the rest of the scripts will gladly unleash their destructive tendencies on the entire filesystem.

### Ritual Warnings
Never trust the environment. Validate `ROOT_DIR` as if your life depends on it, because the lifespan of your filesystem certainly does.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

### [0.4.0.4] - 2026-07-01

- Optimize rc-env.sh variable resolution order.

### [0.4.0.5] - 2026-07-01

- Remove redundant subshells from rc-env.sh.

### [0.4.0.2] - 2026-06-30

- Optimize rc-env.sh subshell parsing and harden sidecar path traversal boundaries

### [0.4.0.3] - 2026-06-30

- Optimize rc-env.sh to prevent unnecessary fork subshells.
