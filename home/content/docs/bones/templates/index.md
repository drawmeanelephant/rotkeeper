---
title: "🧰 Template Index"
slug: templates-index
template: rotkeeper-doc.html
version: "v0.2.3-pre"
updated: "2025-06-01"
description: "Index of Pandoc and HTML templates used in Rotkeeper rendering workflows."
tags:
  - rotkeeper
  - templates
  - rendering
  - index
asset_meta:
  name: "index.md"
  version: "v0.2.3-pre"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# 🧾 Rotkeeper Template Rituals

These templates define how rendered HTML outputs look across different parts of the Rotkeeper system. They're consumed by `rc-render.sh` and selected using `render-flags.yaml`.

Each template lives in:
```
bones/templates/
```

## 📄 Template List

| Template File             | Purpose                                  | Style         |
|---------------------------|------------------------------------------|---------------|
| `rotkeeper-doc.html`      | Maximalist aesthetic / Sora-centric docs | Glitchy       |
| `rotkeeper-blog.html`     | Clean Bootstrap with metadata block      | Readable      |
| `rotkeeper-bones.html`    | Raw Pandoc passthrough (no layout)       | Skeleton only |
| `rotkeeper-tech.html`     | *[planned]* For manuals, scripts, flags  | CLI-friendly  |

## ⚙️ How Rendering Works

Template selection is configured in `render-flags.yaml` using the keys:

```yaml
template_dir: bones/templates/
default_template: rotkeeper-doc.html
per_path:
  docs/bones/scripts: rotkeeper-tech.html
  docs/blog: rotkeeper-blog.html
  docs/mascots: rotkeeper-doc.html
```

## 🧠 Metadata Access

Each template can access the following injected fields:

- `$title$`
- `$subtitle$`
- `$date$`
- `$asset-meta$`
- `$body$` (main rendered content)
- `$sora-prompt$` (optional block from markdown)

## 🔮 Future Plans

- Add `rotkeeper-mascot.html` for character bios
- Add `rotkeeper-log.html` for dev logs and audits
- Add dark-mode toggle or per-mascot themes

---

<!-- Sora Prompt: "A glowing folder labeled 'bones/templates/', with tiny mascots pulling HTML ribbons from inside. Terminal UI overlays drift across a digital ritual altar." -->