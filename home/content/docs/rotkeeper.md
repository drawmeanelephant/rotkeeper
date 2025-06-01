---
title: "🦴 Rotkeeper Overview"
slug: rotkeeper
template: rotkeeper-doc.html
version: "0.2.3-pre"
updated: "2025-06-01"
description: "Core introduction to the Rotkeeper ritual system — its purpose, philosophy, and tooling layers."
tags:
  - rotkeeper
  - overview
  - philosophy
  - intro
asset_meta:
  name: "rotkeeper.md"
  version: "0.2.3-pre"
  author: "Filed Systems"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# `rotkeeper.sh`

This is the main CLI interface for invoking Rotkeeper rituals. It wraps and dispatches calls to each `rc-*.sh` script using familiar subcommands.

***

## 🧠 Purpose

To provide a unified command for interacting with all parts of the rotkeeper toolchain, including initialization, rendering, blessing, verifying, and packing.

***

## 📜 Usage

```bash
./rotkeeper.sh [command] [flags]
```

***

## 🔧 Supported Commands

| Command     | Description                          |
|-------------|--------------------------------------|
| `init`      | Create default folders and templates |
| `assets`    | Copy static files into `output/`     |
| `render`    | Render markdown into HTML tombs      |
| `bless`     | Create changelog and version marker  |
| `verify`    | Check tomb integrity                 |
| `record`    | Log current git + datetime info      |
| `pack`      | Create `.tar.gz` of output & logs    |
| `test`      | Run all scripts in dry mode          |
| `help`      | Show available commands              |

***

## 🧪 Example

```bash
./rotkeeper.sh render
./rotkeeper.sh bless
./rotkeeper.sh pack
```

***

> *“The rotkeeper never types the full path. The path types itself.”*