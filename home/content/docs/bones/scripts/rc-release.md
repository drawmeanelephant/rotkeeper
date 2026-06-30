---
title: "📦 rc-release.sh Reference"
slug: rc-release
version: "0.3.0"
updated: "2026-06-15"
description: "Packages the project into 'lite' and 'full' distribution zip files."
tags:
  - rotkeeper
  - scripts
  - packaging
  - distribution
asset_meta:
  name: "rc-release.md"
  version: "v0.3.0"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

<!--
🎨 Sora Prompt:
"A conveyor belt in a dark factory dropping heavy, perfectly sealed metal lockboxes into a bottomless pit, while spectral workers stamp 'LITE' and 'FULL' on the sides."
-->

# 📦 rc-release.sh

<!-- The rite of distribution -->
**Script Path:** `bones/scripts/rc-release.sh`

## Purpose
- Prepares the Rotkeeper framework for distribution to other users or subagents.
- Generates two distinct flavors of the project: `lite` and `full`.
- The `full` distribution contains the entire working framework, minus temporary outputs and `.git`.
- The `lite` distribution strips away heavy documentation and contributor lore to provide a sterile, blind environment for testing or minimal deployment.

## CLI Interface
```bash
./rotkeeper.sh release
```

## Workflow Steps
1. **Version Detection**
   - Extracts the current system version from `rotkeeper.sh`.
2. **Staging**
   - Creates temporary staging directories in `bones/tmp/`.
3. **Copying**
   - Uses `rsync` to mirror the repository into the staging directories while excluding volatile folders like `.git/`, `output/`, and `bones/logs/`.
4. **Stripping the Lite Distribution**
   - In the `lite` staging folder, aggressively deletes documentation files (`README.md`, `CHANGELOG.md`, `home/content/docs/`, etc.).
   - Injects a micro-README pointing users towards the CLI help.
5. **Compression**
   - Zips both staging directories into `bones/releases/rotkeeper-[version]-full.zip` and `rotkeeper-[version]-lite.zip`.
6. **Cleanup**
   - Prunes the temporary staging files.

## 🛣️ Navigation
- [Scripts Index](index.html)
- [Bones Home](../index.html)

<!--
Limerick:
The archives were growing too fat,
To share in a decentralized chat.
So release made a zip,
For a lightweight trip,
And deleted the docs just like that.
-->

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-06-30T14:44:02Z -->


### Bones of the Code
The merchant of death, packaging distribution zip files for the masses. It uses exclusion lists to decide what gets left behind in the crypt.

### Restless Spirits
The exclusion lists are a brittle defense. If a sensitive file gets created that doesn't match the hardcoded patterns, it will be happily zipped up and shipped to production. Its assumptions about the target environments are equally perilous.

### Ritual Warnings
Audit the exclusion lists regularly. Never assume that 'lite' means 'safe'—sensitive data will slip through if you aren't paying attention.
