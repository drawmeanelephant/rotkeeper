---
title: "Quickstart Guide"
description: "A ritual walkthrough for first-time rotkeepers."
version: "0.2.3-pre"
template: rotkeeper-doc.html
updated: "2025-05-31"
---

# ☠️ Quickstart Guide

Welcome, ritual novice. This document will walk you through your first decay cycle using the Rotkeeper CLI.

## 🧱 Prerequisites

- A Unix-like environment with Bash ≥ 5.x
- `pandoc`, `tar`, and `yq` installed
- A willingness to embrace file death

## 🔨 Your First Tomb

1. **Initialize a new tomb directory:**

   ```bash
   ./rc-init.sh --name my-first-tomb
   ```

2. **Expand the ritual from YAML:**

   ```bash
   ./rc-expand.sh --input tombs/my-first-tomb.yaml
   ```

3. **Render the tomb into HTML:**

   ```bash
   ./rc-render.sh --input tombs/my-first-tomb/
   ```

4. **Scan for file decay:**

   ```bash
   ./rc-scan.sh --input tombs/my-first-tomb/
   ```

5. **Bless and pack it for archival:**

   ```bash
   ./rc-bless.sh --input tombs/my-first-tomb/
   ./rc-pack.sh --input tombs/my-first-tomb/ --output my-first-tomb.tar.gz
   ```

## 📦 What Next?

Check out the [Docs Navigation](/docs/) for deeper rites:
flags, templates, scan rituals, changelogs, and reseeding the entire archive.

> 💀 *You have now become an apprentice of the rot.*