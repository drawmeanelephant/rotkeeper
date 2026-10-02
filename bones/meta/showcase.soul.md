---
title: "Theme showcase"
description: "Generated sample pages for inspecting HTML templates."
reviewed: "2026-10-01"
---

### Purpose

`showcase` writes one Markdown sample per HTML template to this content
directory. The pages support visual inspection; generating them does not
prove that a theme is accessible or free of layout defects.

### Contents and conventions

Sample bodies include headings, emphasis, lists, code, tables, blockquotes,
and metadata. Existing per-template sample files are replaced. The command
does not render the individual samples; run `bash rotkeeper.sh render`
afterward. It also replaces the Markdown gallery index and writes a static
HTML gallery directly under the output tree.
