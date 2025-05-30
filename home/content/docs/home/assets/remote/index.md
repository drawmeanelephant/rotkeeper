

---
title: "Remote Assets"
slug: remote-assets
template: rotkeeper-doc.html
version: 0.2.2
---

<!-- asset-meta: { name: "remote-assets.md", version: "v0.2.2" } -->

# 🛰️ Remote Assets

This directory contains assets pulled from external sources using the `rc-api.sh` script.

These files are **not committed to the repository** and may vary depending on network availability and the contents of your `remote-sources.yaml`.

## 📍 Location

```
home/assets/remote/
```

## 🧩 What Goes Here

Files retrieved by `rc-api.sh`, such as:
- Remote templates (`.html`)
- Content packs or scripts (`.zip`, `.sh`)
- Icon sets or metadata files

## 🔄 How They Get Here

When you run:

```bash
./rotkeeper.sh api
```

The system:
- Reads your `bones/config/remote-sources.yaml`
- Downloads each listed URL
- Saves files to `home/assets/remote/`
- Logs success or failure to `bones/logs/rc-api-*.log`

## 🚫 Git Policy

These files are **git-ignored** and should not be version-controlled.

They are considered external runtime assets and subject to change.

## 🧾 Related

- [`rc-api.sh`](../../bones/scripts/rc-api) — fetches remote assets
- [`remote-sources.yaml`](../../../bones/config/remote-sources) — defines what to pull