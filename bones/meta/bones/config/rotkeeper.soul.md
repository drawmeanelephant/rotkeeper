---
target_file: bones/config/rotkeeper.yaml
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

The YAML file supplies project metadata, default templates, input format,
and the theme registry. `theme_registry.default` takes precedence over
`default_template`. Page frontmatter can select a different template.
The navigation block provides site-relative link targets and labels.

### Limits

Without `layout_style`, paths use the `crypt` layout. Without a `paths`
block, environment loading derives paths from the repository root.
Unsupported input formats or render profiles fall back to Markdown or HTML.

### Cautions

Strict bootstrap validates YAML and any saved path cache. A saved root must
match the checkout, and cached paths must agree with the selected layout.
Use `bash rotkeeper.sh init` to regenerate mappings after relocation or a
layout change. Registered template files must exist in the active template
directory.
