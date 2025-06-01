---
title: "📡 rc-api.sh Reference"
slug: rc-api
template: rotkeeper-doc.html
version: "v0.2.3-pre"
updated: "2025-06-01"
description: "Experimental API utility for extracting or submitting Rotkeeper data between sessions. Not part of core ritual set."
tags:
  - rotkeeper
  - scripts
  - experimental
  - api
asset_meta:
  name: "rc-api.md"
  version: "v0.2.3-pre"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# 🌐 `rc-api.sh`

`rc-api.sh` fetches external assets, templates, and packs as defined in a local YAML config. It is used to keep remote parts of your tombsite up-to-date.

***

## 🔮 Intended Purpose

This script is designed to:
- Read a config file (`bones/config/remote-sources.yaml`)
- Download files from listed `url` entries
- Save them to `home/assets/remote/`
- Log actions and failures to `bones/logs/`

***

## 🔧 Planned Features

- Uses `yq` to parse source URLs
- `--dry-run` flag supported
- Can be extended to support JSON ingestion or content conversion

***

## 🧪 Example Invocation

```bash
./rotkeeper.sh api
```

***

## 📎 Notes

- This script is implemented and active in `v0.2.2`
- Useful for:
  - Fetching mascot bios from a remote repo
  - Pulling changelogs from GitHub APIs
  - Syncing tags or taxonomies from external indexes

***

## 📌 Related

- `rc-expand.sh` — Generates Markdown from BOM locally
- `rc-record.sh` — Tracks commit + system state
- `bones/logs/api-*` — Future location of fetch logs
- `remote-sources.yaml` — Defines the assets fetched by this script

***

<!-- Sora Prompt: "A shell script wrapped in a network cable, pinging the clouds for forgotten data. Mascots hover behind a firewall of JSON ghosts, watching the conversion begin." -->

<!-- 🎴 Limerick 1:
There once was an API script,
That fetched from each distant crypt.
With JSON in hand,
It mapped content to sand,
And left local tombs fully equipped.
-->

<!-- 🎴 Limerick 2:
When endpoints would vanish or sway,
rc-api would cheerfully play.
It grabbed every byte,
By day and by night,
So your docs never ran astray.
-->