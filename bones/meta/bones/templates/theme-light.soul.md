---
target_file: bones/templates/theme-light.html
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

The light wrapper links `css/theme-light.css`. It uses `rk-container`,
a title header with an optional description, and a main article region.
The footer shows version, asset metadata, and tags when supplied.

### Limits

The template has no dark-mode override or theme-switching widget.
It does not define the stylesheet's colors.

### Cautions

Keep the stylesheet link relative through `$assets_root$`. Test stylesheet
changes with `bash rotkeeper.sh a11y` and inspect rendered pages; the
template does not itself verify contrast.
