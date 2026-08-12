# ✅ Rotkeeper Task Ledger

This ledger tracks the backlog of work for Rotkeeper, explicitly structured for async agent (Jules) handoffs and general improvements.

---

## 🧭 Post-PR177 Stabilization Roadmap
*The audit is a prioritization source, not a mandate to rewrite Rotkeeper. Finish each phase as a reviewable slice and keep the project usable after every merge.*

### Phase 0 — Rebaseline after PR177
- [ ] Record the post-PR177 baseline: clean `main`, current version, active layout, supported commands, and renderer path.
- [ ] Confirm obsolete Apex-spike files, release exclusions, and references are gone without deleting active Apex integration.
- [ ] Separate current failures from stale audit findings and document the result in the roadmap or changelog.
- [ ] Define the stabilization target for `0.5.2`: no new rituals, no new runtime, no broad architecture rewrite.

### Phase 1 — Make Apex boring to run
*Slice status (2026-08-12): all of Phase 1 is done. New in 0.5.2: `rotkeeper.sh preflight` command. `apex-contract.md` is verified against source and is authoritative.*

#### Slice 1A — Document the Apex contract
- [x] Document the supported Apex contract: executable discovery, `RK_APEX_BIN`, input format, stdout body HTML, stderr warnings, exit codes, and supported version range.
  - [x] Contract doc written (`home/content/docs/apex-contract.md` v1.1): discovery precedence, input contract, output streams, exit codes, version range 1.1.x (verified 1.1.13/1.1.15).
  - [x] Install path folded into the doc; `render`'s failure message now routes through the shared preflight instead of duplicating guidance.
- [x] Define which behavior belongs in the Apex binary versus `rc-apex-adapter.sh`; record temporary adapter responsibilities explicitly.
  - [x] Adapter boundary recorded in `apex-contract.md` §adapter boundary: yq frontmatter, sidecar precedence, template interpolation, link rewriting stay in `rc-apex-adapter.sh` until Phase 6.
- [x] Add a documented macOS and Ubuntu execution path using the real Apex binary, with the fixture fallback retained for repository tests. *(install paths in `apex-contract.md`; docs also point to `scripts/setup-jules.sh`)*

#### Slice 1B — One preflight, one message
- [x] Add a single preflight that reports whether Apex is found, executable, compatible, and actually runnable.
  - [x] `rk_apex_preflight()` added to rc-utils.sh: resolves binary (RK_APEX_BIN > PATH), executability, version probe against the 1.1.x range from the contract doc, and an empty-doc runnable smoke; one actionable setup message on failure.
  - [x] Surface decision (approved): new `rotkeeper.sh preflight` command via rc-preflight.sh.
- [x] Make `render` fail with one actionable setup message when Apex is unavailable; include the exact command or environment variable needed.
  - [x] Render's failure path (rc-render.sh apex case) routes through `rk_apex_preflight`; diagnostics can no longer drift from `preflight`.

#### Slice 1C — Fixture and hermetic smoke
- [x] Add a checked-in minimal Markdown fixture and a hermetic Apex smoke path that renders one page.
  - [x] Fixture committed at `bones/scripts/tests/fixtures/apex-smoke/smoke-fixture.md` plus `smoke-fixture-expected.html` golden (generated from the hermetic fake-binary pipeline).
  - [x] Hermetic smoke: the harness copies the fixture into each layout pass, renders through the fixture binary, and diffs the rendered `<body>` region against the golden (body is layout-independent).
  - [x] Real-Apex smoke: same harness path through the discovered binary; asserts stderr separation and exit-code propagation; skips cleanly when Apex is absent.
- [x] Test the fixture for frontmatter, sidecar precedence, HTML escaping, internal `.md` links, external links, nested output paths, and renderer stderr. *(nested-path coverage added: the same fixture renders under a content subdirectory into a mirrored nested output path and its body is diffed against the same golden on every layout pass)*

#### Slice 1D — Layout coverage
- [x] Verify Apex rendering through the dispatcher on a fresh `crypt`, `busy`, and `sterile` initialization. *(real-apex smoke + golden comparison run on every layout pass)*

#### Bonus (found working on macOS)
- [x] rc-apex-adapter.sh's local `get_canonical_path` used `realpath -m || readlink -f`, both unreliable on macOS (BSD `readlink -f` resolves existing dirs to `/private/var` but fails on not-yet-written targets, producing false boundary violations). Switched to the shared `rk_canonical_path` helper, which handles nonexistent leaves portably.

### Phase 2 — Repair the DIP/documentation workflow
- [ ] Identify why DIP became unreliable: stale generated books, oversized inventories, absolute paths, stub pages, or source/parser drift.
- [ ] Ensure DIP can run from a clean initialized fixture without depending on stale `bones/book-reports` output.
- [ ] Reduce filesystem-book scope to authoritative source files; exclude `.git`, temporary verification trees, generated output, logs, and caches.
- [ ] Remove host-specific absolute paths from published books and reports.
- [ ] Classify generated pages as authoritative reference, curated guide, or stub; do not present stubs as completed documentation.
- [ ] Rebuild the minimum useful CLI/config/content books and verify them against the source scripts and active configuration.
- [ ] Add a DIP regression check that catches stale paths, obsolete command references, and unexpected TODO stubs.

### Phase 3 — Stabilize the shell boundary
- [x] Centralize checksum selection for `sha256sum` and `shasum` and use the wrapper everywhere.
- [x] Replace the hidden `seq` dependency with a Bash-native or shared path-depth helper.
- [x] Correct GNU Awk detection so an installed `gawk` is checked directly.
- [x] Preflight `jq`, `yq`, `gawk`, `rsync`, archive tools, and the selected renderer only where each command needs them.
- [x] Add an output ownership marker and refuse stale-output deletion unless the output tree is marked generated.
- [x] Verify every destructive synchronization path honors `--dry-run` and has a boundary check.
- [x] Run `bash -n`, ShellCheck, `bash rotkeeper.sh test`, `bash rotkeeper.sh status`, and relevant dry-runs for every slice.

### Phase 4 — Normalize version and CLI contracts
- [x] Introduce one plain version source and make scripts, dispatcher output, release names, tests, and docs read it.
- [x] Replace the current bump behavior with explicit semver-style updates and a changelog entry.
- [x] Make every dispatcher command respond consistently to `--help`, `--version`, and supported `--dry-run` behavior.
- [x] Remove the advertised `--sitemap` flag or implement and test it fully.
- [x] Add a command-contract test that verifies help is non-mutating and does not start a workflow.

### Phase 5 — Make releases deterministic
- [x] Define whether a release is a framework distribution, a site-source archive, or a complete backup. *(decision: framework distribution — dispatcher, bones system, templates, configuration, project docs; documented in rc-release.sh header)*
- [x] Build framework releases from an explicit allowlist rather than repository-wide mirroring plus exclusions. *(explicit `allowed_root` entries enforced against the archive; `.github/`, `.vscode/` now excluded from staging instead of silently shipped)*
- [x] Generate and validate a release manifest; fail on unexpected root-level files and forbidden artifacts. *(`bones/config/release-manifest.txt` inside the archive with version/model/ruleset/entries; fail-fast on unexpected root entries, missing required spine (rotkeeper.sh, config, version, manifest, rc-utils.sh), and forbidden paths/artifacts incl. credentials: *.pem *.key *.p12 .env .npmrc id_rsa)*
- [ ] Verify archive contents on macOS and Ubuntu, including absence of temporary trees, caches, credentials, and compiled artifacts. *(macOS: verified via real `release 0.5.2` run + per-layout harness passes. Ubuntu: pending CI confirmation — the archive checks are rk_canonical_path-based and should behave identically)*

### Phase 6 — Rationalize the Apex boundary
- [ ] Define a stable template/input contract before moving logic out of Bash.
- [ ] Move only renderer-adjacent responsibilities into Apex incrementally: frontmatter extraction, template dialect, link rewriting, output planning, then manifest generation.
- [ ] Keep Bash responsible for dispatch, environment setup, filesystem boundaries, orchestration, and packaging.
- [ ] Treat `crypt`, `busy`, and `sterile` as initialization profiles and document the canonical runtime layout.
- [ ] Do not add a new ritual or rewrite the system until the Phase 1 contract and regression fixtures are stable.

### Phase 7 — Pure-CSS theme family
- [x] Verify every theme is zero-dependency: no JS, no CDN; convert the five Google-Fonts themes (dark, light, kawaii, overgrown, phosphor) to hand-written CSS with system font stacks.
- [x] Add a pure-CSS brutalist minimal theme (`theme-brutal`) styled for Apex markdown output: tables, code fences, blockquotes, footnotes, nested lists, and dark-mode via `prefers-color-scheme`.
- [x] Regenerate showcase gallery coverage for every template and refresh navigation glue indexes.
- [x] Validate: full harness, render, assets sync, zero external references in rendered output.
- [x] Terminal-inspired presets (macOS Terminal, Unix palettes, PowerShell-friendly) from the backlog.
- [x] Preview gallery comparing every theme side by side.

### Exit criteria for `0.5.2`
- [ ] A new user can install/find Apex, run one documented command, and render the fixture successfully.
- [ ] A missing or incompatible Apex binary produces a clear diagnosis.
- [ ] DIP runs against a clean fixture and produces bounded, path-independent reports.
- [ ] The test harness covers the real Apex path where available and remains hermetic where it is not.
- [ ] Version, help, portability, output ownership, and release checks have no known audit regressions.

---

## 🤖 Jules Action Queue
*These are bounded, tedious, reviewable tasks designed for async agent execution. Hand these to Jules one by one.*

### 1. Documentation Sync
- [x] Rewrite `README.md`: add Quickstart, "common workflows", troubleshooting matrix, architecture overview, and file tree reference. *(2026-08-12: rewritten with Quickstart, BHO + layout style table, common workflows, full command reference incl. `preflight`, troubleshooting matrix, contributor notes; stale `init --full` and `rm -rf output/*` guidance corrected)*
- [x] Create `workflow.md` detailing the full `init → reseed → render → pack → scan` cycle. *(created at `home/content/docs/workflow.md` (published as workflow.html) covering preflight → init → author → render → verify → archive → release; reseed no longer exists, so the documented cycle reflects the current dispatcher)*
- [ ] Generate script-by-script reference pages for `rc-*.sh` including flags, inputs, outputs, and "dangerous operations" warnings.
- [ ] Add schema docs for: `rotkeeper-bom.yaml`, `asset-manifest.yaml`.
- [ ] Define and document expectations for creating new `rc-*.sh` rituals.
- [ ] Ensure all index and navigation pages include backlinks to the root or documentation overview.

### 2. Commenting Pass
- [ ] Add concise docstrings to every Bash function and explain non-trivial `awk`, `sed`, `find`, and `tar` pipelines.
- [ ] Mark assumptions about env vars and CWD, and document input/output contracts.
- [ ] Note side effects like file writes, deletes, archiving, and Git operations.

### 3. Security Audit Pass
- [ ] Review manifest parsing and add preflight checks before delete (`rm -rf`) operations.
- [ ] Harden temporary directory handling (e.g., consistent `mktemp` usage).
- [ ] Ensure all destructive commands strictly honor `--dry-run`.

### 4. Shell Safety Cleanup
- [ ] Quote variables consistently and replace brittle loops/unsafe globbing.
- [ ] Normalize `set -euo pipefail` usage and tighten trap/cleanup logic across all scripts.
- [ ] Ensure all scripts fail clearly on missing dependencies (`jq`, `yq`).
- [ ] Make path handling root-relative everywhere and reduce CWD assumptions.
- [ ] Extract `safe_tar_gz()` into `rc-utils.sh` and standardize archive logic.

### 5. Smoke-Test Scaffolding
- [ ] Finalize `rc-test.sh` with `bats` support and shell-only smoke tests for core workflows (init, render, scan, pack, release).
- [ ] Create `tests/` directory for fixture content trees.
- [ ] Add golden-output comparisons for rendered HTML files and Lua filters.

### 6. Release & Checklist Improvements
- [ ] Add a release checklist and verify archive contents/excluded paths.
- [ ] Add sanity script to verify lite vs. full zip expectations.
- [ ] Standardize header/help versions, exit codes, and version strings across all scripts.
- [x] Add `--version` flag to all `rc-*.sh` scripts (one source of truth).

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
- [ ] Audit all existing HTML templates and document which are active, stale, duplicated, or drifted from reality.
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
- [ ] Add optional Mermaid diagram injection into book outputs via `rc-book.sh` or frontmatter flag.
- [ ] Create reusable Apex hooks to inject frontmatter fields into rendered documents.