---
target_file: "bones/templates/theme-fieldnotes.html"
reviewed: "2026-10-30"
reviewed_against: "0.9.0"
---

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
