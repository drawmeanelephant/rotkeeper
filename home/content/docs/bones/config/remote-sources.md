---
title: "Remote Sources Config"
slug: remote-sources
template: rotkeeper-doc.html
version: 0.2.2
---

<!-- asset-meta: { name: "remote-sources.md", version: "v0.2.2" } -->

# 🌐 Remote Sources Config

This configuration file lists remote assets and templates that may be fetched by `rc-api.sh`.

It is written in YAML and lives at:

```
bones/config/remote-sources.yaml
```

## 📥 Structure

Each source block defines:
- `url`: the full URL to the remote file
- `filename`: the local filename it will be saved as

Example:

```yaml
sources:
  - url: "https://assets.rotkeeper.com/templates/plainstone.html"
    filename: "plainstone.html"
  - url: "https://assets.rotkeeper.com/scripts/rc-bless.sh"
    filename: "rc-bless.sh"
```

## 🧪 Used By

- `rc-api.sh`: pulls and logs these files into `home/assets/remote/`
- `rc-expand.sh` or custom workflows may reference these post-fetch

## ⚠️ Notes

- This file is **local-only** and may be customized per environment.
- Files listed here are not automatically executed or rendered — they must be processed manually.

## 🧾 Related

- `rc-api.sh`: script that fetches these sources
- `home/assets/remote/`: destination for downloaded files