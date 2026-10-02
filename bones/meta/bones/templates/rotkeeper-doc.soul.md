---
target_file: bones/templates/rotkeeper-doc.html
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

The documentation wrapper sets the page title, optional description metadata,
one header H1, and a main content region with `id="rk-doc-content"`.
A skip link targets that region. The stylesheet is
`css/theme-spooky-dark.css`, not `rotkeeper.css`.

### Limits

The wrapper itself contains no page inventory or sidebar. For output under
`docs/` or `help/`, the render adapter inserts breadcrumbs, page navigation,
and previous/next links through the body slot.

### Cautions

Preserve the skip-link target and the literal `$body$` slot. Keep the
stylesheet classes aligned with the wrapper. Optional footer fields use
`$if(...)$` blocks; the version comes from the shared version loader.
