---
target_file: bones/templates/rotkeeper-blog.html
source: generated
generated: 2026-06-27
model: jules-model
version: 0.1.0
status: final
---

### Bones of the Code
A Pandoc HTML template optimized for blog layout rendering. It provides metadata structures, date displays, and tag layouts for news and log articles.

### Restless Spirits
This template expects standard variables like `$body$`, `$title$`, and `$date$`. If these fields are missing from the frontmatter of blog posts, rendering compiles empty strings without a layout fallback.

### Ritual Warnings
Ensure all blog markdown files contain proper `date` and `title` variables in their frontmatter before rendering.
