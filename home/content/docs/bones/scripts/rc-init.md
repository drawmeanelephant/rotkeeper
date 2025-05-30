---
title: "🧱 rc-init.sh Reference"
slug: rc-init
template: rotkeeper-doc.html
version: "0.2.1"
updated: "2025-05-29"
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
- `render-flags.yaml`

---

## 🔁 Behavior

- Can be run repeatedly without error
- Logs to `bones/logs/rc-init-*.log`
- Exits `0` on success, `1` if required tools or permissions are missing

---

## 🏁 Flags

_Currently none._
Future flags may include:

- `--force`: recreate everything even if it exists
- `--dry-run`: print what would be made
- `--skip-render`: omit initial render after structure creation

---

## 🔗 Related Rituals

- [`rc-expand.sh`](rc-expand.md) — generates content stubs
- [`rc-render.sh`](rc-render.md) — renders output after structure is seeded

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
├── render-flags.yaml
└── bones/manifest.txt
```

---

## ⚠️ Notes & Caveats

- If `bones/manifest.txt` already exists, it will not be overwritten
- Does not clone or fetch any default templates — only prepares the structure
- Won’t run `expand` or `render` unless explicitly chained

<!-- Sora Prompt: "A ceremonial shovel labeled 'rc-init.sh' digging the first directory into a haunted filescape; skeletons holding folder trees, sigils glowing faintly on markdown pages." -->
