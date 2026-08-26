---
title: "🧱 rc-env.sh Reference"
slug: rc-env
target_file: "bones/scripts/rc-env.sh"
date: "2026-08-26"
template: "rotkeeper-doc.html"
status: "active"
version: "0.5.1"
author: "Rotkeeper Ritual Council"
project: "Rotkeeper"
description: "Canonical environment bootstrap: derives root-relative paths, parses the active layout style and renderer toggles, and exports the shared Rotkeeper environment."
tags:
  - rotkeeper
  - scripts
  - bootstrap
  - shared
---

# 🧱 rc-env.sh

**Script Path:** `bones/scripts/rc-env.sh`

## Overview

`rc-env.sh` is the canonical environment loader for the whole ritual system. It is **sourced, never executed**: rituals reach it through `rk_load_env` in `rc-utils.sh`, which sources this file and then validates what it produced (`strict`) or tolerates a half-initialized tree (`bootstrap`). On its own it performs no work beyond variable derivation.

Responsibilities, in order:

1. **Root-relative path derivation.** `ROOT_DIR` is resolved from `BASH_SOURCE` (two levels above `bones/scripts/`), never from the caller's CWD. All structural bones directories (`BONES_DIR`, `SCRIPT_DIR`, `CONFIG_DIR`, `LOG_DIR`, `TMP_DIR`, `ARCHIVE_DIR`, `RELEASE_DIR`, `REPORT_DIR`, `BOOK_REPORT_DIR`, `META_DIR`) hang off that root.
2. **Layout parsing.** Configuration is read from `bones/config/rotkeeper.yaml`, falling back to a root-level `config/rotkeeper.yaml` for flat trees. With no serialized `paths` block, layout-dependent directories are computed from `layout_style`: `crypt` (`home/content`, `bones/templates`, `home/assets`, `output`), `busy` (`home/content`, `templates`, `assets`, `output`), or `sterile` (`src/content`, `config/templates`, `src/assets`, `dist`). `DOCS_DIR`, `HELP_DIR`, and `WEB_DIR` derive from the content/output directories.
3. **Cached-path reuse with relocation hardening.** When a `paths` block exists and its saved `ROOT_DIR` matches the freshly derived root, the cached values are exported as-is. If the repository has been moved, the cache is invalidated with a `[WARN]` and paths are recomputed from the active layout.
4. **Renderer toggles.** `INPUT_FORMAT` (`markdown` | `textile` | `cooklang`) and `RENDER_PROFILE` (`html` | `xhtml`) are read from config with safe defaults; unsupported values emit `[WARN]` and fall back to `markdown`/`html`. These flow into every Oliver invocation via the adapter and preflight.

An idempotency guard (`ROTKEEPER_ENV_LOADED`) makes repeated sourcing within one shell a no-op for the same repository root, so nested script-to-script calls cannot clobber a validated environment mid-ritual.

### Environment assumptions

- **Reads:** `ROTKEEPER_ENV_LOADED` and `FORCE_ENV_RELOAD` (guard controls — the latter is deliberately set by `rc-init.sh` after rewriting the path cache; do not set it elsewhere without a specific reason), plus `layout_style`, `input_format`, `render_profile`, and any `paths` block from `rotkeeper.yaml`.
- **Exports:** the full canonical variable set — `ROOT_DIR`, `BONES_DIR`, `OUTPUT_DIR`, `CONTENT_DIR`, `ASSETS_DIR`, `DOCS_DIR`, `HELP_DIR`, `LOG_DIR`, `TMP_DIR`, `CONFIG_DIR`, `ARCHIVE_DIR`, `RELEASE_DIR`, `REPORT_DIR`, `BOOK_REPORT_DIR`, `SCRIPT_DIR`, `TEMPLATE_DIR`, `META_DIR`, `WEB_DIR`, `LAYOUT_STYLE`, `INPUT_FORMAT`, `RENDER_PROFILE` — and flips `ROTKEEPER_ENV_LOADED=true`.
- **Dependencies:** `yq` (mikefarah v4 syntax) whenever a config file is present.
- **CWD:** none. Every path is anchored to the script's own location; callers may invoke rituals from any directory.

## Dangerous operations

No writes or deletions happen here — but this file is indirectly authoritative for every destructive ritual, because they all act inside the boundaries it defines:

- A wrong-root derivation would silently redirect every later ritual; the idempotency guard (keyed on `ROOT_DIR`) and relocation-based cache invalidation are the mitigations. Treat both as load-bearing.
- A corrupted or partially written `paths` block is fatal downstream: strict validation exits rather than guessing. `rc-init.sh` writes the block in a single `yq` transaction specifically so a crash cannot produce that state.

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-07-04T15:41:00Z -->


### Bones of the Code
The fragile foundation upon which this whole cursed architecture rests. It loads environment variables and attempts to establish 'safety bounds', as if anything here is truly safe.

### Restless Spirits
Sourcing dynamic shell scripts is basically inviting vampires in through the front door. If `ROOT_DIR` is unset or accidentally evaluates to `/`, the rest of the scripts will gladly unleash their destructive tendencies on the entire filesystem.

### Ritual Warnings
Never trust the environment. Validate `ROOT_DIR` as if your life depends on it, because the lifespan of your filesystem certainly does.

## Ritual History
<!-- DIP-HISTORY-EXTRACTED: 2026-07-23T10:54:47Z -->

- - Optimize rc-env.sh variable resolution order.
- - Remove redundant subshells from rc-env.sh.
- - Optimize rc-env.sh subshell parsing and harden sidecar path traversal boundaries
- - Optimize rc-env.sh to prevent unnecessary fork subshells.
- - streamlined `rc-dip.sh` parsing, and removal of redundant `rc-env.sh`
- - stitching in `rc-dip.sh`, and revised `rc-env.sh` resolution order.
- - Sidecar path-traversal boundaries were hardened and `rc-env.sh` subshell parsing

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
