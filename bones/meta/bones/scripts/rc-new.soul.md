---
target_file: bones/scripts/rc-new.sh
reviewed: "2026-10-09"
reviewed_against: "0.8.1"
---

### Design

Scaffolds one source under the active `CONTENT_DIR`, adding `.md` to bare names. Derives title and slug, resolves the default template, and writes optional author, description, tags, body, and source URL. Markdown and Textile receive format-specific headings; Cooklang gets a sample recipe when no body is supplied. No filename or `--list` lists available templates instead of creating content.

`--soul` uses the file-sidecar schema with a repository-relative target,
Design/Limits/Cautions headings, and null review fields. The content-relative
lookup path remains unchanged. Fill in and verify the notes before recording
a review date and version.

### Limits

Canonical destination checks reject parent traversal and paths outside the content boundary, and existing content files are refused. Value flags given without a value are rejected. Titles, templates, authors, tags, URLs, and descriptions containing control characters are rejected before any directory or file is written; only descriptions may contain newlines and tabs. Titles, templates, authors, tags, URLs, and single-line descriptions are double-quoted with quotes and backslashes escaped; multiline descriptions use a block scalar. Slugs are ASCII-oriented. The selected template name is written to frontmatter without checking whether that template exists; rendering has its own template checks.

### Cautions

`--soul` requests a mirrored metadata sidecar and preserves an existing sidecar with a warning. Newly scaffolded notes are author-editable context, not evidence that a source review has occurred. Source creation and sidecar creation are separate writes, so a sidecar failure does not roll back the content page. Dry-run skips source and sidecar publication but still loads the environment and writes bootstrap logs.
