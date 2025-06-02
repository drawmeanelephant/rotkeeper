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

- [ ] Write `workflow.md` explaining full init → bless cycle
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