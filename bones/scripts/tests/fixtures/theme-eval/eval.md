---
title: "Theme Evaluation Fixture — Longform & Primitives Stress Test"
description: "Headings H1–H6, tables, code, blockquotes, lists, warnings, metadata — CommonMark-safe"
author: "Rotkeeper Fixture Harness"
date: "2026-08-27"
template: "theme-brutal.html"
palette: "mac"
subtitle: "Every renderable primitive through every theme"
tags:
  - fixture
  - theme-eval
  - template-contract-v2
asset_meta:
  name: "eval.md"
  version: "0.7.0"
  author: "Fixture Harness"
  project: "Rotkeeper"
  tracked: true
  license: "All Rights Reserved"
---

# Heading 1 — The Necropolis Reads

This is a long paragraph designed to test measure and vertical rhythm at roughly sixty to seventy-five characters per line. Rotkeeper's reading-first themes must keep line length constrained, spacing even, and contrast legible whether the palette is phosphor green on black, macOS Terminal graphite, or PowerShell blue. The same body will render through every theme in the gallery, and the fixture lives beside `oliver-smoke` under `bones/scripts/tests/fixtures/theme-eval/`.

A second paragraph with **strong emphasis**, *emphasis*, `inline code`, and a [relative link](my-first-page.md) plus an [external link](https://example.com) ensures link rewriting, escaping, and inline parsing remain correct deposit. Cross-format sources rewrite too: a [textile link](docs/textile-guide.textile) and a [cooklang link](../recipes/gravediggers-pie.cook) must both land on `.html`. Escapable characters: `& < > " '` must be escaped in titles and descriptions but not in `$body$`.

## Heading 2 — Lists, Quotes, and Structure

### Heading 3 — Tight and Loose Lists

Tight list:

- First item with a [fragment link](other.md#section-2)
- Second item with code `rk_canonical_path`
- Third — nested:
  - nested 1
  - nested 2 with **bold**

Loose list:

- Keeps breathing room between items.

  Second paragraph inside first item.

- Second loose item.

Ordered, mixed depth:

1. Step one — run `bash rotkeeper.sh preflight`
2. Step two — `bash rotkeeper.sh render`
   1. Nested ordered
   2. Another nested
3. Step three

#### Heading 4 — Blockquotes and Warnings

> Keep the dead quiet at night. A blockquote must not collapse vertical rhythm, and must remain readable on narrow viewports. Repeated to check margin stacking.

> Second blockquote — with **bold** and `code` inside.

Standard warning pattern (as used in docs):

> **Note:** This is a note/warning block — check that code legibility holds inside.

##### Heading 5 — Deep Nesting

A fifth-level heading exercises the descending heading scale that docs-style outlines produce. Most themes stop styling at h4; this level must still render legibly from the browser default rather than collapsing into body text.

###### Heading 6 — Floor of the Outline

The sixth level is the deepest CommonMark heading. It must remain distinguishable from body copy and from h5, even where a theme deliberately mutes it.

## Tables — GFM with Alignment and Escapes

Table tests cover the GFM pipe table surface that Oliver ships (alignment colons, escaped pipes):

| Left align | Center align | Right align | Escaped \| pipe |
| :--- | :---: | ---: | :--- |
| `code` | **bold** | 42 | cell with \| pipe |
| long text that should wrap and test cell padding | centered text | 99 | a\|b\|c |

Wide table to test overflow on narrow viewports:

| Command | Purpose | Flags | Example |
| :--- | :--- | :--- | :--- |
| `render` | Render markdown tombs into HTML | `--dry-run`, `--verbose` | `bash rotkeeper.sh render --dry-run` |
| `scan` | Audit manifest vs files | `--json-only` | `bash rotkeeper.sh scan` |
| `links` | Audit rendered links | `--json` | `bash rotkeeper.sh links --json` |
| `showcase` | Scaffold theme previews | — | `bash rotkeeper.sh showcase` |

## Code Fences — With and Without Info Strings

Fenced block with info string (should become `language-*` class):

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
rk_canonical_path "$OUTPUT_DIR/docs/page.html"
```

Fenced block without info string:

```
plain code block — check wrapping, scroll, and contrast on dark palettes
second line with a very long line that should trigger overflow handling rather than breaking the layout at narrow widths, repeating to test wrapping behavior at 60-75ch
```

Inline `code` inside prose and `` `code` `` span checks.

## Images, Metadata, and The Long Paragraph

Image (local asset path, must not be rewritten to `.html`):

![Alt text for image](assets/images/placeholder.png)

Second longform paragraph to re-test measure after tables/code: The haunted identity work (#251) defines dividers, lore blocks, and ornament as shared primitives rather than copy-pasted CSS. This paragraph must remain legible at 768px and 375px widths, with table and code fences not exploding the layout. The `theme-brutal` palette `mac` here should still pass the contrast audit (#258).

Horizontal rule is open — the divider primitive will be visible below if templates use a shared divider style. Expect minimal drift between `theme-spooky-dark.html` and `theme-textpattern.html` after the skeleton standardization (#245).

---

## Frontmatter Contract Check

This fixture exercises the template dialect from `oliver-contract.md`: the typed metadata tokens (`title`, `description`, `author`, `date`, `palette`), the v2 extended tokens (`version`, `subtitle`, `tags`, `asset_meta`), the raw `$assets_root$`/`$body$` pair, and `$if$/$endif$` gating. Rendering through `theme-kawaii.html` (subset tokens) and `theme-brutal.html` (full set) should both succeed; unknown `$tokens$$` must pass through verbatim.

- `version` is adapter-injected from `bones/config/version` — footer stamps (`v$version$`) must read the current release, not frontmatter.
- `tags` joins as `fixture, theme-eval, template-contract-v2` — themes with a `$if(tags)$` footer slot show it; others omit cleanly.
- `asset_meta` serializes as `eval.md — 0.7.0 — Fixture Harness — Rotkeeper — All Rights Reserved` (name, version, author, project, license joined with ` — `, `tracked` never rendered).
- The v3 generic hook (#269): any extra scalar frontmatter key is interpolatable as `$field$`; `theme-necropolis.html`'s `page_type` is the reference consumer.
- Site navigation (#244) renders through the literal `<site-nav></site-nav>` placeholder, not an escaped token — themes without the slot are unaffected.
- `$warnings$` is reserved with no adapter feed yet; it substitutes empty.

- Keep CommonMark-safe: no task lists (`- [ ]`) that would render literally, no footnotes.
- Raw HTML is not present here — XHTML fail-closed (`error.RawHtmlNotXmlWellFormed`) is not exercised, keeping HTML vs XHTML bytes identical for this page.
