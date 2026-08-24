# ✅ Rotkeeper Task Ledger

This ledger tracks the backlog of work for Rotkeeper, explicitly structured for async agent handoffs and general improvements.

> **Tracking moved to GitHub (2026-08-24).** Open backlog lives in
> [GitHub issues](https://github.com/drawmeanelephant/rotkeeper/issues),
> milestone [`0.8.0`](https://github.com/drawmeanelephant/rotkeeper/milestone/1).
> Lines below ticked with *(tracked in #N)* are ledger pointers, not completed
> work — the referenced issue stays authoritative until it closes. Current
> release candidate: #270.

---

## 🧭 Post-PR177 Stabilization Roadmap
*The audit is a prioritization source, not a mandate to rewrite Rotkeeper. Finish each phase as a reviewable slice and keep the project usable after every merge.*

### Phase 0 — Rebaseline after PR177
- [x] Record the post-PR177 baseline: clean `main`, current version, active layout, supported commands, and renderer path.
- [x] Confirm obsolete Apex-spike files, release exclusions, and references are gone without deleting active Apex integration.
- [x] Separate current failures from stale audit findings and document the result in the roadmap or changelog.
- [x] Define the stabilization target for `0.5.2`: no new rituals, no new runtime, no broad architecture rewrite.

*Baseline recorded 2026-08-12:* clean `main` at `cbfcef4` (24 commits past `v0.5.1`); version source `bones/config/version` = `0.5.1`, release target `0.5.2`; active layout `crypt` (default; config carries no `layout_style`); 17 dispatcher commands (`init new render preflight pack release bump test scan assets autopsy glue links showcase dip book status` plus `--help/--version`) with removed-command stubs for `cleanup ingest sync-inbox reseed`; renderer is Apex-only (Pandoc removed), discovery `RK_APEX_BIN` > PATH, supported 1.1.x per `apex-contract.md`, single preflight via `rotkeeper.sh preflight`. Full `bash rotkeeper.sh test` harness green on macOS 2026-08-12 (all three layouts, hermetic fixture + golden, real Apex 1.1.13, release packager, contract checks). No known current failures from the audit remain open — the remaining open items are all forward work (Phase 2 DIP, Phase 5 Ubuntu verification, exit-criteria documentation bundle).

### Phase 1 — Make Apex boring to run
*Slice status (2026-08-12): all of Phase 1 is done. New in 0.5.2: `rotkeeper.sh preflight` command. `apex-contract.md` is verified against source and is authoritative.*

#### Slice 1A — Document the Apex contract
- [x] Document the supported Apex contract: executable discovery, `RK_APEX_BIN`, input format, stdout body HTML, stderr warnings, exit codes, and supported version range.
  - [x] Contract doc written (`home/content/docs/apex-contract.md` v1.1): discovery precedence, input contract, output streams, exit codes, version range 1.1.x (verified 1.1.13/1.1.15).
  - [x] Install path folded into the doc; `render`'s failure message now routes through the shared preflight instead of duplicating guidance.
- [x] Define which behavior belongs in the Apex binary versus `rc-apex-adapter.sh`; record temporary adapter responsibilities explicitly.
  - [x] Adapter boundary recorded in `apex-contract.md` §adapter boundary: yq frontmatter, sidecar precedence, template interpolation, link rewriting stay in `rc-apex-adapter.sh` until Phase 6.
- [x] Add a documented macOS and Ubuntu execution path using the real Apex binary, with the fixture fallback retained for repository tests. *(install paths in `apex-contract.md`; docs also point to `scripts/setup.sh`)*

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
- [x] Identify why DIP became unreliable: stale generated books, oversized inventories, absolute paths, stub pages, or source/parser drift. *(findings 2026-08-12: no source/parser drift; the real issues were a stale checked-in dip-matrix (40 rows vs 42 from a fresh run), a missing autopsy report degrading artifact exclusion, and 14 stub mirror pages whose help-extract markers were stale; `Unowned` rows (incl. authored `workflow.md`) are by-design reporting, never moves)*
- [x] Ensure DIP can run from a clean initialized fixture without depending on stale `bones/book-reports` output. *(rc-dip.sh one-shot-generates the fsbook catalog when absent; the harness DIP regression runs from a freshly generated inventory)*
- [x] Reduce filesystem-book scope to authoritative source files; exclude `.git`, temporary verification trees, generated output, logs, and caches. *(verified in rc-book.sh runfsbook: prunes `.git`, `output`, `bones/tmp`, `bones/logs`, `bones/reports`, `bones/book-reports`, `bones/archive`, `*.log`, `.DS_Store`, `*.tmp`, `bones/manifest.txt`)*
- [x] Remove host-specific absolute paths from published books and reports. *(fsbook emits relative paths only; dip-matrix verified to contain zero host paths; harness now fails if `$ROOT_DIR` leaks into the matrix)*
- [x] Classify generated pages as authoritative reference, curated guide, or stub; do not present stubs as completed documentation. *(matrix classifies OK=26 / Stub=14 / Unowned=2; stubs refreshed with current help-extract markers after `autopsy --all`)*
- [x] Rebuild the minimum useful CLI/config/content books and verify them against the source scripts and active configuration. *(2026-08-13: reconciled. Found and fixed: fsbook catalog was leaking the git-ignored local `.freebuff/` SQLite tree and editor dirs (`.vscode`/`.idea`) into discovery — runfsbook now prunes them alongside `.git`/generated dirs; `rc-preflight.sh` was missing from the docbook because rc-autopsy's hard-coded `PERMITTED_RITUALS` whitelist predated 0.5.2 — added `rc-links`, `rc-oliver-adapter`, `rc-preflight` so all 21 scripts get help-extracted. Missing docs 4→0 (incl. `rc-preflight.md`, `theme-brutal.md`), ownership collisions 1→0, docbook now covers all 20 on-disk scripts and configbook covers rotkeeper.yaml + all 12 templates)*
- [x] Add a DIP regression check that catches stale paths, obsolete command references, and unexpected TODO stubs. *(harness block after the command contracts: fsbook regeneration, `dip --dry-run` must exit 0 and finish, matrix must be byte-identical after the dry-run, and must contain no absolute host paths)*

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
- [x] Verify archive contents on macOS and Ubuntu, including absence of temporary trees, caches, credentials, and compiled artifacts. *(macOS: verified via real `release 0.5.2` run + per-layout harness passes. Ubuntu: verified via CI — the full harness, including the real-Oliver renderer smoke and CommonMark contract corpus, passes on `ubuntu-latest`; the archive checks are `rk_canonical_path`-based and behaved identically)*

### Phase 6 — Rationalize the Oliver boundary
- [x] Define a stable template/input contract before moving logic out of Bash. *(2026-08-13: `oliver-contract.md` v1.2 now carries the stable contract — input side (frontmatter must start on line 1, six scalar fields, per-field sidecar override, template resolution) and template dialect (seven tokens, escape/raw split, `$if$`/`$endif$` gating, one-pass evaluation order, verbatim unknown tokens). Derived from `rc-oliver-adapter.sh`; script remains authoritative on disagreement)*
- [x] Move only renderer-adjacent responsibilities into Oliver incrementally: frontmatter extraction, template dialect, link rewriting, output planning, then manifest generation. *(2026-08-20: S1 `oliver meta --from <fmt> --format json` `e4cc694` `1.6-S1-draft`, S2 `oliver wrap --template <file> --meta-json <json> --assets-root <prefix> --body <file>` `1310e70` `1.7-S2-draft`, S3 `oliver render` AST link rewriting `ddd8323` `1.8-S3-draft`, S4 `oliver plan` `bab4ac5` `1.9-S4-draft`, S5 `oliver manifest --manifest <file> --add <rel>` `0a022aa` `1.10-S5-draft` — all with yq/gawk/gfind fallback on pin `6edb520c`, `crypt`/`busy`/`sterile` green, `gfind` temp files for `find`+`yq` fork safety)*
- [x] Keep Bash responsible for dispatch, environment setup, filesystem boundaries, orchestration, and packaging. *(2026-08-20: `rc-render.sh:187` `gfind` temp files, `rc-pack.sh:251` `gfind`, `rc-test.sh:1492` `gfind`, `rk_canonical_path`/`is_within_boundary`/`validate_layout_alignment`/`output_is_generated` remain Bash; Oliver receives canonical paths)*
- [x] Treat `crypt`, `busy`, and `sterile` as initialization profiles and document the canonical runtime layout. *(documented in AGENTS.md layout table + `workflow.md` §initialize, which describe profile path mappings, `paths` serialization, and relocation healing)*
- [x] When Oliver lands GFM tables ([drawmeanelephant/oliver#17](https://github.com/drawmeanelephant/oliver/issues/17)), flip the Rotkeeper boundary: update the `contract-table` assertions in `rc-test.sh`, move tables from "not supported" to "supported" in `oliver-contract.md`, re-render the 14 table-bearing content files, and confirm CI. *(2026-08-12: landed — oliver PR #19 shipped GFM pipe tables (alignment + escaped pipes); fixture, harness assertions, and `oliver-contract.md` flipped; real render + full harness verified locally; CI confirms on push)*
- [x] Do not add a new ritual or rewrite the system until the Phase 1 contract and regression fixtures are stable. *(2026-08-20: Phase 6 added no new `rc-*.sh`/dispatcher commands — `meta`/`wrap`/`plan`/`manifest` live in Oliver binary, invoked via existing `rc-oliver-adapter.sh:1`/`rc-render.sh:1`; `output/` never edited directly)*

### Phase 7 — Pure-CSS theme family
- [x] Verify every theme is zero-dependency: no JS, no CDN; convert the five Google-Fonts themes (dark, light, kawaii, overgrown, phosphor) to hand-written CSS with system font stacks.
- [x] Add a pure-CSS brutalist minimal theme (`theme-brutal`) styled for Apex markdown output: tables, code fences, blockquotes, footnotes, nested lists, and dark-mode via `prefers-color-scheme`.
- [x] Regenerate showcase gallery coverage for every template and refresh navigation glue indexes.
- [x] Validate: full harness, render, assets sync, zero external references in rendered output.
- [x] Terminal-inspired presets (macOS Terminal, Unix palettes, PowerShell-friendly) from the backlog.
- [x] Preview gallery comparing every theme side by side.

### Exit criteria for `0.5.2`
- [x] A new user can install/find Apex, run one documented command, and render the fixture successfully. *(verified 2026-08-12: extracted `rotkeeper-0.5.2.zip` to a clean dir, `preflight` → PASS, `render` → success)*
- [x] A missing or incompatible Apex binary produces a clear diagnosis. *(preflight exits 1 with one actionable message; render routes through the same check)*
- [x] DIP runs against a clean fixture and produces bounded, path-independent reports. *(fsbook regenerated on demand; matrix verified path-free; harness regression enforces non-mutation + no absolute paths)*
- [x] The test harness covers the real Apex path where available and remains hermetic where it is not. *(real 1.1.13 smoke on every layout pass; hermetic fixture + golden with zero Apex)*
- [x] Version, help, portability, output ownership, and release checks have no known audit regressions. *(full harness green incl. command contracts, DIP regression, release packager)*

---

## 🤖 Agent Action Queue
*These are bounded, tedious, reviewable tasks designed for async agent execution. Hand these to an agent one by one.*

### 1. Documentation Sync
- [x] Rewrite `README.md`: add Quickstart, "common workflows", troubleshooting matrix, architecture overview, and file tree reference. *(2026-08-12: rewritten with Quickstart, BHO + layout style table, common workflows, full command reference incl. `preflight`, troubleshooting matrix, contributor notes; stale `init --full` and `rm -rf output/*` guidance corrected)*
- [x] Create `workflow.md` detailing the full `init → reseed → render → pack → scan` cycle. *(created at `home/content/docs/workflow.md` (published as workflow.html) covering preflight → init → author → render → verify → archive → release; reseed no longer exists, so the documented cycle reflects the current dispatcher)*
- [x] Generate script-by-script reference pages for `rc-*.sh` including flags, inputs, outputs, and "dangerous operations" warnings. *(2026-08-13: scaffolding complete — all 20 rituals have DIP pages under `docs/bones/scripts/`, the autopsy whitelist now help-extracts every script including `rc-preflight`/`rc-links`/`rc-oliver-adapter`, and the flag/help pillars are stitched and current (stubs were regenerated, Missing 4→0). Overview, env, dangerous-operations prose per page still pending — natural agent work once dust settles)* *(2026-08-24: tracked in #226)*
- [x] Add schema docs for: `rotkeeper-bom.yaml`, `asset-manifest.yaml`. *(2026-08-13: `rotkeeper-schemas.md` documents `bones/asset-manifest.yaml`, `bones/config/rotkeeper.yaml`, and `release-manifest.txt` (which replaced the never-shipped `rotkeeper-bom.yaml` during Phase 5; the stale bom reference in `rotkeeper-reference.md` was corrected)*
- [x] Define and document expectations for creating new `rc-*.sh` rituals. *(2026-08-13: `new-ritual.md` — required header/bootstrap/flags, dispatcher wiring, autopsy whitelist registration, DIP discovery, boundary/destructive-op discipline, and validation list)*
- [x] Ensure all index and navigation pages include backlinks to the root or documentation overview. *(2026-08-13: backlinks added to `bones/`, `bones/scripts/`, `bones/config/`, `bones/templates/`, `scripts/` indexes plus the root index; glue refreshed; two new authored pages cross-link)*

### 2. Commenting Pass
- [x] Add concise docstrings to every Bash function and explain non-trivial `awk`, `sed`, `find`, and `tar` pipelines. *(2026-08-24: tracked in #227)*
- [x] Mark assumptions about env vars and CWD, and document input/output contracts. *(2026-08-24: tracked in #228)*
- [x] Note side effects like file writes, deletes, archiving, and Git operations. *(2026-08-24: tracked in #229)*

### 3. Security Audit Pass
- [x] Review manifest parsing and add preflight checks before delete (`rm -rf`) operations. *(2026-08-24: tracked in #230)*
- [x] Harden temporary directory handling (e.g., consistent `mktemp` usage). *(2026-08-24: done via #231 — post-`0d21146` audit found three fixed-name temp sites left (rc-bump ×2, rc-glue ×1); all converted to per-process `.tmp.$$` with failure cleanup; no fixed-name surfaces remain)*
- [x] Ensure all destructive commands strictly honor `--dry-run`. *(2026-08-13: the harness now asserts `--dry-run` non-mutation for render/pack/scan/release per layout. This caught a real bug — `rc-scan.sh` opened a second-granularity log file on every run, dry or not; the log is now opened only for real runs)*

### 4. Shell Safety Cleanup
- [x] Quote variables consistently and replace brittle loops/unsafe globbing. *(2026-08-24: tracked in #232)*
- [x] Normalize `set -euo pipefail` usage and tighten trap/cleanup logic across all scripts. *(2026-08-24: tracked in #233)*
- [x] Ensure all scripts fail clearly on missing dependencies (`jq`, `yq`). *(2026-08-24: tracked in #234)*
- [x] Make path handling root-relative everywhere and reduce CWD assumptions. *(2026-08-24: tracked in #235)*
- [x] Extract `safe_tar_gz()` into `rc-utils.sh` and standardize archive logic. *(2026-08-13: audited — no tar/gzip call sites exist outside `rc-pack.sh`; `pack_archive`/`validate_gz` (partial-archive cleanup trap + gzip integrity gate) are already the single standard and were left untouched to avoid churn. The harness now independently asserts tomb gzip integrity and root-relative entries)*

### 5. Smoke-Test Scaffolding
- [x] Finalize `rc-test.sh` with `bats` support and shell-only smoke tests for core workflows (init, render, scan, pack, release). *(2026-08-13: bats declined — it would add a dependency CI never used; the dispatcher harness remains the shell-only smoke scaffold and now covers, per layout: init, render, pack, scan, release, preflight, hermetic golden fixtures, the real-Oliver corpus under RK_STRICT, deprecated-command regressions, and — new this pass — release ZIP contents (spine/allowlist/forbidden artifacts), stale-output pruning, `--dry-run` non-mutation for render/pack/scan/release, and archive naming uniqueness)*
- [x] Create `tests/` directory for fixture content trees. *(already exists as `bones/scripts/tests/fixtures/` — oliver-smoke golden pair and oliver-contract corpus are checked in; the harness copies them into every layout pass)*
- [x] Add golden-output comparisons for rendered HTML files and Lua filters. *(golden body comparison ships in the oliver-smoke fixture; the Lua-filters reference was Pandoc-era and is now dropped — no Lua exists in the Oliver pipeline)*

### 6. Release & Checklist Improvements
- [x] Add a release checklist and verify archive contents/excluded paths. *(release ritual runs `verify_archive_contents` against `ZIP_TMP` before finalizing (required spine, root allowlist, forbidden prefixes/artifacts); the harness now re-asserts the same properties externally against the published archive)*
- [x] Add sanity script to verify lite vs. full zip expectations. *(superseded by the single-archive model: the harness asserts the canonical zip exists and no `-lite`/`-full` or `*.tar*` leftovers appear)*
- [x] Standardize header/help versions, exit codes, and version strings across all scripts. *(version and exit-code contracts already standardized; repeated in 0.5.2 — see prior note)*
- [x] Add `--version` flag to all `rc-*.sh` scripts (one source of truth). *(done previously)*

---

## 🛠️ Feature Backlog & Improvements
*Broader architectural changes, UX polish, and experimental features.*

### UX & Logging
- [x] Standardize `--help` output across rituals and add examples. *(2026-08-24: tracked in #236)*
- [x] Improve error messages, warnings, and add explicit success/failure summaries. *(2026-08-24: tracked in #237)*
- [x] Add `--json` for machine-readable reports where useful. *(2026-08-24: tracked in #238)*
- [x] Unify log format, add timestamps, and log tomb version in `yougood.brah` on every invocation. *(timestamps are standard in `log()` (rc-utils.sh); the `yougood.brah` tomb-version line was legacy lore and is dropped)*
- [x] Add post-pack tomb summary to logs and generate Markdown summaries after `pack`. *(scope: `pack` now prints a tomb summary line — archive name, sha256 prefix, file count, size; standalone Markdown summary generation is backlogged under "dashboard/report" work)*
- [x] Add helper for generating `--help` from a `.help.txt` or frontmatter-driven block per script. *(2026-08-24: tracked in #239)*

### Archive + Pack Hardening
- [x] Validate `.tar.gz` contents before finalizing. *(validate_gz gates every pack; the harness independently re-verifies tomb gzip integrity and entry prefixes)*
- [x] Fix archive naming collisions and enforce unique names (`%Y-%m-%d_%H%M%S`). *(2026-08-13: names now carry a per-process random tag — `tomb-<ts>-NNNN.tar.gz` — on both GNU and BSD date implementations; harness asserts two consecutive packs never collide)*
- [x] Clarify policy on tomb versioning (does it invalidate old `.tar.gz` archives?). *(policy: archives are append-only and immutable; names are unique per pack, old tombs are never invalidated or pruned, and `bones/manifest.txt` simply records the newest line per archive. Policy note added to `rotkeeper-schemas.md`)*
- [x] Add fallback recovery logic if `tar` or `gzip` fail in `rc-pack.sh`. *(fail-closed by design: `cleanup` trap removes any partial archive and `validate_gz` aborts on a truncated gzip; verified by the harness's gzip-integrity assertions)*

### Repo Hygiene & Maintenance
- [x] Update `AGENTS.md` to describe script layout, safety rules, naming patterns, and destructive commands. *(current AGENTS.md manual already covers the BHO model, dispatcher usage, hard rules, validation requirements, and per-directory reading list — verified 2026-08-13)*
- [x] Add `.editorconfig`, shellcheck config, markdownlint config, PR templates, and issue templates. *(2026-08-24: entry stale — reconciliation tracked in #242)*
- [x] Archive `peer-reviews.md` into `bones/meta/peer-review-sarcophagus.md`. *(2026-08-24: entry stale — reconciliation tracked in #242)*
- [x] Clean up template footers (add credits, version stamp) and ensure `asset-meta` exists everywhere. *(2026-08-24: tracked in #240)*
- [x] Only generate stub scripts if file is empty or has `# TODO`. *(2026-08-24: done via #241 — DIP now stubs missing *or empty/whitespace-only* doc pages and never overwrites non-empty files; authored content is stitch-guarded as before)*

### Templating, Themes & Terminal Presentation
- [x] Audit all existing HTML templates and document which are active, stale, duplicated, or drifted from reality. *(2026-08-24: tracked in #243)*
- [x] Define a shared template contract for exposed frontmatter/template variables (`title`, `subtitle`, `date`, `description`, `tags`, `asset_meta`, `body`, warnings, navigation, etc.). *(2026-08-24: tracked in #244)*
- [x] Standardize base layout structure across templates while preserving room for spooky variations. *(2026-08-24: tracked in #245)*
- [x] Improve typography and reading layout for longform documentation: line length, spacing, headings, lists, tables, blockquotes, code fences, footnotes, and mobile readability. *(2026-08-24: tracked in #246)*
- [x] Improve rendering of script docs, generated books, reports, and archive pages so they feel deliberate rather than accidental. *(2026-08-24: tracked in #247)*
- [x] Prototype a DaisyUI-backed presentation layer for Rotkeeper templates (vendoring the compiled CSS locally "on-prem" to avoid CDN dependency and Node.js build tools) without turning the project into a framework app. *(2026-08-24: tracked in #248)*
- [x] Map DaisyUI components/tokens to Rotkeeper UI primitives: nav, cards, alerts, tables, metadata blocks, warnings, badges, pagination, and code panels. *(2026-08-24: tracked in #249)*
- [x] Implement a "vanilla" fallback theme sharing the exact same HTML DOM structure as the DaisyUI prototype, but styled entirely with zero-dependency, hand-written CSS to preserve the "internet thing that doesn't need the internet" philosophy. *(2026-08-24: tracked in #250)*
- [x] Preserve haunted/necrotic identity through copy, typography, dividers, iconography, lore blocks, and ornament instead of brittle custom CSS everywhere. *(2026-08-24: tracked in #251)*
- [x] Add a config-driven theme registry for supported visual modes. *(2026-08-24: tracked in #252)*
- [ ] Add terminal-inspired theme presets modeled after classic macOS Terminal styles, common Unix terminal palettes, and PowerShell-friendly looks. *(2026-08-24: possibly already done — reconcile via #242)*
- [x] Separate visual modes into "terminal-forward", "balanced", and "reading-first" families. *(2026-08-24: tracked in #253)*
- [x] Add explicit support for users who want terminal vibes without sacrificing document readability. *(2026-08-24: tracked in #254)*
- [ ] Add a preview gallery page that renders the same content through every supported template/theme for side-by-side comparison. *(2026-08-24: possibly already done — reconcile via #242)*
- [x] Add screenshot/snapshot or golden HTML regression checks for template changes. *(2026-08-24: done via #255 — byte-exact golden HTML diffs in the harness, no browser dependency: deterministic probe page rendered through spooky-dark/brutal/xhtml-profile and compared against checked-in goldens on the crypt pass; regenerate intentional changes via RK_REGEN_TEMPLATE_GOLDENS=1 bash rotkeeper.sh test)*
- [x] Explore `theme_of_the_day` as a config option before attempting full `template_of_the_day`. *(2026-08-24: tracked in #256)*
- [x] If "template of the day" is implemented, define sane fallback rules so explicit frontmatter template selection always wins. *(2026-08-24: tracked in #257)*
- [x] Add accessibility checks for contrast, focus states, table readability, and code block legibility. *(2026-08-24: tracked in #258)*
- [x] Document how to create a new template or theme without breaking the render pipeline. *(2026-08-24: tracked in #259)*
- [x] Ensure docs, docbooks, configbooks, reports, and generated indexes all render acceptably across supported themes. *(2026-08-24: tracked in #260)*
- [x] Add a sample content fixture specifically for template/theme evaluation with headings, tables, code fences, warnings, footnotes, quotes, metadata, and long paragraphs. *(2026-08-24: tracked in #261)*

### Experimental / Future Options
- [x] Replace all HTML regex parsing in `rc-assets.sh` with a proper parser (`pup`, `htmlq`, or `awk`). *(2026-08-24: tracked in #262)*
- [x] Auto-generate `docs.rotkeeper.com` from `output/`. *(2026-08-24: tracked in #263)*
- [x] Create `rc-dashboard.sh` to show rot status in a single report. *(2026-08-24: tracked in #264)*
- [x] Build `rc-pdfbook.sh` to generate PDF from merged docbook/configbook (with optional frontmatter stripping). *(2026-08-24: tracked in #265)*
- [x] Add weird mascot lore footer or 404 page entry. *(2026-08-24: tracked in #266)*
- [x] Load `.ritual.yaml` workflows via `rotkeeper.sh perform <ritual>`. *(2026-08-24: tracked in #267)*
- [x] Add optional Mermaid diagram injection into book outputs via `rc-book.sh` or frontmatter flag. *(2026-08-24: tracked in #268)*
- [x] Create reusable Oliver hooks to inject frontmatter fields into rendered documents. *(2026-08-24: tracked in #269)*
