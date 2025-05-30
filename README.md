

# 🪦 Rotkeeper

Ritual CLI for decaying flat-file systems and rendering tombs.
Rotkeeper is a modular Bash-based system for maintaining Markdown-based archives, verifying content integrity, and automating digital decay rituals.
This project is intentionally over-commented, offline-friendly, and not afraid of the void.

**Version:** `0.2.1`

---

## 📁 What It Does

- Renders Markdown to HTML using Pandoc and custom templates
- Tracks file digests and generates asset manifests
- Blesses commits with changelogs and metadata
- Packs full tomb archives for portable decay
- Supports `--dry-run` logic and offline use

---

## ⚙️ Requirements

- macOS or Linux with Bash 4+
- `pandoc`, `shasum`, `yq` (for YAML processing)
- Terminal that understands the grimness of existence

---

## 🔧 Quickstart

```bash
./rotkeeper.sh init      # Sets up the bones
./rotkeeper.sh expand    # Generates config/docs
./rotkeeper.sh render    # Converts Markdown to HTML
./rotkeeper.sh scan      # Checks file SHA256s
./rotkeeper.sh verify    # Compares to asset-manifest.yaml
```

For a full ritual, try:
```bash
./rotkeeper.sh all
```

---

## 📜 Folder Layout

```
.
├── bones/              # Logs, scripts, tombs, manifests
├── home/               # Source Markdown and config
├── output/             # Rendered HTML output
├── rotkeeper.sh        # The main dispatcher script
```

---

## ✨ Highlights

- Modular scripts in `bones/scripts/rc-*.sh`
- Audit-compliant with trap handling, dry-runs, and `main()`
- No unnecessary dependencies
- All output can be archived as `.tar.gz` tombs

---

## 🚧 Status

This is version `0.2.1`.
It is **functional but haunted**.
Most scripts work cleanly. Some logs whisper.
Perfect for archival weirdos, cursed sysadmins, and digital necromancers.

---

## 📦 Releasing

See the release archive:
https://rotkeeper.com/0.2.0.0.tar.gz

GitHub tag: [v0.2.1](https://github.com/drawmeanelephant/rotkeeper/releases)

---

## 💀 License

MIT. You may rot freely.

---

<!--
⚠️ This is a post-labor ritual CLI.
Do not manually maintain what entropy can clean for you.
-->