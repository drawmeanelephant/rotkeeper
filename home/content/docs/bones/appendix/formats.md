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
# Document-level metadata for a tomb or artifact
title: "The End of Indexing"
author: "Hollowroot"
date: "2025-05-31"        # ISO 8601 format preferred
version: "v0.2.3"          # Semver or ritual-tagged version
tags:                      # Keyword classification
  - decay
  - markdown
  - tomb
```

## 🧩 Asset Manifest

Generated during packing and logging. Example:

```yaml
# Output from tomb packing or logging utilities
files:
  - path: "index.md"                  # Relative path to asset
    hash: "sha256:deadbeef..."        # Full SHA256 digest
    last_modified: "2025-05-30"       # File timestamp (ISO 8601 date)
  - path: "notes/ritual-log.md"
    hash: "sha256:feedcafe..."
    size: 3442                        # Optional: file size in bytes
```

## 🧬 Decay Log Format

Logged by `rc-scan.sh`. Example:

```yaml
# Generated by rc-scan.sh or related rituals
status: "scanned"
timestamp: "2025-05-31T02:34:55Z"     # ISO 8601 datetime (UTC suggested)
decay:
  - file: "old.md"
    reason: "missing frontmatter"
    severity: "grave"                # Enum: light, moderate, grave
  - file: "intro.md"
    reason: "outdated checksum"
    severity: "light"
```

> ☠️ These formats may expand as rituals deepen, but backward compatibility shall be honored by the old gods of markdown.