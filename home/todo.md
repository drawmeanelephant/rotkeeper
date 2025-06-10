# ✅ Rotkeeper Task Ledger

This ledger reflects all tasks known, forgotten, or ghostwritten as of `v0.2.6-dev`.

---

## 🧠 Core Ritual Hardening

# - [ ] Complete `rc-lint.sh` (currently stub)
- [ ] Add `--version` flag to all `rc-*.sh` scripts
- [ ] Replace all HTML regex parsing in `rc-assets.sh` with a proper parser (`pup`, `htmlq`, or awk)
- [ ] Write rc-audit.sh based on rc-frontmatter-audit.sh core logic

---

## 📦 Archive + Pack Behavior

- [ ] Validate `.tar.gz` contents before finalizing
- [ ] Add post-pack tomb summary to logs
- [ ] Enforce unique archive names (`%Y-%m-%d_%H%M%S`)
- [ ] Clarify policy on tomb versioning: does it invalidate old `.tar.gz` archives?
- [ ] Fix archive naming collisions — consider fallback to Unix epoch
- [ ] Add fallback recovery logic if `tar` or `gzip` fail in `rc-pack.sh`

---

- [ ] Write `workflow.md` explaining full init → pack cycle
- [ ] Define and document the full ritual chain in `workflow.md` (`init → reseed → render → pack → scan`)
- [ ] Add schema docs for: `rotkeeper-bom.yaml`, `render-flags.yaml`, `asset-manifest.yaml`
- [ ] Ensure all index and navigation pages include backlinks to the root or documentation overview
- [ ] Build rc-pdfbook.sh to generate PDF from merged docbook/webbook
- [ ] Optionally strip internal frontmatter blocks for clean PDF output
- [ ] Add config-driven style selector for future PDF themes
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
# - [ ] Add GitHub Action to run `rc-lint.sh` + `rc-test.sh` on push
# - [ ] Validate CI output includes test summary + lint warnings

---

## 🧪 Testing & Validation

- [ ] Finalize `rc-test.sh` with bats support and smoke tests
- [ ] Add integration + failure-mode test for init → render → pack flow
- [ ] Create `tests/` directory for fixtures and mock rituals
- [ ] Validate Lua filters via snapshot tests or golden fixtures
# - [ ] Add linting logic and CLI entrypoint for `rc-lint.sh`
# - [ ] Hook lint into CI: fail builds if frontmatter/schema invalid

---

## 🧼 Script Cleanup & Debt Burial

- [ ] Archive `peer-reviews.md` into `bones/meta/peer-review-sarcophagus.md`
- [ ] Only generate stub scripts if file is empty or has `# TODO`
- [ ] Enhance ritual metaphors with optional CLI glyphs and epitaphs
- [ ] Add helper for generating `--help` from a `.help.txt` or frontmatter-driven block per script

---

## 📎 Template & Asset Work

- [ ] Clean up template footers (add credits, version stamp)
- [ ] Ensure `asset-meta` block exists in every HTML/CSS/JS file
- [ ] Add option to inject `asset-meta` JSON into rendered HTML via Pandoc filter
- [ ] Add optional Mermaid diagram injection into book outputs via `rc-book.sh` or frontmatter flag
- [ ] Create reusable Pandoc Lua filters to inject frontmatter fields (e.g. author, template, slug) into rendered documents
- [ ] Extract safe_tar_gz() into rc-utils.sh and standardize archive logic

- [ ] Build `rc-inbox.sh` to process and route loose `.md` files based on frontmatter
- [ ] Allow optional `--lint`, `--report`, and `--dry-run` modes for inbox processing
- [ ] Support routing rules via YAML: template/status determine destination
# - [ ] Future: allow inbox to split long files into renderable multi-page tombs
- [ ] Add `rc-convert-*.sh` helpers (e.g. HTML, CSV, DOCX → Markdown) that feed into inbox

---

## 🗺️ Future Options

- [ ] Auto-generate `docs.rotkeeper.com` from output/
- [ ] Create `rc-dashboard.sh` to show rot status in a single report
- [ ] Add weird mascot lore footer or 404 page entry
- [ ] Load `.ritual.yaml` workflows via `rotkeeper.sh perform <ritual>`
- [ ] Formalize directory layout in `README.md` or echo from `rc-init.sh`
- [ ] Define CLI documentation standard for optional flags and `--help` output across rituals
- [ ] Document expectations for creating new `rc-*.sh` rituals

---

🪦 Archived: v0.2.0 checklist and helper extraction notes relocated to `docs/legacy/hardening-v0.2.0.md`.

---

_Last updated by tombkeeper: 2025-06-06 — current branch: dev-v0.2.7_