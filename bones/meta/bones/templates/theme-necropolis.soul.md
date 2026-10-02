---
target_file: "bones/templates/theme-necropolis.html"
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

This HTML wrapper links `css/theme-necropolis.css` and exposes
`data-page-type="$page_type$"` on the body. The stylesheet scopes its 404
treatment to `body[data-page-type="404"]`.

The wrapper has an H1 page title, an H2 article title, conditional description,
date, and author, and a literal body slot. Scene and divider containers are
marked `aria-hidden="true"`. The footer includes the loaded version and
optional asset metadata and tags.

`page_type` uses the generic frontmatter hook documented in the
[Oliver contract](../../oliver-contract.html). See
[theme guidance](../../themes.html) and
[creating themes](../../creating-themes.html).

### Limits

The theme changes page presentation; it does not set an HTTP status, install
a route, or determine when a host serves a 404 page. There is no palette
hook, site-navigation slot, or script element.

The scene and footer text are fixed in the wrapper rather than supplied by
page metadata.

### Cautions

Set `page_type: 404` to activate the matching stylesheet selectors. An absent
generic metadata key leaves its token literal under the wrap contract.

This is an HTML wrapper. Its presentation does not make raw HTML acceptable
under the [XHTML profile](../../xhtml-profile.html).
