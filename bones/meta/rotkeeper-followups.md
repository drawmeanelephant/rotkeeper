

---
title: "Rotkeeper Followups — v0.2.4-dev"
description: "Tracking unresolved questions, next-phase tasks, and future rot expansions."
version: "0.2.4-dev"
template: rotkeeper-doc.html
updated: "2025-05-31"
---

# 🧩 Rotkeeper Followups — v0.2.4-dev

These items arose from peer review, audit reflection, and post-ritual observation after `v0.2.3-pre`.

---

## ✅ 1. Frontmatter Rules

- [ ] Formalize allowed keys (`title`, `slug`, `template`, `version`, `updated`)
- [ ] Define required/optional fields
- [ ] Decide whether `tags` or `aliases` will be supported long-term
- [ ] Document in `rotkeeper-frontmatter-spec.md` or render into docbook

---

## 🧰 2. YQ Usage & YAML Parsing

- [ ] Create `require_yq()` helper in `rc-utils.sh`
- [ ] Refactor all `yq`-based logic to consistent v4 syntax
- [ ] Add fallback message or check if missing
- [ ] Consider `rc-check.sh` to validate YAMLs like `render-flags.yaml`, `bom.yaml`

---

## ♻️ 3. Rebuildable Output

- [ ] Define what should be wiped by `rc-reset.sh` (archives, logs, reports, etc.)
- [ ] Create `rotkeeper-rebuild-guide.md` for documenting disposable vs persistent files
- [ ] Add a `--clean` or `--purge` mode to render pipeline?

---

## 🧪 4. Script Flags (`--help`, `--dry-run`, `--debug`)

- [ ] Ensure all new scripts implement shared `parse_flags()` + `show_help()`
- [ ] Move flag logic to `rc-utils.sh`
- [ ] Optionally add a linter to scan for flag omissions

---

## ✍️ 5. Changelog Blessings

- [ ] Document canonical changelog entry format
- [ ] Add example/comment to `rc-bless.sh`
- [ ] Possibly extract logic into reusable blessing template

---

## ⚰️ 6. Tomb Archive Structure

- [ ] Document required internal structure (`metadata.json`, layout, manifest)
- [ ] Draft a `tomb.yaml` schema or embed a template into `rc-pack.sh`
- [ ] Create `rotkeeper-tomb-format.md`

---

## 📜 7. Manifest Distinction

- [ ] Clarify difference between `bones/manifest.txt` and asset manifest
- [ ] Define when each is updated and by which script
- [ ] Document in docbook or stub `rc-check-manifests.sh`

---

## 🔧 8. Script Sourcing Conventions

- [ ] Ensure all scripts source `rc-utils.sh`
- [ ] Create minimal template for new scripts (`rc-template.sh`)
- [ ] Optional: linter for missing `source` call or duplicate functions

---

## 🧼 9. Reseed Workflow

- [ ] Define what reseed means: full init from tomb, fresh manifest, logs?
- [ ] Implement `--reseed` in `rc-init.sh`
- [ ] Possibly create `rc-init-full.sh` for one-shot reboots

---

## 📖 10. Help & Onboarding Docs

- [ ] Create `rotkeeper-first-ritual.md` as a welcoming walkthrough
- [ ] Draft `rc-help.sh` to route users to all `--help` outputs
- [ ] Link onboarding doc to all tomb output / render HTML

```

This will track the next full cycle of rotkeeper growth and eliminate future drift across branches or tooling sessions.