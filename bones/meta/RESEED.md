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
- Modular Bash rituals (`rc-*.sh`)
- Offline-first rendering with Pandoc
- YAML asset manifest verification
- Git-integrated changelog tracking
- Tomb archiving (`.tar.gz` + `.json`)
- Standardized flags: `--dry-run`, `--verbose`, `main()`, `trap`

---

## 📁 Repo Structure

```
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
```

---

## 🌐 GitHub & Site

- **Repo**: [github.com/drawmeanelephant/rotkeeper](https://github.com/drawmeanelephant/rotkeeper)
- **Release Tag**: `dev-0.2.3`
- **Latest Archive**: [0.2.0.0.tar.gz](https://rotkeeper.com/0.2.0.0.tar.gz)

---

## 🔧 Recent Patches (`v0.2.1`)

- All scripts now source `rc-utils.sh`
- Standardized logging with `init_log` and `trap`
- Hardened asset manifest logic (skips empties and broken paths)
- `rc-api.sh` operational with `remote-sources.yaml`
- Doc coverage expanded for `home/`, `assets/`, and `scripts/`
- `rc-test.sh` supports dry-run and skips self
- All `.sh` scripts pass the local test ritual
- Audit sheet added: `rotkeeper-audit.md`

---

## 🛠 Patch Queue (`v0.2.4-dev`)

- `run()` hardened to remove `eval`
- `trap_err` added to all major scripts
- Debug and fallback logic improved in renderer
- Frontmatter normalization enforced
- Template validation added to `rc-render.sh`

---

## 📘 Documentation Status

- 81 pages render successfully via `rc-render.sh`
- Templates (`plainstone`, `rotkeeper-doc`, etc.) are functional
- Stubs remain in `home/content/docs/`
- Navigation still stitched manually
- Site build is manual (CI integration pending)
- `render-flags.yaml` governs logic + filter behavior
- Frontmatter compliance checks underway (esp. `asset-meta:`)

---

## 🧪 Known To-Dos

- CI workflow (ShellCheck + `rc-test.sh`)
- Fix `rc-assets.sh` test failure
- Template zhuzh (fonts, credits footer)
- Replace Bootstrap with Hiq (planned)
- Finalize Obsidian/VS Code export logic
- Automate `docs.rotkeeper.com` site generation

---

## 🧾 License & Fonts

- License: MIT
- Fonts: IBM Plex (OFL)
- Emoji: OpenMoji (CC BY-SA 4.0)

---

## 🧬 Snapshot: `v0.2.4-dev`

**Branch**: `dev-0.2.4`
**Status**: Active
**Buffer**: ~55% at snapshot
**Tone**: Sarcastic sysadmin. Doompoetry honored.

### ✅ Completed This Cycle

- `rc-render.sh` rewritten (no more `eval`)
- Archive/render bugs patched
- `rotkeeper-followups.md` added for long-range planning
- Template fallback warnings now log correctly
- Frontmatter fields enforced: `template`, `version`, `updated`
- Audit updated: all script states accurate
- Rendered output: 81 pages
- Archived: 1 tomb

### ⏭️ Next Touchpoint

- Reenter with audit + patch queue in sync
- Optionally begin refactor or ritual expansion
- `rc-render.sh` and `rc-api.sh` confirmed stable
- Consider linking manual/docbook pages into `rc-help.sh` or contributor docs

---

## 🧷 Invocation Notes

- `rc-render.sh` is stable
- `rc-lint.sh` still a stub (audit it)
- Some test files untracked (pending decision)
- Docs normalized — no active metadata rot
- GitHub Projects: undead, unsummoned

---

*Rotkeeper never dies. It forks.*