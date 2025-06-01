Sure — here’s a five-paragraph summary of what this document is asking for, in normal human (but still nerd-aware) language:

---

This is a **second-round technical audit** of Rotkeeper — a Bash-based static site and document archiver built around a macabre metaphor of rituals, tombs, and rot. The tool uses modular scripts (`rc-*.sh`) to render Markdown into HTML, verify metadata, archive content, and track decay. The goal of this review is to assess how maintainable and future-proof the system really is, especially now that multiple peer reviews have been consolidated into one unified TODO tracker. You’re being asked to take ownership of this thing like it’s your undead legacy.

The first area of focus is **script consistency and hygiene**. The reviewer is asked to check whether all `rc-*.sh` scripts follow the same design patterns for flag parsing, logging, dry-run behavior, and error handling. There are calls to create shared environment setups (like a central `rc-env.sh`), unify logging styles, and refactor shared utilities (`rc-utils.sh`) into smaller components like `cli.sh`, `log.sh`, and `env.sh`. The review wants to know if this kind of cleanup should be done now, or if it's smarter to wait until there's test coverage.

Next, the audit turns to **configuration and structure**. There’s debate over whether multiple YAML files (for init, render, remote sources) should be merged into a single `rotkeeper.yaml`. There’s also a push to embed config snapshots inside the generated `.tar.gz` tombs to allow for full rehydration or replay of past builds. The team is toying with the idea of auto-generating `tomb-replay.sh` each time a render runs — a kind of black box for ritual replay.

From a documentation standpoint, the team wants to improve the readability and completeness of generated docs (`rc-docbook.md`, `rc-scriptbook.md`, etc.), consider adding Mermaid diagrams to show process flow, and even include an onboarding mode (`--tutorial`) that scaffolds a fake tomb and explains how the system works. A glossary or lexicon might also be created to help newcomers understand what things like “bless”, “ritual”, or “reseed” actually mean in this weird Bash necropolis.

Finally, the document includes a bonus section encouraging deep reflection: what parts of Rotkeeper are fragile or elegant? What should be scrapped? What helper code should be standardized for writing new rituals? And how can documentation (especially for flags and CLI usage) be made sustainable across 20+ modular scripts? All of this is aimed at not just fixing today’s issues, but ensuring the system can rot gracefully into the future — with clarity, structure, and humor intact.


```
🪦 Rotkeeper Peer Review — Consolidated Audit v0.2.3-pre

This is a focused evaluation of the Rotkeeper CLI toolchain, now with consolidated peer reviews (4o, Claude, Grok) and a unified TODO tracker. You're being summoned for **a second pass** over the full system — as if you're inheriting it for long-term stewardship.

Rotkeeper is a Bash-based static documentation embalmer. It uses modular `rc-*.sh` scripts to expand YAML tombs, render content, scan for rot, and archive results. Everything logs into `bones/`, with content and metadata tracked via frontmatter. The system is designed to be offline-first and thematically necromantic.

### Files Provided
- `rotkeeper-manual.md` — scriptbook of in-source comments
- `rotkeeper-docbook.md` — narrative and reference documentation
- `todo-review-merge.md` — current prioritized roadmap

### Instructions:
Evaluate this system for **maintainability**, **consistency**, and **long-term decay-proofing**. Address the following:

1. Are all `rc-*.sh` scripts following consistent patterns (flag parsing, logging, dry-run, `trap ERR`)?
2. Is `rc-utils.sh` becoming a monolith? Should it be split into `log.sh`, `env.sh`, `cli.sh`?
3. Should all rituals source a shared `rc-env.sh` for path sanity instead of hardcoding `bones/`, `output/`, etc.?
4. Are doc outputs (`rc-scriptbook.md`, `rc-docbook.md`, `rc-webbook.sh`) readable, complete, and clearly grouped?
5. What would *you* do to prep this system for scale (plugin support, YAML workflow runners, i18n, automated recovery, etc.)?

### Bonus:
- What’s elegant?
- What’s fragile?
- What’s worth deleting or rewriting?
- How would you onboard a new contributor?

⚠️ No need to flatter — this is a decay-first design. Be clinical.
```
# 🪦 Rotkeeper Peer Review TODOs (v0.2.3-pre)

A consolidated list of action items, questions, and eerie whispers extracted from peer review feedback. This is the roadmap for stabilizing and refining the tomb rituals.

---

## 🔧 Script & Ritual Consistency

- [ ] Standardize `parse_flags` usage across all `rc-*.sh` scripts (`rc-cleanup-bones.sh` is out of sync).
- [ ] Ensure all scripts use `init_log`, `require_bins`, and wrap actions in `run`.
- [ ] Add `--dry-run` support to `rc-book.sh` and any other missing scripts.
- [ ] Refactor `rc-bless.sh` Git logic to fail gracefully if not in a Git repo.
- [ ] Create `rc-env.sh` to centralize root path variables (e.g., `bones/`, `output/`, `home/`).

---

## 🧠 Utils & Shared Logic

- [ ] Refactor `parse_flags` to support associative arrays for mode-specific options.
- [ ] Add `confirm()` helper for destructive operations (e.g. `rc-cleanup-bones.sh`).
- [ ] Consider logging to both `stdout` and `bones/logs/` in `log()`.

---

## 📦 Config Structure

- [ ] Evaluate unification of `init-config.yaml`, `render-flags.yaml`, `remote-sources.yaml` into a single `rotkeeper.yaml`.
- [ ] Create and document a schema for frontmatter and `asset-meta` YAML blocks.
- [ ] Validate frontmatter using `yq` + optional JSON Schema checks.

---

## 📚 Docs & Output Rituals

- [ ] Improve `rc-webbook.sh` handling of rendered HTML—current mode is fragile.
- [ ] Consider emitting docbook bundles as `.tar.gz` with metadata and index.
- [ ] Add Mermaid-based pipeline diagram to Quickstart or `README.md`.

---

## 🧪 Testing & Validation

- [ ] Create `test/` directory with `bats-core` test scripts for key rituals.
- [ ] Expand `rc-test.sh` to compare outputs/logs against golden fixtures.
- [ ] Add sanity checks in `rc-bless.sh`, `rc-render.sh`, and `rc-pack.sh`.

---

## ⚰️ Future Rotproofing

- [ ] Add `--version` flag across all scripts.
- [ ] Generate `ritual.lock` or `tomb-replay.sh` on each invocation.
- [ ] Improve dependency checks (`require_bins`) consistency.
- [ ] Add fallback recovery logic for corrupted tomb archives.

---

## 📝 Meta / Philosophy

- [ ] Add `bones/roster.yaml` or contributor ledger for personas.
- [ ] Support for i18n/localization in content frontmatter or templates.
- [ ] Enhance ritual metaphors with optional CLI flourishes (ASCII glyphs, epitaph logging).

---

## 🔍 Additional Reviewer Notes

[ ] Replace all HTML regex parsing in `rc-assets.sh` with a proper parser (`pup`, `htmlq`, or even minimal HTML-aware `awk`).
[ ] Add support for `--persist` flag in `rc-book.sh` to optionally keep `.md` docbook outputs outside of ephemeral `tmp/` use.
[ ] Collapse all invocations of `check_deps` and `require_bins` into a standardized `init_env()` wrapper in `rc-utils.sh`.
[ ] Add ability to load `.ritual.yaml` workflows via `rotkeeper.sh perform <ritual>`, replacing current hardcoded dispatch model.
[ ] Formalize directory layout expectations in `README.md` or via `rc-init.sh` output.
[ ] Ensure all generated tombs embed a copy of their corresponding config (`rotkeeper.yaml`, `manifest`, etc.) for replay.
[ ] Audit every `trap` usage for proper `EXIT`, `ERR`, and `INT` consistency—some traps might not be registered in shallow subshells.
[ ] Allow templated changelog entries in `rc-bless.sh` with `rc-scribe.sh` placeholder for AI-augmented logging (future stub).

[ ] Build a glossary/index page from all known `asset-meta.title`, `slug`, and `template` fields in content.

## 📬 Reviewer Followup Questions

### 🛠️ Script & Architecture Design

1. Would you prefer `rotkeeper.sh` to act as a YAML-defined pipeline runner instead of a subcommand dispatcher?
2. How would you enforce consistent `parse_flags` usage without adding boilerplate to every script?
3. Should we aggressively break `rc-utils.sh` apart now, or wait until we have test coverage in place to refactor safely?

### 🧬 Configuration & Recovery

4. Would you support collapsing all config YAMLs into `rotkeeper.yaml` with structured keys?
5. What’s your stance on embedding config snapshots (`rotkeeper.yaml`, manifest, etc.) inside tomb `.tar.gz` files?
6. Should `rc-record.sh` write a fully executable `tomb-replay.sh` each time we render? Where should that file live?

### 📚 Documentation & Onboarding

7. Would a glossary or “tomb lexicon” be helpful for onboarding? What terms are still too vague?
8. Do you see value in embedding Mermaid.js diagrams in the documentation pipeline?
9. Should we expand `rc-init.sh` to support `--tutorial` mode, scaffolding a mock tomb with fake data and a guided README?

### 🪦 Bonus: Runes of Reflection

10. If you were writing a new ritual today (e.g., `rc-decompose.sh`), what boilerplate or helper support would you want already in place?
11. If you could remove or completely rewrite one part of the system, what would it be and why?
12. How would you document optional flags and invocation patterns if you were handling `--help` across 20+ modular scripts?

---

## 🪓 Second Pass: Clinical Maintainer Audit

### Script Consistency (Flags, Logging, Dry-Run, `trap ERR`)

- [ ] Standardize `parse_flags()` usage across all scripts — unify its implementation to handle short/long flags and associative options.
- [ ] Ensure all scripts source `rc-env.sh` and `rc-utils.sh` early and consistently call `init_env`, `init_log`, and `parse_flags`.
- [ ] Enforce `trap ERR` and `trap EXIT` in every script lifecycle for reliable failure handling.
- [ ] Normalize logging strategy — ensure all output respects dry-run and verbosity flags, and logs to both stdout and `bones/logs/`.

### `rc-utils.sh` Refactor Plan

- [ ] Split `rc-utils.sh` into smaller units: `cli.sh`, `log.sh`, `env.sh`, and optionally `deps.sh`.
- [ ] Use `rc-env.sh` as a centralized bootstrapper sourcing these utilities.

### Path Sanity and Directory Bootstrap

- [ ] Replace hardcoded paths in all scripts with dynamic vars from `rc-env.sh`.
- [ ] Introduce safe defaults in `rc-env.sh`, such as:
  ```bash
  ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/../.. && pwd)"
  OUTPUT_DIR="$ROOT_DIR/output"
  ```

### Doc Output Polish

- [ ] Add TOC/index to each book output (especially `docbook` and `scriptbook`).
- [ ] Add frontmatter flags to distinguish source/generated/rendered docs.
- [ ] Add Mermaid.js pipeline diagram to `README.md` or `quickstart-guide.md`.

### Scaling Features

- [ ] Add `.ritual.yaml` workflow support and `rotkeeper perform` runner.
- [ ] Add plugin system via `plugins.d/` sourced scripts.
- [ ] Implement optional i18n metadata (`lang`, `translation_of`) in frontmatter.
- [ ] Create recovery: `tomb-replay.sh` regeneration support from `rc-record.sh`.
- [ ] Consider `rc-translate.sh` for static content string extraction.

### Bonus Observations

- [ ] Replace HTML regex in `rc-assets.sh` with real parsers.
- [ ] Improve git-check resilience in `rc-bless.sh` (handle non-repo environments).
- [ ] Scaffold onboarding via `rotkeeper init --tutorial` with example site.
- [ ] Track contributors via `bones/roster.yaml`.

- [ ] Replace all HTML regex parsing in `rc-assets.sh` with a proper parser (`pup`, `htmlq`, or even minimal HTML-aware `awk`).
- [ ] Add support for `--persist` flag in `rc-book.sh` to optionally keep `.md` docbook outputs outside of ephemeral `tmp/` use.
- [ ] Collapse all invocations of `check_deps` and `require_bins` into a standardized `init_env()` wrapper in `rc-utils.sh`.
- [ ] Add ability to load `.ritual.yaml` workflows via `rotkeeper.sh perform <ritual>`, replacing current hardcoded dispatch model.
- [ ] Formalize directory layout expectations in `README.md` or via `rc-init.sh` output.
- [ ] Ensure all generated tombs embed a copy of their corresponding config (`rotkeeper.yaml`, `manifest`, etc.) for replay.
- [ ] Audit every `trap` usage for proper `EXIT`, `ERR`, and `INT` consistency—some traps might not be registered in shallow subshells.
- [ ] Allow templated changelog entries in `rc-bless.sh` with `rc-scribe.sh` placeholder for AI-augmented logging (future stub).
- [ ] Build a glossary/index page from all known `asset-meta.title`, `slug`, and `template` fields in content.