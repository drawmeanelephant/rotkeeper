---
title: "Help"
description: "Task-based guides for installing, writing, building, checking, publishing, and maintaining Rotkeeper."
reviewed: "2026-10-02"
---

### Purpose

The authored Help index is the task hub. It links existing guide URLs under
Docs and the DIP-generated command index; guide URLs are retained so older
links continue to work. Docs also contains generated core-file references.

### Contents and conventions

Do not replace the Help index with an automatic directory listing. Task
guides declare `doc_type: guide`, record their review date, and have no core
`target_file`. DIP reports them separately rather than stitching command
reference sections into them. `render_system_docs: false` excludes Help,
Docs, and messages together; the published product-help site keeps that
setting enabled.
