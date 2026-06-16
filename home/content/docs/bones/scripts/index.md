---
title: "Rotkeeper Script Index"
slug: scripts-index
version: "v0.2.5-pre"
updated: 2025-06-03
description: "Index of all rc-*.sh ritual scripts with status and links"
tags:
  - rotkeeper
  - scripts
  - cli
asset_meta:
  name: "scripts-index.md"
  version: "v0.2.5-pre"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# 📜 Rotkeeper Scripts — Bones of the Machine

Every `rc-*.sh` script serves a ceremonial function in the Rotkeeper CLI. This page links out to the full autopsy reports and usage notes for each.

All scripts live in:

```
bones/scripts/
```

## 📂 Script Inventory

<!-- The council’s ledger of all ritual scripts -->

| Script              | Purpose                                        | Link                                    | Status   |
|---------------------|------------------------------------------------|-----------------------------------------|----------|
| rc-init.sh          | Initialize directory and file layout           | [rc-init.sh](rc-init.html)      | Ready    |
| rc-render.sh        | Convert markdown to HTML                       | [rc-render.sh](rc-render.html)  | Ready    |
| rc-pack.sh          | Archive `/output/`, export JSON                | [rc-pack.sh](rc-pack.html)      | Ready    |
| rc-scan.sh          | Detect orphan/missing files, create digests    | [rc-scan.sh](rc-scan.html)      | Ready    |
| rc-assets.sh        | Manifest static assets in YAML                 | [rc-assets.sh](rc-assets.html)  | Ready    |
| rc-reseed.sh        | Restore from `.tar.gz` archive                 | [rc-reseed.sh](rc-reseed.html)  | Ready    |
| rc-status.sh        | Summarize project health and logs              | [rc-status.sh](rc-status.html)  | Ready    |
| rc-cleanup-bones.sh | Backup and prune bones/ archives and logs      | [rc-cleanup-bones.sh](rc-cleanup-bones.html) | Ready    |
| rc-glue.sh          | Generate index.md navigation glue              | [rc-glue.sh](rc-glue.html)      | Ready    |
| rc-ingest.sh        | Unpack and merge decentralized payloads        | [rc-ingest.sh](rc-ingest.html)  | Ready    |
| rc-bump.sh          | Log microupdate and bump version               | [rc-bump.sh](rc-bump.html)      | Ready    |
| rc-release.sh       | Package lite and full distributions            | [rc-release.sh](rc-release.html)| Ready    |
| rc-sitemap.sh       | Generate sitemap_pipeline.yaml                 | [rc-sitemap.sh](rc-sitemap.html)| Ready    |
| rc-book.sh          | Generate markdown binders                      | [rc-book.sh](rc-book.html)      | Ready    |
| rc-unpack.sh        | *Planned* — restore output from archive        | [rc-unpack.sh](rc-unpack.html)  | Planned  |

## 🛣️ Navigation

<!-- Quick navigation to scripts -->
- [rc-assets.sh](rc-assets.html)
- [rc-scan.sh](rc-scan.html)
- [rc-status.sh](rc-status.html)
- [Other scripts…](index.html)

## 🧭 Usage

All scripts may be run manually:

```bash
bash bones/scripts/rc-render.sh
```

Or through the CLI dispatcher:

```bash
./rotkeeper render
```

## 🔮 Future Additions

- `rc-mascot.sh`: Mascot-aware frontmatter enforcement
- `rc-doclint.sh`: Structural Markdown and YAML validator
- `rc-shell.sh`: REPL interface for tomb diagnostics

---

<!-- Sora Prompt: "A rusted clipboard listing shell script names beside ancient terminals, glowing runes next to filenames. A mascot skeleton whispers which scripts are working." -->
