---
title: "🧱 rc-env.sh"
slug: rc-env
version: "0.2.5"
updated: "2025-06-03"
description: "Defines centralized environment variables and directory layout for the Rotkeeper ritual system."
tags:
  - rotkeeper
  - environment
  - bootstrap
  - shared
asset_meta:
  name: "rc-env.md"
  author: "Filed Systems"
  project: "Rotkeeper"
  license: "All Rights Reserved"
  tracked: true
  version: "0.2.5"
---

# 🧱 rc-env.sh

This script centralizes all environment setup and directory layout logic for Rotkeeper.

It should be sourced by **every `rc-*.sh` script** to establish a consistent and portable runtime environment.

## 💼 Purpose

- Define canonical paths (`ROOT_DIR`, `BONES_DIR`, `OUTPUT_DIR`, etc.)
- Resolve script-relative locations safely via `BASH_SOURCE`
- Eliminate hardcoded paths across rituals
- Optionally bootstrap default logs, tmp folders, etc.

## 📜 Exposed Variables

- `ROOT_DIR` — absolute project root path
- `BONES_DIR` — `"$ROOT_DIR/bones"`
- `OUTPUT_DIR` — `"$ROOT_DIR/output"`
- `CONTENT_DIR` — `"$ROOT_DIR/home/content"`
- `ASSETS_DIR` — `"$ROOT_DIR/home/assets"`
- `LOG_DIR` — `"$BONES_DIR/logs"`
- `TMP_DIR` — `"$ROOT_DIR/tmp"`
- `CONFIG_DIR` — `"$BONES_DIR/config"`
- `ARCHIVE_DIR` — `"$BONES_DIR/archive"`
- `REPORT_DIR` — `"$BONES_DIR/reports"`
- `TEMPLATE_DIR` — `"$BONES_DIR/templates"`
- `DOCS_DIR` — `"$OUTPUT_DIR/docs"`
- `WEB_DIR` — `"$OUTPUT_DIR/web"`
- `HELP_DIR` — `"$CONTENT_DIR/help"`
- `SCRIPT_DIR` — `"$BONES_DIR/scripts"`
- `META_DIR` — `"$BONES_DIR/meta"`

## 🔧 Usage

Add this to the top of any `rc-*.sh`:

```bash
source "$(dirname "${BASH_SOURCE[0]}")/rc-env.sh"
```

Or, if using via `rc-utils.sh`:

```bash
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
```

## 🧪 Notes

- Will eventually include environment validation (`check_bones()`, `require_dirs()`)
- May emit logs if used with `--debug`
- Intended for both human-run and CI-safe contexts

```
🪦 Ritual Standard:
Every script should source `rc-env.sh` to avoid path chaos.
```
## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-07-01T10:11:53Z -->


### Bones of the Code
The fragile foundation upon which this whole cursed architecture rests. It loads environment variables and attempts to establish 'safety bounds', as if anything here is truly safe.

### Restless Spirits
Sourcing dynamic shell scripts is basically inviting vampires in through the front door. If `ROOT_DIR` is unset or accidentally evaluates to `/`, the rest of the scripts will gladly unleash their destructive tendencies on the entire filesystem.

### Ritual Warnings
Never trust the environment. Validate `ROOT_DIR` as if your life depends on it, because the lifespan of your filesystem certainly does.
## Ritual History
<!-- DIP-HISTORY-EXTRACTED: 2026-07-01T10:32:34Z -->

- - Optimize rc-env.sh variable resolution order.
- - Remove redundant subshells from rc-env.sh.
- - Optimize rc-env.sh subshell parsing and harden sidecar path traversal boundaries
- - Optimize rc-env.sh to prevent unnecessary fork subshells.
