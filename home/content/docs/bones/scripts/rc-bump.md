---
title: "📈 rc-bump.sh Reference"
slug: rc-bump
version: "0.3.0"
updated: "2026-06-15"
description: "Automated microbump logging and version bumping workflow."
tags:
  - rotkeeper
  - scripts
  - logging
  - versioning
asset_meta:
  name: "rc-bump.md"
  version: "v0.3.0"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "All Rights Reserved"
---

<!--
🎨 Sora Prompt:
"A mechanical monk meticulously chiseling a new version number into a monolithic stone tablet, surrounded by piles of old, dusty blueprints."
-->

# 📈 rc-bump.sh

<!-- The rite of chronicling progress -->
**Script Path:** `bones/scripts/rc-bump.sh`

## Purpose
- Handles the bureaucratic paperwork of advancing the project's version.
- Replaces the tedious process of manually updating version strings across dozens of bash scripts.
- Injects updates into the Living Buildlog and the `CHANGELOG.md`.
- Automatically stages and commits the changes to Git.

## CLI Interface
```bash
./rotkeeper.sh bump -m "Your update message here"
```

## Workflow Steps
1. **Version Discovery**
   - Reads the current `VERSION` variable from the main `rotkeeper.sh` dispatcher.
2. **Microbump Calculation**
   - Increments the final digit of the version string (e.g., `0.3.0.6` becomes `0.3.0.7`).
3. **Global Replacement**
   - Uses a POSIX-compliant `awk` script to execute a search-and-replace across all `rc-*.sh` files and the main dispatcher, ensuring the new version string is stamped into every header.
4. **Living Buildlog Injection**
   - Appends the message and timestamp directly into the `road-to-bones/index.md` buildlog.
5. **Changelog Append**
   - Adds the new version entry to the root `CHANGELOG.md`.
6. **Git Commit**
   - Runs `git add .` and commits the entire tree with a standardized `bump: [version] - [message]` commit message.

## 🛣️ Navigation
- [Scripts Index](index.html)
- [Bones Home](../index.html)

<!--
Limerick:
The version was stuck in the past,
And updating by hand was a task.
But bump ran the string,
Changed every last thing,
And committed the code really fast.
-->

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-06-30T17:53:41Z -->


### Bones of the Code
A mindless automaton dedicated to making numbers go up. It integrates with Python3 to bump patch versions and automatically commits the results. It's the bureaucratic equivalent of a necromancer padding their body count.

### Restless Spirits
Running this in a dirty Git tree will indiscriminately swallow your uncommitted sins into the bump commit. Worse, if tied to a CI pipeline, it can easily enter a frenzied loop of automated commits on failure, spamming your repository with endless, meaningless bumps until the heat death of the universe.

### Ritual Warnings
Never invoke this ritual in a dirty working directory. If you attach this to an automated pipeline, ensure you have safeguards against infinite commit loops, or face the wrath of the repository maintainers.
