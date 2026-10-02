---
target_file: "bones/templates/theme-spooky-dark.html"
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

This HTML wrapper links `css/theme-spooky-dark.css`. It places the page title
in the document title, an H1 header, and an H2 article header, then inserts
`$body$` into `.entry-content`. Description, date, and author regions are
conditional. The footer includes the loaded version and optional asset
metadata and tags.

The site configuration selects this template as its default. See
[theme selection](../../themes.html),
[creating themes](../../creating-themes.html), and the
[Oliver token contract](../../oliver-contract.html).

### Limits

The wrapper has no palette hook, site-navigation slot, or script element.
The fixed `ROTKEEPER` user picture is marked `aria-hidden="true"`.
The footer contains fixed decorative text, not page metadata.

This is an HTML wrapper, not the XHTML variant.

### Cautions

The stylesheet must be available at the page-relative `$assets_root$` path.
`$body$` is a literal rendered fragment, not escaped metadata.

For XHTML output, use `theme-spooky-dark-xhtml.html` together with the XHTML
render profile. See the [XHTML guide](../../xhtml-profile.html).
