---
target_file: bones/templates/theme-overgrown.html
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

The wrapper loads `css/theme-overgrown.css`, displays `$title$` in an
`rk-header`, and places `$body$` in `rk-article` within `rk-shell`.
The footer contains the version and optional asset metadata and tags.

### Limits

There are no Google Fonts imports or description fields in this template.
Typography and colors are defined by its stylesheet.

### Cautions

Keep the stylesheet available through the relative asset prefix. Template
changes must preserve the literal body slot and the CSS class names they use.
