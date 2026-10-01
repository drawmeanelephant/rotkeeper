---
reference_contract: rotkeeper.command-reference.v1
title: rc-oliver-adapter.sh
slug: rc-oliver-adapter
target_file: bones/scripts/rc-oliver-adapter.sh
template: rotkeeper-doc.html
status: active
version: 0.8.1
author: Rotkeeper DIP
project: Rotkeeper
description: |-
  Pure Bash batch adapter for Oliver renderer.
  Zero Python requirement. Enforces path boundaries and
  orchestrates Oliver `meta`/`render`/`wrap` for frontmatter,
  link rewriting, and template interpolation.
---

# rc-oliver-adapter.sh

## Overview

Pure Bash batch adapter for Oliver renderer.
Zero Python requirement. Enforces path boundaries and
orchestrates Oliver `meta`/`render`/`wrap` for frontmatter,
link rewriting, and template interpolation.

Source: `bones/scripts/rc-oliver-adapter.sh`.

## Usage

Not documented in the script help block. Consult the source; no command behavior is inferred.

## Options

Not documented in the script help block. Consult the source; no command behavior is inferred.

## Examples

Not documented in the script help block. Consult the source; no command behavior is inferred.

## Exit codes

Not documented in the script help block. Consult the source; no command behavior is inferred.

## Reads and writes

**Environment:** reads INPUT_FORMAT, RENDER_PROFILE, SCRIPT_DIR, TEMPLATE_DIR, TMP_DIR, VERSION (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.

**Working directory:** No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.

**Inputs and outputs:** internal batch worker invoked by render, not a dispatcher command. Reads a TSV manifest with source/destination/template/assets-root/sidecar/binary/layout/flag fields per row; rejects paths outside content/output/template/meta boundaries and unavailable renderer binaries.
Oliver meta extracts frontmatter; sidecar metadata overrides page fields. Source extension selects Textile/Cooklang over the configured input default. Per-page render_profile overrides the site HTML/XHTML profile; invalid or escaping templates abort.
Oliver render produces the body and Oliver wrap applies the template with merged metadata and link rewriting. Writes pages only under OUTPUT_DIR and short-lived metadata/body/error scratch files under TMP_DIR, plus warning accumulators keyed by RK_RENDER_ID.
Failures stop the batch with the underlying error and XHTML raw-HTML guidance when applicable. Manifest dry-run rows skip page writes. See `home/content/docs/oliver-contract.md`.

## Side effects

- **write:** captures oliver meta JSON into a bones/tmp scratch file
- **delete:** removes the doc-meta scratch file
- **write:** captures sidecar oliver meta JSON into a bones/tmp scratch file
- **delete:** removes the soul-meta scratch file
- **write:** creates bones/tmp and pre-cleans per-page body/err scratch files
- **delete:** removes stale per-page body/err scratch files before rendering
- **write:** renders the body HTML snippet into a bones/tmp scratch file; stderr captured alongside
- **delete:** removes per-page scratch files on render failure (no output page is written)
- **write:** appends warnings to the shared bones/tmp warning list for the batch
- **write:** accumulates the per-page warning count into the shared batch tally under bones/tmp
- **delete:** removes the stderr scratch file after warnings are harvested
- **write:** duplicates the body HTML into the rewrite-stage scratch file
- **write:** creates the page's output directory and writes the final HTML into output/
- **delete:** removes the partial output page and wrap scratch files on failure
- **delete:** removes the wrap meta and stderr scratch files on success
- **delete:** removes the body/rewrite scratch files for this page

## Notes
<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->

No sidecar notes are documented for `bones/scripts/rc-oliver-adapter.sh`.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

### [0.5.3] - 2026-08-13

- Replaced the Apex renderer with [Oliver](https://github.com/drawmeanelephant/oliver): the adapter (`rc-apex-adapter.sh` → `rc-oliver-adapter.sh`) now drives `oliver render --from markdown` (stdin → stdout body HTML, stderr = warnings) and strips a leading YAML frontmatter block before the Markdown reaches Oliver, a pure CommonMark renderer; the environment override is `RK_OLIVER_BIN` (was `RK_APEX_BIN`), and the authoritative contract moved from `apex-contract.md` to `oliver-contract.md`.
