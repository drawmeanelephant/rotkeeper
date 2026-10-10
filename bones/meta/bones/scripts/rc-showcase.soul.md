---
target_file: bones/scripts/rc-showcase.sh
reviewed: "2026-10-09"
reviewed_against: "0.8.1"
---

### Design

Discovers top-level HTML templates in the active `TEMPLATE_DIR`, scaffolds `CONTENT_DIR/showcase/showcase-<name>.md`, and writes both a gallery source index and an immediate static gallery at `OUTPUT_DIR/showcase/index.html`. Names remove the `.html` suffix and optional `theme-` prefix. Sample frontmatter is derived from template tokens; a common body exercises headings, lists, quotes, tables, and code.

### Limits

Does not render the individual showcase pages; run render afterward to populate their linked HTML. The template-directory existence check is explicit. The optional Oliver check only tests whether a template is non-empty when an executable renderer is discoverable; it never invokes Oliver or validates the template dialect. An empty template stops the run with exit 1 before its page is written (also in dry-run), leaving later templates and the gallery indexes unwritten. The source gallery contains raw HTML, and per-template scaffolds do not automatically select XHTML profiles.

### Cautions

Real runs replace generated showcase sources and both gallery indexes, so manual additions there are lost. Templates whose names differ only by the removed `theme-` prefix map to the same showcase filename. Dry-run skips the showcase directory, page, and index writes but still writes bootstrap logs. The direct gallery output is a preview write, not a render-manifest update.
