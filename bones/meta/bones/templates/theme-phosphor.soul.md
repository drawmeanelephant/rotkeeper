---
target_file: bones/templates/theme-phosphor.html
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

The wrapper loads `css/theme-phosphor.css` and includes a `crt-overlay`
element. The header formats the title as `> $title$_`. The article receives
the rendered body; the footer shows version and optional metadata.

### Limits

This is an HTML page wrapper, not a terminal emulator. It contains no
inline font import, dynamic flag parser, or description display.

### Cautions

Keep the overlay's styling in the associated stylesheet. Preserve
`$assets_root$` and `$body$`; layout-specific asset locations are supplied
by the renderer rather than hard-coded to `home/assets`.
