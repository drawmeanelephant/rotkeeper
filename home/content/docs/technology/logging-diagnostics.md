---
title: "Logging & Diagnostics"
slug: logging-diagnostics
template: rotkeeper-doc.html
---

<!-- asset-meta: { name: "logging-diagnostics.md", version: "v0.1.0" } -->

# 📉 Logging & Diagnostics

Rotkeeper scripts log everything. Every directory created, file injected, archive built, and ritual run leaves a trail.

This file explains how Rotkeeper logs work, where to find them, and how to interpret their often deadpan tone.

***

## 📁 Log Output Location

Logs are stored in the `logs/` folder by default. You may see:

- `logs/yougood.brah` — core status output
- `logs/render.log` — output from the `rc-render.sh` script
- `logs/manifest.txt` — a flat list of files to be packed

You can modify these locations in your configuration, but the defaults are consistent across projects.

***

## 🧾 yougood.brah

This is Rotkeeper’s primary ritual status log.

Example entries:
```bash
✅ Initialized: content/
📄 Injected: themes/hiq/hiq-custom.css
📦 Packed: tomb-v0.1.7.5.tar.gz
⚠️  Skipped: inject.d not found
```

It is safe to append your own entries to this file if you're extending behavior. It is meant to be human-readable and ritualistically reassuring.

***

## 🧪 render.log

This file captures Pandoc output from `rc-render.sh`.

It will contain errors, warnings, and info from each Markdown file that is processed. Common errors include:

- Unclosed tags in templates
- Undefined variables in frontmatter
- Files that fail to convert due to encoding issues

***

## 📦 manifest.txt

This file is regenerated (or updated) on every pack cycle and determines what gets included in your tomb.

It is used by:
- `rc-pack.sh`
- `rc-bless.sh`
- `rc-verify.sh`

***

## ⚠️ Common Issues

- If `yougood.brah` is empty: you likely ran a dry-run or skipped phases
- If `render.log` is missing: you may not have invoked `rotkeeper render`
- If `manifest.txt` is incomplete: assets may be missing asset-meta, or `rc-assets.sh` was skipped

***

## 🧠 Tips

- Consider including timestamps in your logs using `date +"%Y-%m-%d %H:%M:%S"`
- Avoid reusing logs between builds unless explicitly comparing
- You can parse `manifest.txt` to quickly audit content drift between tombs

***

Back to [Limericks & Creative Corner](limericks-creative-corner.md)
Continue to [Persona Management](persona-management.md)

<!--
LIMERICK

The logger once quietly groaned,
As subroutines echoed and moaned.
Its timestamps were terse,
Each message a curse—
But the tomb’s full condition was known.

SORA PROMPT

"a flickering terminal log writing itself during a ritual, each entry echoing like a chant, timestamps glowing like runes, diagnostic sorrow in grayscale"
-->