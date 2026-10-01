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
- **delegated:** rc-oliver-adapter.sh renders HTML into output/ and
  writes per-run logs under bones/logs plus warning files under bones/tmp
- **delete:** the structured channel is consumed; drop it so a
  stale file can never feed a later run.

## Notes
<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->

### Bones of the Code
This incantation is the beating, black heart of the Rotkeeper engine, responsible for transmuting lifeless Markdown tombs into fully fleshed HTML horrors. It sweepingly traverses the content catacombs, forcefully applies Oliver templates to the restless spirits within, and ultimately entombs the resulting digital husks in a compressed `.tar.gz` archive for safe, eternal slumber.

* **Oliver (`oliver`)**: The primary golem summoned to bend Markdown into HTML.
* **Link Rewriting (`rc-oliver-adapter.sh`)**: Rewrites internal `.md` links to `.html` during compilation.
* **YAML frontmatter extractor (`yq`)**: Used to surgically extract template preferences from the heads of corpses.
* **Tarball Archiver (`tar`)**: Compresses the resulting HTML husks into `bones/archive/tomb-*.tar.gz`.
* **Template Directory (`TEMPLATE_DIR`)**: The morgue containing the HTML layouts (e.g., `theme-light.html`, `rotkeeper-blog.html`).
* **Manifest (`MANIFEST`)**: A ledger (`bones/manifest.txt`) tracking every soul successfully rendered.

### Restless Spirits
This script is a masterclass in bureaucratic necromancy. I deeply appreciate the brutal efficiency of ignoring `output/`, `bones/`, and `docs/` using `find -prune` rather than some weak, post-processing `grep` filter. The fallback logic for when a corpse forgets to specify a template—blindly grabbing the first template it stumbles across in the dark—is exactly the kind of callous indifference to human error that I respect in a good system. The fact that it calculates its own runtime duration is just the script gloating about how quickly it can process the dead.

### Ritual Warnings
* The most glaring vulnerability is its blind trust in Oliver's handling of user-provided Markdown. If a template name is cleverly manipulated in the frontmatter to traverse directories (e.g., `../../etc/passwd`), this ritual could inadvertently attempt to read outside the `TEMPLATE_DIR`.
* The fallback template selection is reliant on whatever file globbing decides is first; one day, it will grab a template meant for internal torture rather than public display.
* If `ROOT_DIR` or `OUTPUT_DIR` somehow become unassigned or point to `/`, the recursive `mkdir -p` and path string replacements (`${mdpath#"$PROJ_ROOT"/}`) might attempt to entomb the entire operating system.

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
