---
target_file: "bones/templates/theme-fieldnotes.html"
template: "rotkeeper-doc.html"
status: "complete"
author: "Rotkeeper"
project: "Rotkeeper"
---

# theme-fieldnotes

Documentation for `bones/templates/theme-fieldnotes.html`.

## Overview
<!-- DIP-GENERATED-MARKER: Overview -->
Fieldnotes is a paper-and-ink HTML wrapper for readable articles and small
editorial sites. Its local stylesheet is `home/assets/css/theme-fieldnotes.css`.
The [Field Station](../../../field-station/index.html) is a small sample site
built with it.

## Usage
<!-- DIP-HELP-EXTRACTED: 2026-10-30T13:21:08Z -->

This file has no command-line interface. Select `theme-fieldnotes.html` in
page frontmatter or in the theme registry.
## Reads and writes
<!-- DIP-ENV-EXTRACTED: 2026-10-30T13:21:08Z -->

The template reads no files and writes no files itself. Oliver fills its
metadata and body slots during rendering; the adapter fills site navigation.
## History
<!-- DIP-HISTORY-EXTRACTED: 2026-10-30T13:21:08Z -->

Introduced with the Field Station example.
## Notes
<!-- DIP-SOUL-EXTRACTED: 2026-10-30T13:21:08Z -->


### Design

The Fieldnotes wrapper uses `css/theme-fieldnotes.css` for an editorial,
paper-and-ink reading layout. It provides one page title, optional description,
date and author, the configured site navigation slot, and the literal body.
Its footer includes the Rotkeeper version and optional asset metadata and tags.

The stylesheet uses the locally supplied Fira fonts with fallbacks, supports
small screens and wide tables or code, and provides visible keyboard focus.
The sample field journal lives under `home/content/field-station/`.

### Limits

The masthead and decorative circle are presentation, not site-specific data.
The wrapper is HTML, not an XHTML variant. It does not add scripts or fetch
fonts from a remote service.

### Cautions

Keep the `<site-nav></site-nav>` and `$body$` slots literal so the adapter can
insert configured navigation and rendered content. The `.field-list` styles
are optional and can be used for an editorial index.
