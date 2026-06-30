---
title: "🦴 rc-init.sh Reference"
slug: rc-init
version: "v0.2.3-pre"
updated: "2025-06-01"
description: "Initializes a new rotkeeper directory structure with all required folders, templates, and seed files."
tags:
  - rotkeeper
  - scripts
  - init
  - bootstrap
asset_meta:
  name: "rc-init.md"
  version: "v0.2.3-pre"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# 🧱 rc-init — Ritual Bootstrap

The `rc-init.sh` script creates the skeletal folder structure and placeholder files required for a new Rotkeeper deployment.

This script is typically run **once**, or when reanimating a collapsed tomb structure. It can be safely run multiple times (idempotent).

---

## 📁 What It Creates

- `bones/`, `bones/logs/`, `bones/archive/`, `bones/reports/`, `bones/templates/`
- `home/`, `home/assets/`, `home/content/rotkeeper/`
- `output/`

It also ensures the following exist:
- `bones/manifest.txt`

---

## 🔁 Behavior

- Can be run repeatedly without error
- Logs are saved to `bones/logs/rc-init.log`. All stdout and stderr are captured.
- Errors from `rc-expand.sh` or `rc-render.sh` will cause a non-zero exit and be captured in the log.
- Exits `0` on success, `1` if required tools or permissions are missing
- Sources `rc-env.sh` to set root path constants

---

## 🏁 Flags

```markdown
- `--help`: print usage text and exit
- `--verbose`: print log entries to terminal
- `--dry-run`: simulate setup without creating files
```

---

## 🔗 Related Rituals

- [`rc-expand.sh`](rc-expand.md) — generates content stubs
- [`rc-render.sh`](rc-render.md) — renders output after structure is seeded
- [`rc-book.sh`](rc-book.md) — generates documentation reports after init

---

## 🪦 Limericks

<!-- 🎴 Limerick 1:
A tomb with no bones is just lore,
So `init` lays the ground on the floor.
With each mkdir trace,
It prepares the ghost's place,
And beckons what scripts come before.
-->

<!-- 🎴 Limerick 2:
When the skeleton screeched for a scheme,
rc-init emerged like a dream.
It carved out each path,
From home to the math,
And ensured your rot cycle’s theme.
-->


---


---

## 🧪 Usage Examples

Run from the root of your Rotkeeper repo:

```bash
bash bones/scripts/rc-init.sh
```

Or invoke through the main dispatcher:

```bash
./rotkeeper init
```

All output is logged to `bones/logs/rc-init.log`.

Use this at the beginning of any new tomb cycle or prior to reseeding from archive.

---

## 🗂️ Folder Layout Preview

```plaintext
rotkeeper/
├── bones/
│   ├── archive/
│   ├── logs/
│   ├── reports/
│   └── templates/
├── home/
│   ├── assets/
│   └── content/
│       └── rotkeeper/
├── output/
└── bones/manifest.txt
```

---

## ⚠️ Notes & Caveats

- If `bones/manifest.txt` already exists, it will not be overwritten
- Does not clone or fetch any default templates — only prepares the structure
- Won’t run `expand` or `render` unless explicitly chained
- Errors are trapped and logged via `trap_err`. Review `rc-init.log` for troubleshooting.
- May be chained with `rc-book.sh` or `rc-render.sh` to generate reports and outputs after setup

<!-- Sora Prompt: "A ceremonial shovel labeled 'rc-init.sh' digging the first directory into a haunted filescape; skeletons holding folder trees, sigils glowing faintly on markdown pages." -->

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-06-30T15:49:36Z -->


### Bones of the Code
The Genesis script. It copies templates, blesses scripts, and bootstraps the project. It's the overly enthusiastic cult leader welcoming you to the compound.

### Restless Spirits
Its zealotry knows no bounds. When invoked with `--force`, it will violently overwrite existing configurations and clobber active directories without a second thought. It respects nothing that came before it.

### Ritual Warnings
Use `--force` only when you are entirely prepared to salt the earth and start anew. Keep backups of your configuration.
