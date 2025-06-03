---
title: "CLI Reference"
slug: tech-index
subtitle: "Rotkeeper Technology Overview"
template: rotkeeper-doc.html
version: "0.2.3-pre"
updated: "2025-06-01"
description: "Overview of Rotkeeper's CLI-based tooling, shell scripts, and static rendering flow."
tags:
  - cli
  - technology
  - docs
  - shell
  - reference
asset_meta:
  name: "index.md"
  version: "0.2.3-pre"
  author: "Filed Systems"
  project: "Rotkeeper"
  type: "toc"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# 🧪 Rotkeeper Technology Index

This section documents the internal tech stack, shell-based tools, and output rituals that power Rotkeeper. Use these pages to understand how the CLI operates behind the scenes, and how each script relates to your rendered tombs, logs, assets, and audits.

## 📚 Pages

1. [⚡ Quickstart Guide](quickstart-guide.md)
   Get running with minimal ceremony. Setup, first render, pack, and index.

2. [🗒️ CLI Commands](cli-commands.md)
   Describes each `rc-*.sh` script: purpose, flags, inputs, outputs.

3. [⚙️ Configuration Reference](config-reference.md)
   All YAML knobs, environment flags, and how render-flags.yaml gets interpreted.

4. [🪵 Logging & Reports](logging-reports.md)
   Where logs go, what `bones/logs/` holds, and how reports are used in audits.

5. [🔐 Scan & Verify Tools](scan-verify-tools.md)
   How `rc-scan.sh` and `rc-verify.sh` detect missing, mismatched, or orphaned files.

6. [🤖 CI/CD Integration](ci-cd-integration.md)
   Automate tomb generation with cron jobs, GitHub Actions, or bash-driven deploy loops.

***

<!--
Sora prompt: "A cracked ledger of Rotkeeper CLI commands, handwritten annotations in the margins, flickering terminal output behind."
-->
