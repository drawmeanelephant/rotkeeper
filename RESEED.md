---
rotkeeper_reseed: v0.2.3
updated: 2024-06-06
---

# 🧬 Rotkeeper Reseed — v0.2.3

This document serves as a ritual continuity point for new sessions, threads, or assistants. It captures the current state of the Rotkeeper project, ensuring future helpers may rise without confusion or decay.

---

## 🪦 Project Summary

**Name**: Rotkeeper
**Version**: `v0.2.3-pre` (in development)
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
- **Release Tag**: `dev-0.2.3`
- **Archive**: https://rotkeeper.com/0.2.0.0.tar.gz

---

## 🔧 Recent Patches (v0.2.1)

- All scripts now source `rc-utils.sh`
- Logging standardized (`init_log`, `trap`)
- Asset manifest logic hardened (empty emits, bad paths skipped)
- `rc-api.sh` now functional with `remote-sources.yaml`
- Doc coverage expanded for `home/`, `assets/`, `scripts/`
- Test suite (`rc-test.sh`) supports dry-run and skips itself
- All `.sh` scripts pass local test ritual

---

## 🛠 Patch Queue (planned for v0.2.3)

- Expand `rc-api.sh` with extract + post-fetch support
- Standardize `--dry-run` and `--help` flags across all scripts
- Build `.vscode/` onboarding config for dev environment
- Improve `rc-render.sh` frontmatter validation
- Begin `rc-pack.sh` tomb metadata enhancements
- Draft `.woa/` integration (optional WebObjects mode)

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

- Audit sheet: `rotkeeper-audit.md` added for tracking script state

---

*Rotkeeper never dies. It forks.*