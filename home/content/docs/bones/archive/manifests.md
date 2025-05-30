

---
title: "📋 Manifest Backups"
slug: manifests
template: rotkeeper-doc.html
version: "v0.1.0"
---
<!-- asset-meta:
     name:        "manifests.md"
     version:     "v0.1.0"
     description: "Backups of asset-manifest.yaml versions"
     author:      "Rotkeeper Ritual Council"
-->

# 📋 Manifest Backups

<!-- The council’s ledger of manifest evolution -->

The `manifest-backups` archive holds previous snapshots of `asset-manifest.yaml` captured by `rc-bless.sh`. Each backup reflects a blessed tomb state.

## Location

- Directory: `archive/manifests/`
- Naming: `asset-manifest.yaml.YYYYMMDD-HHMMSS.bak`

## Contents

- **YAML backups**: full copies of the manifest at each blessing.
- **Change summaries**: optional `.md` files summarizing key differences.

## 🧭 Usage

<!-- How to restore or inspect backups -->

To list available backups:

```bash
ls archive/manifests/asset-manifest.yaml.*.bak
```

To restore a specific backup:

```bash
cp archive/manifests/asset-manifest.yaml.20250527-121314.bak asset-manifest.yaml
```

## 🛣️ Navigation

<!-- Quick links within Archive -->
- [Archive Index](archive/index.html)
- [Scan Reports](archive/scan-reports.html)
- [Session Records](archive/records.html)

## Future Additions

<!-- Aspirational rites for manifest backups -->
- Automate cleanup of backups older than N days.
- Embed diff metadata alongside each backup.
- Support compressed backup formats (e.g., `.tar.gz`).