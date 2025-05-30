---
title: Asset Manifest
template: rotkeeper-doc.html
subtitle: YAML Index of Static Assets
asset-meta:
  name: "asset-manifest.md"
  version: "v0.2.0-pre"
  type: "docs"
  tags: [assets, manifest, yaml, rotkeeper]
---

# 🧾 Asset Manifest

Rotkeeper catalogs all static assets into a structured YAML file:  
`bones/asset-manifest.yaml`

This manifest is used for:

- Verifying file presence and integrity (`rc-verify.sh`)
- Generating accessible file listings
- Supporting template references to icons, images, fonts, etc.

## 📁 What Gets Tracked

`rc-assets.sh` recursively scans:

- `home/assets/`
- `home/themes/`
- `home/icons/`

Each file is registered in the manifest with:

- Relative path
- SHA256 checksum
- Last modified time
- Optional alt text (if annotated)

## 🧬 Sample Manifest Entry

```yaml
- path: home/assets/logo.svg
  sha256: "a8b91c847d94b..."
  size: 3821
  modified: 2025-05-27T11:19:00
  alt: "Filed Systems logo (monochrome)"
```

## 🛠 Usage in the Pipeline

This manifest is consumed by:
	•	rc-verify.sh: verifies file hashes and presence
	•	rc-pack.sh: determines what assets to include
	•	rc-scan.sh: detects orphaned or undocumented files

## 🧼 Cleaning the Manifest
	•	Run rc-assets.sh --prune to remove entries for deleted files
	•	Use --dry-run to preview changes before updating



Sora Prompt:
"A glowing YAML scroll held by a tiny archivist bot, surrounded by floating icons, asset folders, and checksum sigils." -->
