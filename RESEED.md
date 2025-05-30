---
rotkeeper_reseed: v0.2.1
updated: 2025-05-30
---

# 🧬 Rotkeeper Reseed — v0.2.1

This document serves as a ritual continuity point for new sessions, threads, or assistants. It captures the current state of the Rotkeeper project, ensuring future helpers may rise without confusion or decay.

---

## 🪦 Project Summary

**Name**: Rotkeeper
**Version**: `v0.2.1` (live on GitHub)
**Type**: Ritual CLI for decaying flat-file systems
**Core Features**:
- Bash modular scripts (`rc-*.sh`)
- Offline-first doc rendering (`render`, Pandoc-based)
- YAML asset manifest verification
- Git changelog tracking
- `.tar.gz` and `.json` tomb archiving
- `--dry-run`, `main()`, `trap` support

---

## 📁 Repo Structure

rotkeeper/
├── bones/              # Scripts, logs, templates, manifests, archive
├── home/content/       # Markdown source content
├── output/             # Rendered HTML
├── SUPPORT/            # Local-only staging (gitignored)
├── rotkeeper.sh        # Main dispatcher
├── README.md           # Current and correct
├── CREDITS.md          # Asset attribution (IBM Plex, OpenMoji)
├── .gitignore          # Enforced (SUPPORT/, logs/, .DS_Store, etc)
└── .github/            # Future CI workflows

---

## 🌐 GitHub & Site

- **GitHub Repo**: https://github.com/drawmeanelephant/rotkeeper
- **Release Tag**: [`v0.2.1`](https://github.com/drawmeanelephant/rotkeeper/releases/tag/v0.2.1)
- **Archive**: https://rotkeeper.com/0.2.0.0.tar.gz

---

## 🔧 Recent Patches (v0.2.1)

- `rc-scan.sh`: SHA skipping logic, stable report output
- `rc-verify.sh`: `--regen` now functional
- `rc-assets.sh`: manifest output even when empty
- Cleaned template outputs, log folder logic, trap coverage

---

## 🛠 Patch Queue (planned for v0.2.2)

- `rc-bless.sh`: write real git changelogs to `bones/logs/changelog.md`
- `rc-record.sh`: stamp commit + timestamp
- `rc-assets.sh`: verify manifest accuracy under `--dry-run`
- `rc-verify.sh`: SHA256 regression check consistency
- `rc-audit.sh`: enforce `asset-meta:` frontmatter block
- Shared logic: extract to `rc-utils.sh`
- Normalize `main()`, `trap`, and `check_deps` across scripts
- Patch `rc-render.sh` for frontmatter validation
- Add `rotkeeper-audit.md` checklist to track ritual stability

---

## 📘 Docs Status

- 67 pages render successfully via `render`
- Templates work (`plainstone`, `rotkeeper-doc`, etc.)
- Some stubs remain in `home/content/docs/`
- Navigation needs manual stitching
- Site build/deploy done manually (not yet CI-linked)
- `render-flags.yaml` governs template logic + filter control
- Frontmatter compliance checks in progress (`asset-meta:` focus)

---

## 🧪 Known To-Dos

- CI workflow (ShellCheck + `rc-test.sh`)
- `rc-assets.sh` test script failure fix
- Template zhuzh (fonts, credits footer)
- Replace Bootstrap with Hiq (planned)
- Finalize Obsidian/VScode project export logic
- Automate `docs.rotkeeper.com` generation

---

## 🧾 License & Fonts

- Licensed MIT
- Fonts: IBM Plex (OFL)
- Emoji: OpenMoji (CC BY-SA 4.0)

---

## 🧬 Next Ritual Thread

To continue this project in a new session:
> Refer to `reseed.md` and let your assistant read this file to restore context.

You may safely archive this file in `bones/meta/` or the repo root.

---

*Rotkeeper never dies. It forks.*