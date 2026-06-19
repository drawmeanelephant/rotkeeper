---
title: "The Book of Rituals"
slug: rotkeeper-rituals
template: rotkeeper-doc.html
description: "A cryptic, lore-friendly guide to the bash scripts (rituals) that power Rotkeeper."
---

# The Book of Rituals

Within the `bones/scripts/` directory lie the bash scripts—known to us as the **rituals**. These incantations manage the decay and rebirth of your markdown tombs.

To prevent catastrophic entropy, **do not invoke these scripts directly.** Always channel your intent through the dispatcher: `./rotkeeper.sh <command>`.

## 📜 The Core Rituals

### 💀 `rc-render.sh` (The Rebirth)
The most sacred command. It sweeps through `home/content/`, reads the markdown (the remains), and resurrects them as HTML forms in the `output/` directory, guided by your chosen Pandoc templates.

### 📦 `rc-pack.sh` (The Embalming)
Takes the rendered output and binds it into a `.tar.gz` archive. This archive is timestamped and carries a `metadata.json` soul, making it perfect for preservation or transmission to other crypts.

### 📖 `rc-book.sh` (The Binding)
Gathers scattered fragments (scripts, docs, or configuration files) and binds them into massive, single-file Markdown tomes (like the `docbook` or `scriptbook`). Essential for handing context over to AI agents or human scholars.

### 🔍 `rc-scan.sh` (The Audit)
Scans your earthly files against the eternal `bones/manifest.txt`. It seeks out orphans, missing files, and mismatched SHA256 checksums, ensuring the integrity of your graveyard.

### 🕸️ `rc-ingest.sh` (The Calling)
When decentralized payloads (`.tar.gz` files) arrive from external agents in the `messages-from-my-friends/` inbox, this ritual safely unpacks and merges them into `home/content/messages/`.

### 🧹 `rc-cleanup-bones.sh` (The Purge)
A dangerous but necessary act. It sweeps away old logs and backups from `bones/`, enforcing a retention window (default 30 days) to prevent your system from choking on its own history.

---
*May these rituals serve you well in the dark.*
