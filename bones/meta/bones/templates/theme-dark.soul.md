---
target_file: bones/templates/theme-dark.html
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

This wrapper loads `css/theme-dark.css` and places the title, optional
description, and body inside an `rk-container`. Its footer includes the
loaded version and optional asset metadata and tags.

### Limits

Rendering uses Oliver through `render`, not `pack`. The template contains
no theme-switching control or inline font import.

### Cautions

Keep the relative `$assets_root$` prefix and the `$body$` slot. Styling
depends on the linked stylesheet; the wrapper alone does not establish
contrast or accessibility compliance.
