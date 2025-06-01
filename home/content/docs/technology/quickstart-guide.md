---
title: "🚀 Quickstart Guide"
slug: quickstart-guide
template: rotkeeper-doc.html
version: "0.2.3-pre"
updated: "2025-06-01"
description: "A rapid onboarding guide for using Rotkeeper, setting up tombs, and rendering documentation."
tags:
  - rotkeeper
  - guide
  - quickstart
  - onboarding
asset_meta:
  name: "quickstart-guide.md"
  version: "0.2.3-pre"
  author: "Filed Systems"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---
# ⚡ Quickstart Guide

This guide walks you through creating your first tomb with Rotkeeper.

By the end of this guide, you will have:
- Initialized a rotkeeper-compatible project environment
- Rendered a Markdown file into HTML using a template
- Packed the project into a reproducible `.tar.gz` tomb

***

## 🛠️ Prerequisites

Before you begin:
- Make sure `bash`, `tar`, and `pandoc` are installed and available in your shell
- Clone or download the Rotkeeper repo:
  ```bash
  git clone https://github.com/your-org/rotkeeper.git
  cd rotkeeper
  ```

***

## 1. Initialize the Project

Run the main rotkeeper script with `init`:

```bash
./rotkeeper init
```

This will:
- Create folders (`content/`, `output/`, `templates/`, `logs/`, etc.)
- Seed default configuration files (e.g. `init-config.yaml`)
- Log the steps taken in `manifest.txt`

You can view the log output in:

```bash
cat logs/yougood.brah
```

***

## 2. Add Sample Content

Create a Markdown file inside the `content/` directory:

```bash
echo "# My First Tomb" > content/example.md
```

***

## 3. Render the Site

Use the `render` command to convert your Markdown into HTML:

```bash
./rotkeeper render
```

The output will appear in the `output/` folder, using the default layout (`templates/stackburger.html`).

***

## 4. Pack the Tomb

Now create a tomb archive of the entire rendered site:

```bash
./rotkeeper pack
```

This will:
- Read from `manifest.txt`
- Exclude unwanted files (like `archive/`)
- Output a `.tar.gz` file in the root project folder

***

## ✅ Success

You’ve now built your first tomb. It is reproducible, minimal, and tracked.

From here, explore:

- [Configuration Reference](configuration-reference.md)
- [Asset Pipeline](asset-pipeline.md)
- [Rotkeeper CLI Reference](rotkeeper-help.md)

<!--
LIMERICK

A tomb that was built in a flash,
With markdown and logs in a stash.
Though quick it may start,
Its decay is an art—
Preserved in a gzip'd bash crash.
-->

<!--
SORA PROMPT

"a ritualized digital tomb being constructed by hand, markdown swirling into HTML, static files forming like bone, eerie bureaucratic light"
-->