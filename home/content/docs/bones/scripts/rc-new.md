---
reference_contract: rotkeeper.command-reference.v1
title: rc-new.sh
slug: rc-new
target_file: bones/scripts/rc-new.sh
template: rotkeeper-doc.html
status: active
version: 0.8.1
author: Rotkeeper DIP
project: Rotkeeper
description: Scaffold a Markdown, Textile, or Cooklang source with YAML frontmatter.
---

# rc-new.sh

## Overview

Scaffold a Markdown, Textile, or Cooklang source with YAML frontmatter.

Source: `bones/scripts/rc-new.sh`.

## Usage

```bash
rotkeeper.sh new <file> [options]
rotkeeper.sh new --list
```

## Options

```text
--title "Title"        Override auto-derived title; skip slug-from-filename
--author "Name"        Override config-derived author
--tags "tag1,tag2"     Comma-separated tags; rendered as YAML list
--template "file.html" Override the configured default template
--description "text"   Frontmatter description field
--body "text"          Starting body content
--url "https://..."    A URL to embed in the document (creates source skeleton)
--subdir "path"        Directory under home/content/ to place the file
--soul                 Also scaffold sidecar bones/meta/<path>.soul.md
--list                 List available templates and exit
--dry-run              Preview actions without writing files
--verbose              Enable detailed debug logging
--help, -h             Show this help message and exit
--version, -v          Show script version and quit
```

## Examples

```bash
bash rotkeeper.sh new graveyard-shift                       # Simple scaffold at content root
bash rotkeeper.sh new ember-report --subdir journal         # Place under journal/
bash rotkeeper.sh new ember-report --title "Ember Report" --tags "news,ember" --dry-run
```

## Exit codes

```text
0    Success
1    Invalid usage or scaffold failure
```

## Reads and writes

**Environment:** reads BONES_DIR, CONFIG_DIR, CONTENT_DIR, DOCS_DIR, DRY_RUN, LOG_DIR, META_DIR, QUIET, ROOT_DIR, SCRIPT_DIR, TEMPLATE_DIR, TMP_DIR, VERBOSE (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.

**Working directory:** No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.

**Inputs and outputs:** creates one new `.md`, `.textile`, or `.cook` source under `CONTENT_DIR`; bare names get `.md`. No filename or `--list` lists templates, marking the configured default and palette support.
YAML fields include title, slug, and template; optional description, author, tags, and source_url are emitted when supplied. Multiline descriptions use a block scalar and tags use a quoted YAML list. Template selection uses the shared registry/default resolution.
Markdown gets a `#` heading, Textile an `h1.` heading, and Cooklang a sample recipe body without a heading. `--url` creates Source/Notes/Summary sections. `--soul` requests a sidecar through the traversal-guarded metadata mapping.
Filename/subdirectory traversal and destinations outside `CONTENT_DIR` are rejected. Existing content is never overwritten; existing sidecars are warned about and kept. Dry-run previews the scaffold without publishing files.

## Side effects

- **write:** creates the target directory under content/ if missing
- **write:** creates the new content page (frontmatter + body appended below);
  earlier existence check guarantees this never overwrites an existing file
- **write:** creates bones/meta/<rel>.soul.md sidecar scaffold

## Notes
<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->

### Design

Scaffolds one source under the active `CONTENT_DIR`, adding `.md` to bare names. Derives title and slug, resolves the default template, and writes optional author, description, tags, body, and source URL. Markdown and Textile receive format-specific headings; Cooklang gets a sample recipe when no body is supplied. No filename or `--list` lists available templates instead of creating content.

`--soul` uses the file-sidecar schema with a repository-relative target,
Design/Limits/Cautions headings, and null review fields. The content-relative
lookup path remains unchanged. Fill in and verify the notes before recording
a review date and version.

### Limits

Canonical destination checks reject parent traversal and paths outside the content boundary, and existing content files are refused. Titles, authors, tags, and single-line descriptions escape quotes and backslashes; multiline descriptions use a block scalar. Slugs are ASCII-oriented. The selected template name is written to frontmatter without checking whether that template exists; rendering has its own template checks.

### Cautions

`--soul` requests a mirrored metadata sidecar and preserves an existing sidecar with a warning. Newly scaffolded notes are author-editable context, not evidence that a source review has occurred. Source creation and sidecar creation are separate writes, so a sidecar failure does not roll back the content page. Dry-run skips source and sidecar publication but still loads the environment and writes bootstrap logs.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

No matching entries in CHANGELOG.md.
