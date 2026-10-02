---
target_file: "bones/templates/theme-textpattern.html"
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

This HTML wrapper links `css/theme-textpattern.css`. It separates a fixed
site masthead, a config-driven navigation slot, the article, and a sidebar.
The article owns the H1 page title and literal body slot. Date, author, and
description are conditional; the footer carries the loaded version and
optional asset metadata and tags.

The masthead uses a paragraph rather than a second H1. The adapter fills
`<site-nav></site-nav>` after wrapping. See the
[Oliver contract](../../oliver-contract.html),
[theme guidance](../../themes.html), and
[creating themes](../../creating-themes.html).

### Limits

Selecting this wrapper does not select Textile input. The source extension
or configured input format chooses the parser.

Sidebar text, reference examples, and section links are fixed in the
template. They are not generated from the content inventory. `palette`
adds a root class but does not validate a palette name.

### Cautions

The fixed links expect the site's index and named documentation pages to
exist. The `$assets_root$../` prefix makes those links relative to the page
depth; moving destination pages still requires updating the template.

Navigation must use the literal slot, not an escaped metadata token.
This HTML wrapper is not the XML-compatible variant described in the
[XHTML guide](../../xhtml-profile.html).
