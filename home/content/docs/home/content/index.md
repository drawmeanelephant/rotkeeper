---
title: "Home Content"
slug: content-home
template: rotkeeper-doc.html
version: 0.2.2
---

<!-- asset-meta: { name: "home-content.md", version: "v0.2.2" } -->

# 🏠 Home Content Directory

This is the root directory for all rotkeeper documentation content. It includes pages, tomb docs, render metadata, and user-authored markdown.

## 📂 Layout

```
home/content/
└── docs/
    ├── bones/        ← internal script and audit documentation
    ├── home/         ← assets, index pages, structural references
    ├── rituals/      ← onboarding steps and invocations
    ├── tombs/        ← final compiled tomb docs
    └── misc/         ← scratch space and orphaned pages
```

## 🧾 Purpose

Files under `home/content/docs/` are scanned and rendered by `rc-render.sh`.

Each Markdown file should:
- Include valid YAML frontmatter
- Use a `template:` key (e.g. `rotkeeper-doc.html`)
- Optionally include `asset-meta:` metadata for audit compatibility

## 🔄 Workflow Notes

- All subfolders may be selectively rendered
- `rc-docs-fix.sh` can insert common section headers or detect formatting gaps
- Rendered output is stored in `output/` with matching slugs

## 📎 Related Tools

- `rc-render.sh` — core renderer
- `rc-docs-fix.sh` — layout and frontmatter fixer
- `rc-audit.sh` — ensures docs contain valid metadata

## 📌 Notes

Markdown inside this folder **should not** include inline scripts or external calls. Everything is statically processed.