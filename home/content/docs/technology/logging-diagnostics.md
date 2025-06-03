---
title: "📟 Logging & Diagnostics"
slug: logging-diagnostics
template: rotkeeper-doc.html
version: "0.2.5-pre"
updated: "2025-06-03"
description: "Explains how logs are generated, stored, and used for debugging in Rotkeeper rituals."
tags:
  - rotkeeper
  - logging
  - diagnostics
  - debug
asset_meta:
  name: "logging-diagnostics.md"
  version: "0.2.3-pre"
  author: "Filed Systems"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# 📉 Logging & Diagnostics

Rotkeeper scripts log everything. Every directory created, file injected, archive built, and ritual run leaves a trail.

Rotkeeper’s logs form a death-rattle ledger—tracking decay, output, and decisions made by every `rc-*` script.

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
- `rc-record.sh`
- `rc-verify.sh`

***

## 🔍 diag.log

This file is a catch-all diagnostics log, often written during `rc-scan.sh`, `rc-verify.sh`, or failed expansion/render phases. It includes stack traces, environment notes, and error reports not suitable for `yougood.brah`.

Use this file to diagnose systemic failures across scripts, especially when one ritual silently fails mid-pipeline.

## ⚠️ Common Issues

- If `yougood.brah` is empty: you likely ran a dry-run or skipped phases
- If `render.log` is missing: you may not have invoked `rotkeeper render`
- If `manifest.txt` is incomplete: assets may be missing asset-meta, or `rc-assets.sh` was skipped

***

## 🧠 Tips

- Consider including timestamps in your logs using `date +"%Y-%m-%d %H:%M:%S"`
- Avoid reusing logs between builds unless explicitly comparing
- You can parse `manifest.txt` to quickly audit content drift between tombs

- `diag.log` is your last resort for when things go deeply sideways—treat it as your postmortem log.

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