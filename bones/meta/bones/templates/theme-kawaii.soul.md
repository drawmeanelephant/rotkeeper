---
target_file: bones/templates/theme-kawaii.html
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

The wrapper links `css/theme-kawaii.css` and uses `rk-shell`, `rk-header`,
`rk-title`, and `rk-article` as class names. It displays a title, body,
version footer, and optional asset metadata and tags.

### Limits

The template contains no Google Fonts import and no description display.
The named wrappers are ordinary HTML elements with classes, not custom tags.

### Cautions

Preserve `$assets_root$` and `$body$`. Check the stylesheet separately for
font and color behavior; the wrapper does not guarantee high contrast.
