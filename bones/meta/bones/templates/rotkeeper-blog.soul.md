---
target_file: bones/templates/rotkeeper-blog.html
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

The wrapper uses `rk-shell`, a title header, an optional description, and
an article body. It loads `css/theme-spooky-dark.css` through `$assets_root$`.
The footer shows the loaded version and optional asset metadata and tags.

### Limits

The template has no date display, post list, or chronological navigation.
It wraps one rendered source body.

### Cautions

Keep `$body$` and `$assets_root$` intact. The adapter passes body HTML
literally and supplies the relative asset prefix. The linked stylesheet
must be available in the generated asset tree.
