---
title:  "Ritual Record Generator"
slug: ritual-record
template: rotkeeper-doc.html
---
<!-- asset-meta: { name: "quickstart-guide.md", version: "v0.1.0" } -->
# 🧃 Ritual Record Generator

Rotkeeper’s planned `rc-record.sh` tool allows a tomb to generate the script that built it. This helps with reproducibility, documentation, debugging, and preservation of ritual steps in a literal, executable format.

---

## 🪬 What It Does

`rc-record.sh` will output a reproducible `.sh` script that captures:

- Folder creation order and structure (`rc-init.sh`)
- Files added to `manifest.txt`
- Asset injection steps
- Template render instructions (Pandoc calls)
- Packing invocation (with the resulting archive path)

The result is a snapshot not just of state, but of **procedure**.

***

## 📄 Example Output

```bash
#!/bin/bash
# Recorded by rotkeeper v0.1.7.5 on 2025-05-13

mkdir -p content logs output templates
cp assets/hiq-custom.css output/
pandoc content/index.md -o output/index.html --template templates/stackburger.html
tar -czf tomb-v0.1.7.5.tar.gz -T manifest.txt
```

You can pipe this into a file for reproduction:

```bash
./scripts/rc-record.sh > tomb-replay.sh
bash tomb-replay.sh
```

***

## 🎛 Use Cases

- Generate portable build scripts for tombs
- Archive a tomb and its ritual in the same `.tar.gz`
- Restore an old version’s state *exactly* from a past invocation
- Let AI agents replay and audit rot procedures for forensic analysis

***

## 🔮 Future Features

- Flag support: `--compact`, `--commented`, `--annotated`
- Embed persona signature in generated file
- Include optional SHA validation or meta header summary

***

Back to [Changelog & Version Blessing](changelog-blessing.md)
Return to [Documentation Index](index.md)

<!--
LIMERICK

A record was etched in the void,
A ritual script to be deployed.
With each line replayed,
The tomb was remade—
And entropy briefly enjoyed.

SORA PROMPT

"a terminal script auto-generating itself from logs, digital runes forming a ritual replay, soft glowing shell prompts on a black mirror background"
-->