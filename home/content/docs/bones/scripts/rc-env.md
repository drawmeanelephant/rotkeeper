---
title: "🧱 rc-env.sh"
slug: rc-env
template: rotkeeper-doc.html
version: "0.2.4-dev"
updated: "2025-06-01"
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
  license: "CC-BY-SA-4.2-unreal"
  tracked: true
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
- `LOG_DIR` — `"$BONES_DIR/logs"`
- `TMP_DIR` — `"$ROOT_DIR/tmp"`
- `CONFIG_DIR` — `"$BONES_DIR/config"`
- `ARCHIVE_DIR` — `"$BONES_DIR/archive"`
- `REPORT_DIR` — `"$BONES_DIR/reports"`
- `TEMPLATE_DIR` — `"$BONES_DIR/templates"`
- `DOCS_DIR` — `"$OUTPUT_DIR/docs"`
- `WEB_DIR` — `"$OUTPUT_DIR/web"`

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