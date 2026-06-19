# ✅ Rotkeeper Task Ledger

This ledger tracks the backlog of work for Rotkeeper, explicitly structured for async agent (Jules) handoffs and general improvements.

---

## 🤖 Jules Action Queue
*These are bounded, tedious, reviewable tasks designed for async agent execution. Hand these to Jules one by one.*

### 1. Documentation Sync
- [ ] Rewrite `README.md`: add Quickstart, "common workflows", troubleshooting matrix, architecture overview, and file tree reference.
- [ ] Create `workflow.md` detailing the full `init → reseed → render → pack → scan` cycle.
- [ ] Generate script-by-script reference pages for `rc-*.sh` including flags, inputs, outputs, and "dangerous operations" warnings.
- [ ] Add schema docs for: `rotkeeper-bom.yaml`, `asset-manifest.yaml`.
- [ ] Define and document expectations for creating new `rc-*.sh` rituals.
- [ ] Ensure all index and navigation pages include backlinks to the root or documentation overview.

### 2. Commenting Pass
- [ ] Add concise docstrings to every Bash function and explain non-trivial `awk`, `sed`, `find`, and `tar` pipelines.
- [ ] Mark assumptions about env vars and CWD, and document input/output contracts.
- [ ] Note side effects like file writes, deletes, archiving, and Git operations.

### 3. Security Audit Pass
- [ ] Audit archive extraction; validate filenames and prevent path traversal in ingest/reseed flows.
- [ ] Review manifest parsing and add preflight checks before delete (`rm -rf`) operations.
- [ ] Harden temporary directory handling (e.g., consistent `mktemp` usage).
- [ ] Ensure all destructive commands strictly honor `--dry-run`.

### 4. Shell Safety Cleanup
- [ ] Quote variables consistently and replace brittle loops/unsafe globbing.
- [ ] Normalize `set -euo pipefail` usage and tighten trap/cleanup logic across all scripts.
- [ ] Ensure all scripts fail clearly on missing dependencies (`jq`, `pandoc`, `yq`).
- [ ] Make path handling root-relative everywhere and reduce CWD assumptions.
- [ ] Extract `safe_tar_gz()` into `rc-utils.sh` and standardize archive logic.

### 5. Smoke-Test Scaffolding
- [ ] Finalize `rc-test.sh` with `bats` support and shell-only smoke tests for core workflows (init, render, scan, pack, release, reseed).
- [ ] Create `tests/` directory for fixture content trees and archive ingest fixtures.
- [ ] Add golden-output comparisons for rendered HTML files and Lua filters.

### 6. Release & Checklist Improvements
- [ ] Add a release checklist and verify archive contents/excluded paths.
- [ ] Add sanity script to verify lite vs. full zip expectations.
- [ ] Standardize header/help versions, exit codes, and version strings across all scripts.
- [ ] Add `--version` flag to all `rc-*.sh` scripts (one source of truth).

---

## 🛠️ Feature Backlog & Improvements
*Broader architectural changes, UX polish, and experimental features.*

### UX & Logging
- [ ] Standardize `--help` output across rituals and add examples.
- [ ] Improve error messages, warnings, and add explicit success/failure summaries.
- [ ] Add `--json` for machine-readable reports where useful.
- [ ] Unify log format, add timestamps, and log tomb version in `yougood.brah` on every invocation.
- [ ] Add post-pack tomb summary to logs and generate Markdown summaries after `pack`.
- [ ] Add helper for generating `--help` from a `.help.txt` or frontmatter-driven block per script.

### Archive + Pack Hardening
- [ ] Validate `.tar.gz` contents before finalizing.
- [ ] Fix archive naming collisions and enforce unique names (`%Y-%m-%d_%H%M%S`).
- [ ] Clarify policy on tomb versioning (does it invalidate old `.tar.gz` archives?).
- [ ] Add fallback recovery logic if `tar` or `gzip` fail in `rc-pack.sh`.

### Repo Hygiene & Maintenance
- [ ] Update `AGENTS.md` to describe script layout, safety rules, naming patterns, and destructive commands.
- [ ] Add `.editorconfig`, shellcheck config, markdownlint config, PR templates, and issue templates.
- [ ] Archive `peer-reviews.md` into `bones/meta/peer-review-sarcophagus.md`.
- [ ] Clean up template footers (add credits, version stamp) and ensure `asset-meta` exists everywhere.
- [ ] Only generate stub scripts if file is empty or has `# TODO`.

### Templating, Themes & Terminal Presentation
- [ ] Audit all existing Pandoc/HTML templates and document which are active, stale, duplicated, or drifted from reality.
- [ ] Define a shared template contract for exposed frontmatter/template variables (`title`, `subtitle`, `date`, `description`, `tags`, `asset_meta`, `body`, warnings, navigation, etc.).
- [ ] Standardize base layout structure across templates while preserving room for spooky variations.
- [ ] Improve typography and reading layout for longform documentation: line length, spacing, headings, lists, tables, blockquotes, code fences, footnotes, and mobile readability.
- [ ] Improve rendering of script docs, generated books, reports, and archive pages so they feel deliberate rather than accidental.
- [ ] Prototype a DaisyUI-backed presentation layer for Rotkeeper templates (vendoring the compiled CSS locally "on-prem" to avoid CDN dependency and Node.js build tools) without turning the project into a framework app.
- [ ] Map DaisyUI components/tokens to Rotkeeper UI primitives: nav, cards, alerts, tables, metadata blocks, warnings, badges, pagination, and code panels.
- [ ] Implement a "vanilla" fallback theme sharing the exact same HTML DOM structure as the DaisyUI prototype, but styled entirely with zero-dependency, hand-written CSS to preserve the "internet thing that doesn't need the internet" philosophy.
- [ ] Preserve haunted/necrotic identity through copy, typography, dividers, iconography, lore blocks, and ornament instead of brittle custom CSS everywhere.
- [ ] Add a config-driven theme registry for supported visual modes.
- [ ] Add terminal-inspired theme presets modeled after classic macOS Terminal styles, common Unix terminal palettes, and PowerShell-friendly looks.
- [ ] Separate visual modes into "terminal-forward", "balanced", and "reading-first" families.
- [ ] Add explicit support for users who want terminal vibes without sacrificing document readability.
- [ ] Add a preview gallery page that renders the same content through every supported template/theme for side-by-side comparison.
- [ ] Add screenshot/snapshot or golden HTML regression checks for template changes.
- [ ] Explore `theme_of_the_day` as a config option before attempting full `template_of_the_day`.
- [ ] If "template of the day" is implemented, define sane fallback rules so explicit frontmatter template selection always wins.
- [ ] Add accessibility checks for contrast, focus states, table readability, and code block legibility.
- [ ] Document how to create a new template or theme without breaking the render pipeline.
- [ ] Ensure docs, docbooks, configbooks, reports, and generated indexes all render acceptably across supported themes.
- [ ] Add a sample content fixture specifically for template/theme evaluation with headings, tables, code fences, warnings, footnotes, quotes, metadata, and long paragraphs.

### Experimental / Future Options
- [ ] Replace all HTML regex parsing in `rc-assets.sh` with a proper parser (`pup`, `htmlq`, or `awk`).
- [ ] Auto-generate `docs.rotkeeper.com` from `output/`.
- [ ] Create `rc-dashboard.sh` to show rot status in a single report.
- [ ] Build `rc-pdfbook.sh` to generate PDF from merged docbook/configbook (with optional frontmatter stripping).
- [ ] Add weird mascot lore footer or 404 page entry.
- [ ] Load `.ritual.yaml` workflows via `rotkeeper.sh perform <ritual>`.
- [ ] Implement or purge stub: `rc-unpack.sh`.
- [ ] Add optional Mermaid diagram injection into book outputs via `rc-book.sh` or frontmatter flag.
- [ ] Create reusable Pandoc Lua filters to inject frontmatter fields into rendered documents.