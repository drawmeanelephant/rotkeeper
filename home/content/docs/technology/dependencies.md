---
title: "🔗 Dependencies"
slug: dependencies
template: rotkeeper-doc.html
version: "0.2.3-pre"
updated: "2025-06-01"
description: "Lists the required tools and environment dependencies for running Rotkeeper rituals, renderers, and CLI tools."
tags:
  - rotkeeper
  - dependencies
  - environment
  - setup
asset_meta:
  name: "dependencies.md"
  version: "0.2.3-pre"
  author: "Filed Systems"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# 🛠 Dependencies (macOS)

Rotkeeper is currently developed and tested on macOS. Linux and WSL support may be possible in the future—pending rituals, caffeine, and divine intervention.

***

## 🔧 Required Tools

You’ll need the following installed and available in your `$PATH`:

| Tool     | Purpose                    | Install Command (Homebrew)     |
|----------|----------------------------|--------------------------------|
| `bash`   | Script shell               | Pre-installed on macOS         |
| `pandoc` | Markdown → HTML renderer   | `brew install pandoc`          |
| `yq`     | YAML processor             | `brew install yq`              |
| `jq`     | JSON processor             | `brew install jq`              |
| `tar`    | Archiver                   | Pre-installed on macOS         |
| `git`    | Version control + rev logs| `brew install git`             |

Optional:
- `tree` (for file structure previews)
- `bat` (for pretty log dumps)
- `grep`, `sed`, `find` (BSD variants are fine, but GNU versions preferred if you’re chaotic)

***

## 🍎 macOS Setup

1. **Install Homebrew** (if missing):
   [https://brew.sh](https://brew.sh)

2. **Run the full install stack**:

```bash
brew install pandoc yq jq git tree bat
```

3. **Clone the repo and run a render**:

```bash
git clone https://github.com/youruser/rotkeeper.git
cd rotkeeper
./rotkeeper.sh render
```

***

## 💭 Linux / WSL?

Not supported yet, but theoretically viable.
If you try and succeed—or suffer greatly—please submit a ritual report or log your screams to the issue tracker.

***
> *“macOS is the temple. WSL is the haunted basement. Linux is the field where bones are scattered.”*
