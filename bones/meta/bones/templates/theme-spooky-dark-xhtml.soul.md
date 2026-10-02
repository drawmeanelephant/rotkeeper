---
target_file: "bones/templates/theme-spooky-dark-xhtml.html"
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

This wrapper starts with an XML declaration, declares the XHTML namespace,
and uses self-closing `meta` and `link` elements. It shares the dark template's
stylesheet, H1 page title, H2 article title, conditional description/date/
author regions, body slot, and version/asset-metadata/tags footer.

See the [XHTML profile](../../xhtml-profile.html),
[Oliver contract](../../oliver-contract.html),
[theme guidance](../../themes.html), and
[creating themes](../../creating-themes.html).

### Limits

Selecting this template does not enable `render_profile: xhtml`. The body
profile and document wrapper are separate settings. There is no palette
hook, site-navigation slot, or script element.

The stylesheet is `css/theme-spooky-dark.css`; there is no separate XHTML
stylesheet link.

### Cautions

Select both `template: theme-spooky-dark-xhtml.html` and
`render_profile: xhtml` for an XHTML page. Raw HTML in source content fails
under the XHTML renderer rather than being repaired.

Keep wrapper markup XML-compatible. `$body$` is inserted literally, so an
HTML body profile alone cannot guarantee an XML-compatible final document.
