---
rotkeeper_reseed: v0.2.4-dev
updated: 2025-05-31
---

# 🧬 Rotkeeper Reseed — v0.2.4-dev

This document serves as a ritual continuity point for new sessions, threads, or assistants. It captures the current state of the Rotkeeper project, ensuring future helpers may rise without confusion or decay.

---

## 🪦 Project Summary

**Name**: Rotkeeper
**Version**: `v0.2.4-dev` (in development)
**Type**: Ritual CLI for decaying flat-file systems
**Core Features**:
- Bash modular scripts (`rc-*.sh`)
- Offline-first doc rendering (`render`, Pandoc-based)
- YAML asset manifest verification
- Git changelog tracking
- `.tar.gz` and `.json` tomb archiving
- `--dry-run`, `--verbose`, `main()`, `trap` support

***

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

***

## 🌐 GitHub & Site

- **GitHub Repo**: https://github.com/drawmeanelephant/rotkeeper
- **Release Tag**: `dev-0.2.3`
- **Archive**: https://rotkeeper.com/0.2.0.0.tar.gz

***

## 🔧 Recent Patches (v0.2.1)

- All scripts now source `rc-utils.sh`
- Logging standardized (`init_log`, `trap`)
- Asset manifest logic hardened (empty emits, bad paths skipped)
- `rc-api.sh` now functional with `remote-sources.yaml`
- Doc coverage expanded for `home/`, `assets/`, `scripts/`
- Test suite (`rc-test.sh`) supports dry-run and skips itself
- All `.sh` scripts pass local test ritual

***

## 🛠 Patch Queue (v0.2.4-dev)

- Harden `run()` to remove `eval` (done)
- Add `trap_err` to all major scripts (done)
- Render debug and fallback logic improved
- Docs frontmatter normalized
- Template validation added to `rc-render.sh`

***

## 📘 Docs Status

- 81 pages render successfully via `render`
- Templates work (`plainstone`, `rotkeeper-doc`, etc.)
- Some stubs remain in `home/content/docs/`
- Navigation needs manual stitching
- Site build/deploy done manually (not yet CI-linked)
- `render-flags.yaml` governs template logic + filter control
- Frontmatter compliance checks in progress (`asset-meta:` focus)

***

## 🧪 Known To-Dos

- CI workflow (ShellCheck + `rc-test.sh`)
- `rc-assets.sh` test script failure fix
- Template zhuzh (fonts, credits footer)
- Replace Bootstrap with Hiq (planned)
- Finalize Obsidian/VScode project export logic
- Automate `docs.rotkeeper.com` generation

***

## 🧾 License & Fonts

- Licensed MIT
- Fonts: IBM Plex (OFL)
- Emoji: OpenMoji (CC BY-SA 4.0)

***

- Audit sheet: `rotkeeper-audit.md` added for tracking script state

***

*Rotkeeper never dies. It forks.*

***

## 🧬 v0.2.4-dev — Snapshot for Reseed

**Branch:** dev-0.2.4
**Status:** Active
**Buffer:** ~55% at time of reseed
**Tone:** Sarcastic sysadmin. Doompoetry respected.

### Completed This Cycle:
- `rc-render.sh` rewritten, eval removed
- Archive + render logic debugged and patched
- `rotkeeper-followups.md` introduced as long-range taskboard
- Template fallback warnings now logged
- Frontmatter fields enforced: `template`, `version`, `updated`
- Audit updated: all script states reflected accurately
- Rendered output: 81 pages, 1 tomb archived

### Next Touchpoint:
- Reenter with audit and patch queue ready
- Optional: begin refactor or ritual expansion
- `rc-render.sh` and `rc-api.sh` stable
- Consider linking manual/docbook pages into future `rc-help.sh` or contributor docs

_Session sealed by tombkeeper at 2025-05-31_