---
title: "Blog Layout Template"
description: "Layout expectations for logs, streams, and chronology formats."
status: "complete"
---

### Architectural Intent
A Pandoc HTML template optimized for blog layout rendering. It provides metadata structures, date displays, and tag layouts for news and log articles.

### Directory / File Schema Expectations
This template expects standard variables like `$body$`, `$title$`, and `$date$`. If these fields are missing from the frontmatter of blog posts, rendering compiles empty strings without a layout fallback. Ensure all blog markdown files contain proper `date` and `title` variables in their frontmatter before rendering.
