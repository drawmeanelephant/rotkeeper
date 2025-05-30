---
title: "rc-api.sh"
template: rotkeeper-doc.html
subtitle: "Fetch, convert, or ingest remote content into tombs"
asset-meta:
  name: rc-api.md
  version: 0.2.0-pre
  tags: [scripts, api, ingestion, fetch, external]
---

# 🌐 `rc-api.sh`

`rc-api.sh` is an experimental script for fetching and transforming external data sources into tomb-ready formats. It is currently a stub and will be extended in future versions.

---

## 🔮 Intended Purpose

This script will allow you to:

- Pull JSON or YAML from remote sources (e.g., APIs, repos)
- Convert those files into usable Markdown
- Inject or update them into `home/content/` or `bones/`

---

## 🔧 Planned Features

- `--url <source>` — Target API or remote endpoint
- `--yaml` / `--json` — Force expected response format
- `--output <path>` — Destination file or folder
- `--header <key:val>` — Pass custom request headers
- `--convert` — Pipe output through a JSON→MD adapter
- `--dry-run` — Preview fetch + transformation plan

---

## 🧪 Example Invocation

```bash
bash bones/scripts/rc-api.sh \
  --url https://api.example.com/mascots \
  --json \
  --convert \
  --output home/content/mascots/from-api.md
```

---

## 📎 Notes

- This script is **not yet implemented**
- Useful for:
  - Fetching mascot bios from a remote repo
  - Pulling changelogs from GitHub APIs
  - Syncing tags or taxonomies from external indexes

---

## 📌 Related

- `rc-expand.sh` — Generates Markdown from BOM locally
- `rc-record.sh` — Tracks commit + system state
- `bones/logs/api-*` — Future location of fetch logs

---

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