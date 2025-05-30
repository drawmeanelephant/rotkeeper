---
title:  "Rotkeeper TODO"
slug: todo
template: rotkeeper-doc.html
version: 0.2.2-pre
---
<!-- asset-meta: { name: "todo.md", version: "v0.2.2-pre" } -->

# ✅ Rotkeeper Build TODO

Tracking next steps, cleanup tasks, and ritual enforcement plans.

---

## 🧠 Rotkeeper v0.2.0 Hardening Checklist

This section consolidates the status, review, and next-phase plan for your CLI system as of late v0.1.9.9.

### ✅ What’s Working Well

1. **Modular Scripts**
   Every major ritual step has its own `rc-*.sh` handler—expand, render, pack, scan, bless, assets, record, status, reseed, cleanup, docs-fix, audit, API pulls, init—so it’s easy to target individual phases.

2. **Consistent Logging Pattern**
   Almost every script defines a `log()` helper and traps cleanup on exit, writing to `bones/logs/…`. That gives you a uniform audit trail.

3. **Flag-Driven Modes**
   Many scripts already support `--dry-run`, `--self`, `--manifest-only`, `--verbose`, etc., which will let you test and fine-tune without accidentally mutating real state.

4. **Self-Containment & Self-Replication**
   Some scripts even copy themselves or pack the whole suite for bone-deep portability (e.g. `rc-reseed.sh` and your earlier dump mechanism).

5. **Poetic Ritual Flavor**
   Limericks, glyphs, and atmospheric comments make this fun to read and maintain—great for onboarding new cultists.

---

### 🔧 Areas to Harden

1. **Unify Flag Parsing & Helpers**
   Extract a shared lib (`bones/scripts/rotkeeper-lib.sh`) for `parse_flags`, `log`, `require_cmds` etc. Reduce boilerplate and unify behavior.

2. **Standardize Exit Codes**
   Use:
   - `0` = all good
   - `1` = minor issues (missing files, warnings)
   - `2` = critical failure or missing dependency

3. **Centralize Config Paths**
   Move shared path definitions to a config file or sourced script (`rotkeeper-paths.sh`).

4. **Simplify Script Seeding**
   Replace BOM-script stub loop with a prebuilt `scripts.tar.gz` to unpack on expand/init.

5. **Finish Scan & Audit Tools**
   Implement `rc-scan.sh` and `rc-audit.sh` fully per BOM specs, enabling full digest/frontmatter validation.

6. **Add Tests**
   Write a `tests/` harness that runs init→render→scan→pack, catching regressions.

7. **Update Docs**
   Polish `configuration-reference.md`, `README.md`, and rendered output to reflect current CLI workflows and flags.

---

### 🎯 Next Concrete Steps

1. Extract and source a common helper for flags, logging, and dependency checks.
2. Implement `rc-scan.sh` metadata collection & report generation.
3. Refactor `rc-expand.sh` to unpack a bundled script archive.
4. Write a smoke-test harness that validates full init→pack flow.
5. Update `docs/` to reflect v0.2.0 logic and structure.
6. Enable Pandoc-driven in-page Table of Contents via `--toc` flag and update `render-flags.yaml`.
7. Inject `asset-meta` JSON into rendered HTML pages by extending the Pandoc template.

---

## 🔧 Manifest Hygiene

- [ ] Deduplicate `manifest.txt` entries during all phases (`init`, `inject`, `render`)
- [ ] Add `sort -u` pass after each `log_manifest` call
- [ ] Ensure `manifest.txt` is not polluted by multiple identical entries

---

## 📦 Archive & Packing Cleanliness

- [x] Validate `.tar.gz` tomb contents (✅ no duplicates)
- [ ] Improve log output: clarify repeated lines vs packed entries
- [ ] Add post-pack message summarizing tomb contents count

---

## 🧼 Script Cleanup & Branding

- [x] Rename `peer-consensus.sh` → `rotkeeper.sh`
- [x] Update internal strings and help output to match new identity
- [ ] Delete or archive `ritual-copy-assets.sh`
- [ ] Delete or archive legacy `render.sh`, `ASSETELLA.sh` stubs
- [ ] Migrate any logic worth keeping into `rc-*` scripts
- [ ] Annotate TODO list with hidden Sora prompt placeholders for future tone-setting.

---

## 🔍 Script Compliance Audit

- [ ] Ensure all `rc-*.sh` scripts define `main()` and use `trap` safely
- [ ] Apply `set -euo pipefail` to every script
- [ ] Move shared logic to `rc-utils.sh` and source it
- [ ] Use `check_deps` or equivalent in all scripts
- [ ] Sanity-check argument handling for `--dry-run`, `--help`, `--verbose`

---

## 🪦 Output Enhancements

- [ ] Create HTML `/index.html` showcasing rendered pages
- [ ] Inject CSS, JS, or icon assets via `rc-assets.sh`
- [ ] Add meta headers or banners to rendered output

---

## 🧠 Docs Polish & Metadata Injection

- [x] Write docs for: bless, scan, record
- [x] Link all pages into `index.md`
- [ ] Add version tags to top of all rendered `.html` files
- [ ] Ensure every file in `scripts/` and `templates/` has an `asset-meta` block

---

## 🔁 Ritual Logging

- [ ] Improve clarity of bootstrap logs in `rotkeeper.sh`
- [ ] Add tomb version to every log bundle
- [ ] Consider emitting a ritual summary `.md` after pack

---

## 🧾 Audit Tools & Metadata Rituals

- [ ] Create `rotkeeper-audit.md` for checklist-based rotkeeper health tracking
- [ ] Patch `rc-render.sh` to validate YAML frontmatter
- [ ] Enforce `asset-meta:` in all Markdown via `rc-audit.sh`
- [ ] Add failure modes to `rc-audit.sh` for missing frontmatter

---

## 🌐 Optional

- [ ] Generate real Markdown personas for Patchy, Bricky, etc.
- [ ] Add 404.html and weird mascot lore into rendered output
- [ ] Link all tombs to tomb index page

---


---

## 🧃 Script Stub Logic

- [ ] Only create script stubs if file does not exist or still contains `# TODO`
- [ ] Prevent overwriting functional scripts during `rotkeeper init`
- [ ] Log clearly whether a stub was created vs. a real script preserved
- [ ] Consider `.scripts-seeded` flag to skip future stub generation unless forced

## 🧼 CSS & Template Cleanup

- [x] Bootstrap removal task moved to `template-debt.md`
- [ ] Ensure templates use Hiq or pure CSS only
- [ ] Purge Bootstrap references from `render-flags.yaml` and `.html` comments

Last updated: 2025-05-13
<!--
LIMERICK

A checklist that kept getting longer,
Each ritual entry grew stronger.
Though nothing was done,
The logs showed it won—
And the tombshell grew buggier, not wronger.

SORA PROMPT

"a decaying checklist on old paper, taped to a terminal, slowly being updated by a ghostly archivist with a flickering cursor"
-->