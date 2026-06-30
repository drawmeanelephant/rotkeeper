---
title: "📥 rc-ingest.sh Reference"
slug: rc-ingest
version: "0.3.0"
updated: "2026-06-15"
description: "Unpacks decentralized payloads from the inbox and safely merges them into the content tree."
tags:
  - rotkeeper
  - scripts
  - ingestion
  - decentralized
asset_meta:
  name: "rc-ingest.md"
  version: "v0.3.0"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "All Rights Reserved"
---

<!--
🎨 Sora Prompt:
"A digital courier handing a glowing cube to a skeletal archivist, who carefully places it onto a towering, perfectly organized shelf of similar glowing cubes."
-->

# 📥 rc-ingest.sh

<!-- The rite of accepting foreign tombs -->
**Script Path:** `bones/scripts/rc-ingest.sh`

## Purpose
- Rotkeeper acts as a decentralized communications node. The `rc-ingest.sh` ritual is responsible for unboxing these incoming transmissions.
- It scans the `messages-from-my-friends/` directory for `.tar.gz` payloads.
- It safely extracts the content into isolated subdirectories within `home/content/messages/`.
- It dynamically avoids filename collisions by appending timestamps.
- It triggers the `rc-glue.sh` ritual automatically to weave the new content into the navigation hierarchy.

## CLI Interface
```bash
./rotkeeper.sh ingest
```

## Workflow Steps
1. **Inbox Scan**
   - Locates any `.tar.gz` files sitting in `messages-from-my-friends/`.
2. **Safe Extraction**
   - Unpacks the payload into a temporary directory.
   - Retroactively cleans up redundant documentation (`docs/`, `help/`) that the sender may have accidentally packed.
3. **Merging**
   - Moves the sanitized content into `home/content/messages/<payload-name>/`.
   - If the folder already exists, it appends the current Unix timestamp to avoid overwriting existing tombs.
4. **Vaulting**
   - Moves the original `.tar.gz` archive into `bones/ingested/` for permanent, unedited safekeeping.
5. **Applying Glue**
   - Fires `rc-glue.sh` to ensure the new folder is indexed and accessible.

## 🛣️ Navigation
- [Scripts Index](index.html)
- [Bones Home](../index.html)

<!--
Limerick:
A friend sent a tomb from afar,
All wrapped up tight in a tar.
The ingest script fired,
The contents rewired,
And now it’s the site's brightest star.
-->

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-06-30T17:53:41Z -->


### Bones of the Code
A script that blindly swallows whatever garbage is thrown into `messages-from-my-friends/`. It performs decentralized content extraction, playing the role of a gullible archivist.

### Restless Spirits
Unpacking unverified `.tar.gz` payloads is a classic recipe for disaster. It practically begs for zip-slip vulnerabilities and directory traversal attacks. And let's not even start on malicious frontmatter injections—it will gladly execute whatever cursed metadata it finds.

### Ritual Warnings
Do not trust your 'friends'. Verify the contents of archives before extracting them, or risk overwriting critical files with malicious payloads.
