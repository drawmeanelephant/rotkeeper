---
reference_contract: rotkeeper.command-reference.v1
title: rc-render.sh
slug: rc-render
target_file: bones/scripts/rc-render.sh
template: rotkeeper-doc.html
status: active
version: 0.8.1
author: Rotkeeper DIP
project: Rotkeeper
description: Render Markdown, Textile, and Cooklang sources into themed HTML using Oliver.
---

# rc-render.sh

## Overview

Render Markdown, Textile, and Cooklang sources into themed HTML using Oliver.

Source: `bones/scripts/rc-render.sh`.

## Usage

```bash
rotkeeper.sh render [options]
```

## Options

```text
--renderer NAME  Select renderer: oliver (the only supported renderer; pandoc was removed)
--dry-run        Preview actions without invoking renderer
--verbose        Show detailed logs
--help, -h       Show this help message and exit
--version, -v    Show script version and quit
```

## Examples

```bash
bash rotkeeper.sh render                                            # Render all content
bash rotkeeper.sh render --dry-run                                  # Preview without rendering
RK_OLIVER_BIN=/path/to/oliver bash rotkeeper.sh render --renderer oliver
```

## Exit codes

```text
0    Success
1    Render or validation failure
```

## Reads and writes

**Environment:** reads BONES_DIR, CONFIG_DIR, CONTENT_DIR, DOCS_DIR, DRY_RUN, INPUT_FORMAT, LOG_DIR, LOG_FILE, META_DIR, OLIVER_BIN, OUTPUT_DIR, QUIET, RK_OLIVER_BIN, RK_RENDERER, ROOT_DIR, SCRIPT_DIR, TEMPLATE_DIR, TMP_DIR, VERBOSE, VERSION (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.

**Working directory:** No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.

**Inputs and outputs:** discovers `.md`, `.textile`, and `.cook` sources under `CONTENT_DIR` with NUL-delimited paths, plans a TSV batch with Oliver, and executes the adapter to write mirrored HTML under `OUTPUT_DIR`.
Oliver discovery uses `RK_OLIVER_BIN` then `PATH` and the shared live preflight. Theme registry/default-template resolution chooses the site template; per-page metadata can override it. Missing templates and source-basename collisions abort the render.
With `render_system_docs: false`, discovery excludes `docs`, `messages`, and `help` directories. Stale pages and assets are pruned only from an output tree marked `.rotkeeper-generated`; real runs delegate asset synchronization.
Each output is recorded through `oliver manifest --add` in `bones/manifest.txt`. Failures abort rather than desynchronize the ledger. Scratch files and warning accumulators live under `TMP_DIR`; logs summarize duration and warnings. Dry-run does not execute the adapter or publish output.

## Side effects

- **write:** appends the output entry to `bones/manifest.txt` via `oliver manifest --add`
- **write:** filters the plan into a sibling scratch file,
  then replaces the batch TSV without changing the original row bytes.
- **delegated:** rc-oliver-adapter.sh renders HTML into output/ and
  writes per-run logs under bones/logs plus warning files under bones/tmp
- **delete:** the structured channel is consumed; drop it so a
  stale file can never feed a later run.

## Notes
<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->

### Design

Discovers Markdown, Textile, and Cooklang sources under the active `CONTENT_DIR`, checks output-basename collisions, obtains an Oliver TSV plan, and delegates page generation to `rc-oliver-adapter.sh`. Real runs synchronize assets and record rendered output paths in `bones/manifest.txt` through Oliver. Rendering writes mirrored `.html` pages under `OUTPUT_DIR`; tarball packaging belongs to pack, not render.

### Limits

Oliver is the only supported renderer. Discovery uses `RK_OLIVER_BIN` before PATH and includes a live smoke render. The theme-registry default precedes the legacy default-template key; an unavailable default falls back to the first sorted top-level HTML template. The adapter checks canonical source, output, template, and metadata boundaries. Only an existing per-page template within the template boundary replaces the planned template. `.textile` and `.cook` extensions override the configured source format; source frontmatter can override the site HTML/XHTML profile.

### Cautions

Stale HTML is pruned only from an output tree carrying `.rotkeeper-generated`; pruning and asset synchronization precede the adapter, so a failed batch is not a transactional rollback. `render_system_docs: false` excludes directories named docs, messages, or help from local discovery and filters Oliver's whole-tree plan before the adapter runs. Explicit false is preserved rather than passed through yq's default operator. A generated tree's previously rendered product-help pages are pruned on a real user-only build. XHTML requires a suitable wrapper and can fail on raw HTML. Dry-run skips the adapter, output writes, pruning, asset synchronization, and manifest updates, but still invokes Oliver preflight and plan and writes logs and temporary planning files.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

### [0.4.0.4] - 2026-07-01

- Improve rc-render.sh error handling during template fallback.

### [0.4.0.5] - 2026-07-01

- Added parallel processing to rc-render.sh.

### [0.3.0.14] - 2026-06-15

- Strip frontmatter overrides and fix rc-render.sh to use rotkeeper.yaml

### [0.3.1.4] - 2026-06-22

- Fix template parsing bug in rc-render.sh using yq

### [0.4.0.3] - 2026-06-30

- Ensure rc-render.sh outputs proper HTML with valid tags.
