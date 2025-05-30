---
title: "Rotkeeper CLI & Subroutine Reference"
slug: rotkeeper-help
template: rotkeeper-doc.html
---

<!-- asset-meta: { name: "rotkeeper-help.md", version: "v0.1.0" } -->

# 📜 Rotkeeper CLI & Subroutine Reference

This document outlines how to use the `rotkeeper` CLI and its alphabetized `rc-*` subroutines to scaffold, render, and archive tombs.

---

## 🧰 Core CLI Usage

The `rotkeeper` script is the master ritual coordinator. It wraps core subroutines (`rc-*`) and handles full lifecycle execution.

### 🔧 General Syntax

```bash
./rotkeeper <command> [flags]
```

### ⚙️ Available Commands

| Command | Description |
|---------|-------------|
| `init` | Set up the project structure |
| `assets` | Copy static files from declared asset directories |
| `render` | Convert Markdown content to HTML |
| `pack` | Bundle tomb contents into a `.tar.gz` archive |
| `all` | Run `init`, `assets`, `render`, and `pack` in order |
| `help` | Display available commands and usage tips |

---

## 🏴‍☠️ Common Flags

| Flag | Description |
|------|-------------|
| `--dry-run` | Preview operations without writing to disk |
| `--skip-inject` | Avoid injection logic (e.g. `inject.d/`) |
| `--verbose` | Enable detailed logs |
| `--version` | Print current rotkeeper version |
| `--ritualize` | Output the script used to create this tomb (planned) |

---

## 🧩 Subroutine Scripts (`rc-*`)

Each subroutine lives in `scripts/` and may be invoked directly.

| Script | Purpose |
|--------|---------|
| `rc-init.sh` | Creates folders, seed files, and templates |
| `rc-assets.sh` | Copies assets from `assets/`, `themes/`, etc. |
| `rc-render.sh` | Converts `content/` Markdown to `output/` HTML |
| `rc-pack.sh` | Builds `.tar.gz` from `manifest.txt` |
| `rc-scan.sh` | Checks for missing files, version drift (planned) |
| `rc-bless.sh` | Writes a changelog and blesses the current version |
| `rc-inject.sh` | Optional script to copy contents from `inject.d/` |
| `rc-limerick.sh` | Emits random limericks to `yougood.brah` (planned) |
| `rc-record.sh` | Generates a shell script to recreate the tomb (planned) |

---

## 🧠 Environment Variables

| Variable | Use |
|----------|-----|
| `TOMB_VERSION` | Sets version string in logs, meta |
| `RK_CONFIG` | Alternate path to `init-config.yaml` |
| `RK_DRY` | Global dry-run override |
| `RK_VERBOSE` | Global verbose logging override |

---

## 🔍 Example Workflows

### Minimal render and pack:

```bash
./rotkeeper init
./rotkeeper render
./rotkeeper pack
```

### Full lifecycle:

```bash
./rotkeeper all --verbose
```

### Direct invocation:

```bash
./scripts/rc-render.sh
```

---

Back to [Documentation Index](index.md)

<!--
LIMERICK

The keeper accepts your command,  
And echoes them back, ghostly and bland.  
Each subroutine call  
Just rewrites it all—  
By entropy’s deeply chilled hand.

SORA PROMPT

"a monochrome terminal with glowing command-line invocations, each input summoning faded subroutines, cold static and flickering glyphs around them"
-->