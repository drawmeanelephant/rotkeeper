---
title: "Architecture & Philosophy"
slug: architecture
version: "0.3.0"
updated: "2026-06-15"
description: "The Four Pillars of the Bash-Native Necropolis."
tags:
  - rotkeeper
  - architecture
  - philosophy
asset_meta:
  name: "architecture.md"
  version: "v0.3.0"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "All Rights Reserved"
---

<!--
🎨 Sora Prompt:
"A monolithic basalt pillar inscribed with glowing bash syntax, standing defiantly in a desert of abandoned javascript frameworks."
-->

# 🏛️ Architecture & Philosophy

Welcome to the Bash-Native Necropolis. 

Rotkeeper operates under a brutal, unapologetic philosophy: **No frameworks. No hydration. Just bones.** 
It is not a stepping stone to a modern Javascript framework. It is the final destination for content that must survive the test of time. It relies entirely on Unix philosophies, Bash orchestration, and Pandoc compilation.

Rotkeeper is permanently composed of **Four Core Pillars**, all native to the system and designed to outlive the web as we know it.

## The Four Pillars

### 1. The Vault (State & Assets)
The Vault manages the integrity and history of the project. It handles micro-version logging, state auditing, and asset tracking.
- **Key Rituals:** `rc-bump.sh`, `rc-scan.sh`, `rc-assets.sh`
- **Purpose:** Ensure that the project's history is perfectly committed and that every asset is checksum-verified.

### 2. The Forge (Render)
The Forge is the burning heart of Rotkeeper. It uses `pandoc` to convert Markdown tombs into static HTML.
- **Key Rituals:** `rc-render.sh`
- **Purpose:** Translate semantic, flat-file Markdown into reading-optimized web pages without a single byte of unnecessary JavaScript. **Pandoc is non-negotiable.** Do not attempt to replace the Forge with Node, NPM, Astro, or any other modern compiler.

### 3. The Courier (Archive)
The Courier guarantees that your words can travel securely through time and space. It packages both raw content and rendered outputs into highly portable `.tar.gz` tombs.
- **Key Rituals:** `rc-pack.sh`, `rc-release.sh`
- **Purpose:** Create versioned backups and shareable distribution zips that can be stored offline or handed to collaborators.

### 4. The Receiver (Ingest & Glue)
The Receiver allows Rotkeeper to act as a decentralized communications node. It unpacks payloads from external sources and dynamically weaves them into the site's navigation.
- **Key Rituals:** `rc-ingest.sh`, `rc-glue.sh`
- **Purpose:** Safely extract incoming `.tar.gz` payloads from the `messages-from-my-friends/` inbox and apply "navigation glue" so they are immediately accessible.

---

<!--
Limerick:
A javascript dev from the coast,
Tried to render our tombs with a post.
But we told him, "No way!
We use bash every day,
And Pandoc is what we love most."
-->
