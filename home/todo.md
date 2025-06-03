# ✅ Rotkeeper Task Ledger

This document consolidates audit items, peer review critiques, and all known TODOs into one canonical list for `v0.2.5-pre`.

---

## 🧠 Core Ritual Hardening

- [ ] Remove `eval` from all scripts (done in `rc-render.sh`)
- [ ] Implement or purge stub: `rc-unpack.sh`
- [ ] Complete `rc-lint.sh` (currently stub)
- [ ] Add `--version` flag to all `rc-*.sh` scripts
- [ ] Replace all HTML regex parsing in `rc-assets.sh` with a proper parser (`pup`, `htmlq`, or awk)

---

## 📦 Archive + Pack Behavior

- [ ] Validate `.tar.gz` contents before finalizing
- [ ] Add post-pack tomb summary to logs
- [ ] Enforce unique archive names (`%Y-%m-%d_%H%M%S`)
- [ ] Clarify policy on tomb versioning: does it invalidate old `.tar.gz` archives?
- [ ] Fix archive naming collisions — consider fallback to Unix epoch
- [ ] Add fallback recovery logic if `tar` or `gzip` fail in `rc-pack.sh`
- [ ] Generate `tomb-replay.sh` during each render for ritual replay support

---

- [ ] Write `workflow.md` explaining full init → pack cycle
- [ ] Define and document the full ritual chain in `workflow.md` (`init → expand → render → pack → scan → reseed`)
- [ ] Add schema docs for: `rotkeeper-bom.yaml`, `render-flags.yaml`, `asset-manifest.yaml`
- [x] Improve internal linking between all ritual docs, config references, and glossary
- [ ] Ensure all index and navigation pages include backlinks to the root or documentation overview
- [x] Ensure rc-*-book.sh emit file inclusion count and warnings on empty
- [ ] Build rc-pdfbook.sh to generate PDF from merged docbook/webbook
- [ ] Optionally strip internal frontmatter blocks for clean PDF output
- [ ] Add config-driven style selector for future PDF themes
- [ ] Add Mermaid.js diagram to `README.md` or `quickstart-guide.md`
- [ ] Build a glossary/index from `asset-meta.title`, `slug`, and `template`
- [ ] Add `--tutorial` support to `rc-init.sh` that scaffolds a mock tomb
- [ ] Add templated changelog entry support via `rc-scribe.sh` placeholder
- [ ] Distinguish source/generated/rendered docs via frontmatter flags

---

- [ ] Confirm deleted files are purged from manifest
- [ ] Define and enforce `asset-meta:` schema beyond presence (field types, required keys)

---

## 🪵 Logging + CI

- [ ] Add GitHub Action for lint + `rc-test.sh`
- [ ] Log tomb version in `yougood.brah` on every invocation
- [ ] Generate Markdown summary after each `pack`
- [ ] Validate version presence and fallback behavior for `jq`, `pandoc`, `yq`
- [ ] Define recovery behavior if `tar`/`gzip` fail during `pack`

---

## 🧪 Testing & Validation

- [ ] Build a real test suite using `bats` or `.test.sh`
- [ ] Write integration test for full CLI flow
- [ ] Add unit tests for `rc-utils.sh`
- [ ] Mock `pandoc`, `curl`, `yq` for failure testing
- [ ] Validate that `rc-utils.sh` unit tests cover all helper functions
- [ ] Add smoke test for full CLI flow (`init → render → scan → pack`)
- [ ] Expand `rc-test.sh` to compare logs and output against known-good fixtures
- [ ] Create `test/` directory to hold all test rituals and golden fixtures

---

## 🧼 Script Cleanup & Debt Burial

- [ ] Archive `peer-reviews.md` into `bones/meta/peer-review-sarcophagus.md`
- [ ] Purge legacy `render.sh`, `ASSETELLA.sh`, etc.
- [ ] Only generate stub scripts if file is empty or has `# TODO`
- [ ] Enhance ritual metaphors with optional CLI glyphs and epitaphs
- [ ] Add helper for generating `--help` from a `.help.txt` or frontmatter-driven block per script

---

## 📎 Template & Asset Work

- [ ] Remove Bootstrap, switch to HiQ
- [ ] Clean up template footers (add credits, version stamp)
- [ ] Ensure `asset-meta` block exists in every HTML/CSS/JS file
- [ ] Add option to inject `asset-meta` JSON into rendered HTML via Pandoc filter
- [ ] Add optional Mermaid diagram injection into book outputs via `rc-book.sh` or frontmatter flag

---

- [ ] Document `rc-expand.sh` invocation patterns
- [ ] Clarify `rc-record.sh` scope (script emitter only)

---

## 🗺️ Future Options

- [ ] Auto-generate `docs.rotkeeper.com` from output/
- [ ] Create `rc-dashboard.sh` to show rot status in a single report
- [ ] Support rotkeeper personas in rendered footers
- [ ] Add weird mascot lore footer or 404 page entry
- [ ] Load `.ritual.yaml` workflows via `rotkeeper.sh perform <ritual>`
- [ ] Add plugin support via sourced scripts in `plugins.d/`
- [ ] Formalize directory layout in `README.md` or echo from `rc-init.sh`
- [ ] Add optional i18n frontmatter fields (`lang`, `translation_of`)
- [ ] Define CLI documentation standard for optional flags and `--help` output across rituals
- [ ] Document expectations for creating new `rc-*.sh` rituals

---

_Last updated by tombkeeper: 2025-06-01 — seedling branch: v0.2.5-pre_

## 🧠 Rotkeeper v0.2.0 Hardening Checklist

This section consolidates the status, review, and next-phase plan for your CLI system as of late v0.1.9.9.

### ✅ What’s Working Well

1. **Modular Scripts**
   Every major ritual step has its own `rc-*.sh` handler—expand, render, pack, scan, assets, record, status, reseed, cleanup, docs-fix, audit, API pulls, init—so it’s easy to target individual phases.

2. **Consistent Logging Pattern**
   Almost every script defines a `log()` helper and traps cleanup on exit, writing to `bones/logs/…`. That gives you a uniform audit trail.

3. **Flag-Driven Modes**
   Many scripts already support `--dry-run`, `--self`, `--manifest-only`, `--verbose`, etc., which will let you test and fine-tune without accidentally mutating real state.

4. **Self-Containment & Self-Replication**
   Some scripts even copy themselves or pack the whole suite for bone-deep portability (e.g. `rc-reseed.sh` and your earlier dump mechanism).

5. **Poetic Ritual Flavor**
   Limericks, glyphs, and atmospheric comments make this fun to read and maintain—great for onboarding new cultists.

***

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

8. Standardize parse_flags() usage (support associative arrays) across all rc-*.sh scripts.
9. Ensure every script sources rc-env.sh and rc-utils.sh, calls init_log, uses require_bins, and wraps external calls in run().
10. Add --dry-run support to rc-book.sh (and any scripts lacking it).
12. Create rc-env.sh to centralize root path variables (bones/, output/, home/, etc.).
***

### 🎯 Next Concrete Steps

1. Extract and source a common helper for flags, logging, and dependency checks.
2. Implement `rc-scan.sh` metadata collection & report generation.
3. Refactor `rc-expand.sh` to unpack a bundled script archive.
4. Write a smoke-test harness that validates full init→pack flow.
5. Update `docs/` to reflect v0.2.0 logic and structure.
6. Enable Pandoc-driven in-page Table of Contents via `--toc` flag and update `render-flags.yaml`.
7. Inject `asset-meta` JSON into rendered HTML pages by extending the Pandoc template.

***

## 🔧 Manifest Hygiene

- [ ] Deduplicate `manifest.txt` entries during all phases (`init`, `inject`, `render`)
- [ ] Add `sort -u` pass after each `log_manifest` call
- [ ] Ensure `manifest.txt` is not polluted by multiple identical entries

***

## 📦 Archive & Packing Cleanliness

- [x] Validate `.tar.gz` tomb contents (✅ no duplicates)
- [ ] Improve log output: clarify repeated lines vs packed entries
- [ ] Add post-pack message summarizing tomb contents count

***

## 🧼 Script Cleanup & Branding

- [x] Rename `peer-consensus.sh` → `rotkeeper.sh`
- [x] Update internal strings and help output to match new identity
- [ ] Delete or archive `ritual-copy-assets.sh`
- [ ] Delete or archive legacy `render.sh`, `ASSETELLA.sh` stubs
- [ ] Migrate any logic worth keeping into `rc-*` scripts
- [ ] Annotate TODO list with hidden Sora prompt placeholders for future tone-setting.

- [ ] Add a confirm() helper in rc-utils.sh for destructive operations (e.g., rc-cleanup-bones.sh).
- [ ] Update log() helper to write to both stdout and $LOG_DIR/<script>.log.

***

## 🔍 Script Compliance Audit

- [ ] Ensure all `rc-*.sh` scripts define `main()` and use `trap` safely
- [ ] Apply `set -euo pipefail` to every script
- [ ] Move shared logic to `rc-utils.sh` and source it
- [ ] Use `check_deps` or equivalent in all scripts
- [ ] Sanity-check argument handling for `--dry-run`, `--help`, `--verbose`

***

## 🪦 Output Enhancements

- [ ] Create HTML `/index.html` showcasing rendered pages
- [ ] Inject CSS, JS, or icon assets via `rc-assets.sh`
- [ ] Add meta headers or banners to rendered output

***

- [x] Write docs for: scan, record
- [x] Link all pages into `index.md`
- [ ] Add version tags to top of all rendered `.html` files
- [ ] Ensure every file in `scripts/` and `templates/` has an `asset-meta` block

- [ ] Consolidate init-config.yaml, render-flags.yaml, and remote-sources.yaml into a single rotkeeper.yaml.
- [ ] Define and document a JSON/YAML schema for frontmatter and asset-meta blocks.
- [ ] Integrate yq + JSON Schema validation in rc-lint.sh to enforce frontmatter and asset-meta consistency.

***

## 🔁 Ritual Logging

- [ ] Improve clarity of bootstrap logs in `rotkeeper.sh`
- [ ] Add tomb version to every log bundle
- [ ] Consider emitting a ritual summary `.md` after pack

***

## 🧾 Audit Tools & Metadata Rituals

- [ ] Create `rotkeeper-audit.md` for checklist-based rotkeeper health tracking
- [ ] Patch `rc-render.sh` to validate YAML frontmatter
- [ ] Enforce `asset-meta:` in all Markdown via `rc-audit.sh`
- [ ] Add failure modes to `rc-audit.sh` for missing frontmatter

***

## 🌐 Optional

- [ ] Generate real Markdown personas for Patchy, Bricky, etc.
- [ ] Add 404.html and weird mascot lore into rendered output
- [ ] Link all tombs to tomb index page

- [ ] Refactor or formally deprecate rc-webbook.sh in favor of rc-book.sh, and document its behavior.
- [ ] Package docbook output into a .tar.gz including metadata and an index.

***


***

## 🧃 Script Stub Logic

- [ ] Only create script stubs if file does not exist or still contains `# TODO`
- [ ] Prevent overwriting functional scripts during `rotkeeper init`
- [ ] Log clearly whether a stub was created vs. a real script preserved
- [ ] Consider `.scripts-seeded` flag to skip future stub generation unless forced

## 🧼 CSS & Template Cleanup

- [x] Bootstrap removal task moved to `template-debt.md`
- [ ] Ensure templates use Hiq or pure CSS only
- [ ] Purge Bootstrap references from `render-flags.yaml` and `.html` comments

## 🧟 Shadow Revelations from Peer Review

The following entries arise from structured reviews, audits, and script dissections. These reflect gaps, fragilities, or design decisions flagged as haunted or misleading. To be addressed before or alongside `v0.2.3`.

### 🔥 Critical Gaps

- [ ] Finish or purge stub scripts (`rc-audit.sh`, `rc-unpack.sh`, `rc-webbook.sh`)
- [ ] Fix archive name collisions: use `%Y-%m-%d_%H%M%S` or `%s` in tarball names
- [ ] Validate `rotkeeper-bom.yaml`, `render-flags.yaml`, and `asset-manifest.yaml` via `yq` schema
- [ ] Enforce standard exit codes: `0` (success), `1` (warn), `2` (fail)
- [ ] Document full lifecycle: create `docs/workflow.md` describing `init → expand → render → pack → scan → reseed`

### 🧪 Testing & Validation

- [ ] Build real test suite using `bats`
- [ ] Add unit tests for `rc-utils.sh` functions
- [ ] Write integration test for full CLI flow (init → pack)
- [ ] Mock `pandoc`, `curl`, `yq` for failure case simulation

### 🧼 YAML + Dependency Fragility

- [ ] Replace manual `awk`/`grep` YAML parsing with `yq` (Mike Farah)
- [ ] Validate `yq` version compatibility in `rc-deps.sh`
- [ ] Add timeout + retry logic to `curl` in `rc-api.sh`
- [ ] Add checksum verification for remote assets

### 🧟 Audit Ritual Enhancements

- [ ] Define schema for `asset-meta` frontmatter
- [ ] Have `rc-audit.sh` fail on missing or malformed metadata
- [ ] Implement `--fix` mode in `rc-audit.sh` to inject missing `asset-meta` blocks

### 📚 Docs to Author

- [ ] `docs/schemas/rotkeeper-bom.md`
- [ ] `docs/schemas/render-flags.md`
- [ ] `docs/schemas/asset-manifest.md`
- [ ] `docs/glossary.md`
- [ ] `docs/errors.md`
- [ ] `docs/workflow.md`
- [ ] `bones/meta/rotkeeper-audit.md`

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

### 🕳️ Exit Interview Questions

The following questions emerged from structured peer reviews and onboarding prompts intended to uncover design gaps, user confusion, or brittle behavior.

- [ ] Where’s the “start here” script to run Rotkeeper rituals in sequence?
- [ ] What is the canonical directory structure and where is it documented?
- [ ] Which scripts are production-ready and which are placeholders (e.g. `rc-audit.sh`)?
- [ ] What is the expected schema for `remote-sources.yaml`?
- [ ] What is the full configuration schema for `render-flags.yaml`?
- [ ] What are the bootstrap steps for initializing a fresh Rotkeeper repo?
- [ ] Should we scaffold a default BOM if `rotkeeper-bom.yaml` is missing?
- [ ] Is there a mechanism for staging/production config separation?
- [ ] How are versions for `pandoc`, `yq`, `jq` handled and validated?
- [ ] Should all scripts unify on `rc-utils.sh` or allow local overrides?
- [ ] How should `tar`/`gzip` partial failures be handled?
- [ ] Who owns cleanup duties for `bones/logs`, `bones/archive`, etc.?
- [ ] Do we validate Markdown frontmatter or just hope it’s well-formed?
- [ ] What’s the intended use case for `rc-record.sh`?
- [ ] Are naming conventions enforced for tombs, templates, and assets?
- [ ] What is the expected output of `rc-scan.sh --json-only`?
- [ ] What’s the audit spec for `rc-audit.sh` and its timeline?
- [ ] Should `--dry-run` enforce a strict no-write policy across all scripts?
- [ ] Should `rc-pack.sh` check for existing archive name collisions?
- [ ] Is there a formal CI pipeline or is test coverage DIY?

- [ ] Add a --version flag to every rc-*.sh script that prints its version and exits.
- [ ] Update rc-record.sh (or create new helper) to emit a tomb-replay.sh inside each tomb archive for reconstruction.
- [ ] In rc-pack.sh, if tar or gzip fails, delete partial archives and provide a retry/resume mechanism.