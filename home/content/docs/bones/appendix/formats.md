---
title: "Formats Reference"
description: "Metadata, manifest, and decay format documentation."
version: "0.2.3-pre"
template: rotkeeper-doc.html
updated: "2025-05-31"
---

# 🧾 Formats Reference

This appendix details the file formats used throughout Rotkeeper’s decay rituals, including metadata manifests, asset logs, and rot tracking schemas.

## 📜 Metadata Manifest (BOM)

Usually stored as `rotkeeper-bom.yaml`. Contains:

```yaml
title: "The End of Indexing"
author: "Hollowroot"
date: "2025-05-31"
version: "v0.2.3"
tags:
  - decay
  - markdown
  - tomb
```

## 🧩 Asset Manifest

Generated during packing and logging. Example:

```yaml
files:
  - path: "index.md"
    hash: "sha256:deadbeef..."
    last_modified: "2025-05-30"
  - path: "notes/ritual-log.md"
    hash: "sha256:feedcafe..."
    size: 3442
```

## 🧬 Decay Log Format

Logged by `rc-scan.sh`. Example:

```yaml
status: "scanned"
timestamp: "2025-05-31T02:34:55Z"
decay:
  - file: "old.md"
    reason: "missing frontmatter"
    severity: "grave"
  - file: "intro.md"
    reason: "outdated checksum"
    severity: "light"
```

> ☠️ These formats may expand as rituals deepen, but backward compatibility shall be honored by the old gods of markdown.