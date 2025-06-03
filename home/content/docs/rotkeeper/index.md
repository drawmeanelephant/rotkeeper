---
title: "🦴 Rotkeeper Overview"
slug: rotkeeper
template: rotkeeper-doc.html
version: "0.2.5-pre"
updated: "2025-06-02"
description: "Core introduction to the Rotkeeper ritual system — its purpose, philosophy, and tooling layers."
tags:
  - rotkeeper
  - overview
  - philosophy
  - intro
asset_meta:
  name: "rotkeeper.md"
  version: "0.2.5-pre"
  author: "Filed Systems"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# `rotkeeper.sh`

This is the main CLI interface for invoking Rotkeeper rituals. It wraps and dispatches calls to each `rc-*.sh` script using familiar subcommands.

***

## 🧠 Purpose

To provide a unified command for interacting with all parts of the rotkeeper toolchain, including initialization, rendering, verifying, and packing.

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
| `verify`    | Check tomb integrity                 |
| `record`    | Log current git + datetime info      |
| `pack`      | Create `.tar.gz` of output & logs    |
| `test`      | Run all scripts in dry mode          |
| `help`      | Show available commands              |
| `book`      | Generate documentation outputs (scriptbook, docbook, webbook) |

***

## 🧪 Example

```bash
./rotkeeper.sh render
./rotkeeper.sh pack
./rotkeeper.sh book --all
```

***

> *“The rotkeeper never types the full path. The path types itself.”*