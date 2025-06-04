# 🪦 Rotkeeper

[![Release](https://img.shields.io/github/v/release/drawmeanelephant/rotkeeper?sort=semver)](https://github.com/drawmeanelephant/rotkeeper/releases)

*“What lives in `/bones/` may yet render again.”*

Rotkeeper is a haunted CLI suite for Markdown morticians, static site cryptkeepers, and ritual sysadmins.
Written in modular Bash, it automates the slow decay and archival rebirth of your flat-file knowledge hoards.
Every script is annotated for post-apocalyptic readability. No network required. Only reverence.

**Current Version:** `v0.2.6-dev`

***

## 📁 What It Does

- Renders Markdown to HTML using Pandoc and custom templates
- Tracks file digests and generates asset manifests
- Packs and unpacks tomb archives with embedded metadata
- Supports `--dry-run` logic and offline use
- Expands YAML-defined tombs into structured markdown pages
- Aggregates documentation into scriptbook, docbook, and webbook via `rc-book.sh`

***

## ⚙️ Requirements

- macOS or Linux with Bash 4+
- `pandoc`, `shasum`, `yq` (for YAML processing)
- Terminal that understands the grimness of existence

***

## 🔧 Quickstart

```bash
./rotkeeper.sh init      # Sets up the bones
./rotkeeper.sh expand    # Generates config/docs
./rotkeeper.sh render    # Converts Markdown to HTML
./rotkeeper.sh book      # Aggregates Markdown into scriptbook/docbook/webbook
./rotkeeper.sh scan      # Checks file SHA256s
./rotkeeper.sh verify    # Compares to asset-manifest.yaml
./rotkeeper.sh test      # Runs utility test suite (Bats)
```

For a full ritual, try:
```bash
./rotkeeper.sh all
```

***

## 📜 Folder Layout

```
.
├── bones/              # Logs, scripts, tombs, manifests
├── home/               # Source Markdown and config
├── output/             # Rendered HTML output
├── rotkeeper.sh        # The main dispatcher script
```

***

## ✨ Highlights

- Modular scripts in `bones/scripts/rc-*.sh` (excluding removed scripts; shared logic centralized in `rc-utils.sh`)
- Audit-compliant with trap handling, dry-runs, and `main()`
- No unnecessary dependencies
- All output can be archived as `.tar.gz` tombs

Supports logging to `bones/logs/`, dry-run execution, and manifest-aware audits

- Includes Bats-based utility test coverage (`rc-utils.bats`)

***

## 🚧 Status

This is version `v0.2.5`.
It is **functional but haunted**.
Most scripts work cleanly. Some logs whisper.
Frontmatter validation, content expansion, and logging are now stable across core rituals.
Perfect for archival weirdos, cursed sysadmins, and digital necromancers.

***

## 📦 Releasing

GitHub tag: [v0.2.5](https://github.com/drawmeanelephant/rotkeeper/releases/tag/0.2.5)

***

## 💀 License

MIT. You may rot freely.

***

<!--
⚠️ This is a post-labor ritual CLI.
Do not manually maintain what entropy can clean for you.
-->