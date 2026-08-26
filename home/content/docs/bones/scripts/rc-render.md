---
title: "🖨️ rc-render.sh Reference"
slug: rc-render
target_file: "bones/scripts/rc-render.sh"
date: "2026-08-26"
template: "rotkeeper-doc.html"
status: "active"
version: "0.7.0"
author: "Rotkeeper Ritual Council"
project: "Rotkeeper"
description: "The core render ritual: plans and executes Oliver renders of every content source into themed HTML pages under output/, pruning stale pages and recording a manifest."
tags:
  - rotkeeper
  - scripts
  - rendering
  - oliver
---

# 🎨 rc-render.sh

<!-- The sacred rite of tomb rendering -->
**Script Path:** `bones/scripts/rc-render.sh`

## Overview

`rc-render.sh` backs the `render` dispatcher command — the beating heart of the pipeline. Every `.md`, `.textile`, and `.cook` source under `CONTENT_DIR` is planned and rendered through Oliver into an HTML page at the mirrored path under `OUTPUT_DIR`.

The pass, in order:

1. **Renderer gate** — Oliver is the only renderer (pandoc was removed and is refused by name). The binary is resolved via `rk_oliver_preflight` (`RK_OLIVER_BIN` override, then `PATH`); failure aborts with copy-pasteable diagnosis and a pointer to `preflight`.
2. **Template resolution** — `default_template` from `rotkeeper.yaml`; if unset, the first template in `TEMPLATE_DIR` is used with a `[WARN]`; no templates at all is fatal.
3. **Source discovery** — NUL-delimited walk of `CONTENT_DIR` using the GNU-find-safe helper (BSD find + yq can segfault on macOS). With `render_system_docs: false` in config, the internal `docs/`, `messages/`, and `help/` subtrees are pruned from user space.
4. **Output mapping & collision check** — each source maps to `$OUTPUT_DIR/<rel-path>.html`; two sources competing for one page basename (`foo.md` vs `foo.textile`) is a fatal error, not a silent overwrite.
5. **Stale-page pruning** — HTML files in `output/` that no longer map to any source are deleted, but *only* when the tree carries the `.rotkeeper-generated` ownership marker; an unmarked tree is refused with a warning instead.
6. **Asset sync** — delegates to `rc-assets.sh` so every rendered page's relative asset links resolve (real runs only; `--dry-run` stays non-mutating).
7. **Oliver plan + adapter batch** — `oliver plan` emits a TSV of render jobs which `rc-oliver-adapter.sh` executes page by page (frontmatter stripping, template application, link rewriting). Adapter failures surface the first underlying Oliver error line plus hints (including the XHTML raw-HTML rule) as terminal markers.
8. **Manifest & summary** — every expected output is recorded into `bones/manifest.txt` via `oliver manifest --add`; the run ends with a duration/warning-count marker and re-stamps the output ownership marker.

## CLI Usage

```bash
rotkeeper.sh render [options]

# Options:
#   --renderer NAME  Select renderer: oliver (the only supported value)
#   --dry-run        Preview without invoking the adapter or writing output
#   --verbose        Show detailed logs and per-page progress
#   --help, -h       Show usage help

# Examples:
bash rotkeeper.sh render
RK_OLIVER_BIN=/path/to/oliver bash rotkeeper.sh render --renderer oliver
```

### Environment assumptions

- **Reads:** `RK_RENDERER` (default `oliver`), `RK_OLIVER_BIN`, `INPUT_FORMAT`, `RENDER_PROFILE`; config keys `default_template` and `render_system_docs`; requires the canonical path set (`CONTENT_DIR`, `OUTPUT_DIR`, `TEMPLATE_DIR`, `META_DIR`, …).
- **Writes:** the HTML tree under `OUTPUT_DIR` (via the adapter), `bones/manifest.txt`, batch/bookkeeping files under `TMP_DIR`, per-run logs under `LOG_DIR`; refreshes the `.rotkeeper-generated` marker.
- **CWD:** none — sources and outputs resolve against canonical roots.

## Dangerous operations

- **Deletes stale rendered pages** under `OUTPUT_DIR` — gated on the `.rotkeeper-generated` marker proving the tree is machine-produced; unmarked trees are never pruned.
- Delegates destructive asset pruning to `rc-assets.sh` (same ownership-marker gate).
- Appends to `bones/manifest.txt`; a failed `oliver manifest --add` aborts the run rather than silently desyncing the ledger.
- Source-basename collisions abort the whole render up front, protecting the output tree from nondeterministic overwrites.

## 🛣️ Navigation
<!-- Quick navigation links -->
- [Scripts Index](index.html)
- [Render Reference](rc-render.html)
- [Bones Home](index.html)

<!--
Limerick 1:
A chorus of oliver calls in sync,
rc-render fills each HTML link.
With logs signed in time,
And parallel rhyme,
It crafts each tomb page in a blink.

Limerick 2:
In Markdown crypts of silent gloom,
rc-render breathes each page to bloom.
It logs every start,
And edges apart,
Leaving no page in pending doom.
-->

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-08-12T02:18:17Z -->


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

## Ritual History
<!-- DIP-HISTORY-EXTRACTED: 2026-07-23T10:54:47Z -->

- - Improve rc-render.sh error handling during template fallback.
- - Added parallel processing to rc-render.sh.
- - Strip frontmatter overrides and fix rc-render.sh to use rotkeeper.yaml
- - Fix template parsing bug in rc-render.sh using yq
- - Ensure rc-render.sh outputs proper HTML with valid tags.
- `CHANGELOG.md` records parallel `rc-render.sh` processing, smaller `rc-pack.sh`

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
