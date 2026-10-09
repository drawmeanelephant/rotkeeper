---
title: "Document Improvement Project (DIP) Matrix"
date: "2026-10-09T18:00:58Z"
template: "rotkeeper-doc.html"
---

# Document Improvement Project Matrix

This page tracks the documentation status of core project files.

OK requires populated sections and no prose placeholders, including Notes.
Fenced examples, YAML frontmatter, and HTML comments are excluded from placeholder counts.
Dates are last git commit dates, not checkout times. Staleness is unknown in shallow
repositories or without path history. Stale row totals count only known Stale statuses;
incomplete pages remain Stub even when their sources are stale.
Sidecar coverage counts targets; orphaned sidecars have no DIP, glue-directory, or render-page consumer.

| Target File | Doc Page | Last Code Edit | Last Doc Edit | Status | Placeholders | Sections | Sidecar | Staleness |
|-------------|----------|----------------|---------------|--------|--------------|----------|---------|-----------|
| `.agentignore` | [.agentignore.md](.agentignore.md) | 2026-07-01 | 2026-10-01 | Stub | 0 | overview: missing; usage: populated; reads and writes: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `.blessed` | `.blessed.md` | 2025-05-30 | Missing | Exempt | 0 | overview: exempt; usage: exempt; reads and writes: exempt; notes: exempt; history: exempt | exempt | doc: exempt; sidecar: exempt |
| `.editorconfig` | `.editorconfig.md` | 2026-08-13 | Missing | Exempt | 0 | overview: exempt; usage: exempt; reads and writes: exempt; notes: exempt; history: exempt | exempt | doc: exempt; sidecar: exempt |
| `.gitattributes` | [.gitattributes.md](.gitattributes.md) | 2026-10-09 | unknown | Stub | 1 | overview: placeholder; usage: populated; reads and writes: populated; notes: populated; history: populated | present | doc: unknown; sidecar: unknown |
| `.gitignore` | `.gitignore.md` | 2026-08-13 | Missing | Exempt | 0 | overview: exempt; usage: exempt; reads and writes: exempt; notes: exempt; history: exempt | exempt | doc: exempt; sidecar: exempt |
| `.shellcheckrc` | [.shellcheckrc.md](.shellcheckrc.md) | 2026-06-22 | 2026-10-01 | OK | 0 | overview: populated; usage: populated; reads and writes: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `.vscode/extensions.json` | `.vscode/extensions.md` | 2026-06-22 | Missing | Exempt | 0 | overview: exempt; usage: exempt; reads and writes: exempt; notes: exempt; history: exempt | exempt | doc: exempt; sidecar: exempt |
| `.vscode/settings.json` | `.vscode/settings.md` | 2025-06-05 | Missing | Exempt | 0 | overview: exempt; usage: exempt; reads and writes: exempt; notes: exempt; history: exempt | exempt | doc: exempt; sidecar: exempt |
| `bones/asset-manifest.yaml` | [bones/asset-manifest.md](bones/asset-manifest.md) | 2026-10-01 | 2026-10-01 | OK | 0 | overview: populated; usage: populated; reads and writes: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/config/dip-whitelist.txt` | [bones/config/dip-whitelist.md](bones/config/dip-whitelist.md) | 2026-10-01 | 2026-10-01 | Stale | 0 | overview: populated; usage: populated; reads and writes: populated; notes: populated; history: populated | present | doc: stale; sidecar: stale |
| `bones/config/rotkeeper.yaml` | [bones/config/rotkeeper.md](bones/config/rotkeeper.md) | 2026-09-05 | 2026-10-01 | OK | 0 | overview: populated; usage: populated; reads and writes: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/config/version` | [bones/config/version.md](bones/config/version.md) | 2026-09-24 | 2026-10-01 | Stub | 0 | overview: missing; usage: populated; reads and writes: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/scripts/rc-a11y.sh` | [bones/scripts/rc-a11y.md](bones/scripts/rc-a11y.md) | 2026-10-01 | 2026-10-01 | OK | 0 | overview: populated; usage: populated; options: populated; examples: populated; exit codes: populated; reads and writes: populated; side effects: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/scripts/rc-assets.sh` | [bones/scripts/rc-assets.md](bones/scripts/rc-assets.md) | 2026-10-01 | 2026-10-01 | OK | 0 | overview: populated; usage: populated; options: populated; examples: populated; exit codes: populated; reads and writes: populated; side effects: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/scripts/rc-autopsy.sh` | [bones/scripts/rc-autopsy.md](bones/scripts/rc-autopsy.md) | 2026-10-01 | 2026-10-01 | OK | 0 | overview: populated; usage: populated; options: populated; examples: populated; exit codes: populated; reads and writes: populated; side effects: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/scripts/rc-book.sh` | [bones/scripts/rc-book.md](bones/scripts/rc-book.md) | 2026-10-01 | 2026-10-01 | OK | 0 | overview: populated; usage: populated; options: populated; examples: populated; exit codes: populated; reads and writes: populated; side effects: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/scripts/rc-bump.sh` | [bones/scripts/rc-bump.md](bones/scripts/rc-bump.md) | 2026-10-01 | 2026-10-01 | OK | 0 | overview: populated; usage: populated; options: populated; examples: populated; exit codes: populated; reads and writes: populated; side effects: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/scripts/rc-dip.sh` | [bones/scripts/rc-dip.md](bones/scripts/rc-dip.md) | 2026-10-09 | 2026-10-02 | Stale | 0 | overview: populated; usage: populated; options: populated; examples: populated; exit codes: populated; reads and writes: populated; side effects: populated; notes: populated; history: populated | present | doc: stale; sidecar: stale |
| `bones/scripts/rc-env.sh` | [bones/scripts/rc-env.md](bones/scripts/rc-env.md) | 2026-10-02 | 2026-10-02 | Stub | 0 | overview: populated; usage: missing; options: missing; examples: missing; exit codes: missing; reads and writes: populated; side effects: missing; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/scripts/rc-glue.sh` | [bones/scripts/rc-glue.md](bones/scripts/rc-glue.md) | 2026-10-09 | 2026-10-01 | Stale | 0 | overview: populated; usage: populated; options: populated; examples: populated; exit codes: populated; reads and writes: populated; side effects: populated; notes: populated; history: populated | present | doc: stale; sidecar: stale |
| `bones/scripts/rc-init.sh` | [bones/scripts/rc-init.md](bones/scripts/rc-init.md) | 2026-10-02 | 2026-10-02 | OK | 0 | overview: populated; usage: populated; options: populated; examples: populated; exit codes: populated; reads and writes: populated; side effects: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/scripts/rc-links.sh` | [bones/scripts/rc-links.md](bones/scripts/rc-links.md) | 2026-10-09 | 2026-10-01 | Stale | 0 | overview: populated; usage: populated; options: populated; examples: populated; exit codes: populated; reads and writes: populated; side effects: populated; notes: populated; history: populated | present | doc: stale; sidecar: stale |
| `bones/scripts/rc-new.sh` | [bones/scripts/rc-new.md](bones/scripts/rc-new.md) | 2026-10-01 | 2026-10-01 | OK | 0 | overview: populated; usage: populated; options: populated; examples: populated; exit codes: populated; reads and writes: populated; side effects: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/scripts/rc-oliver-adapter.sh` | [bones/scripts/rc-oliver-adapter.md](bones/scripts/rc-oliver-adapter.md) | 2026-10-01 | 2026-10-01 | Stub | 0 | overview: populated; usage: missing; options: missing; examples: missing; exit codes: missing; reads and writes: populated; side effects: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/scripts/rc-pack.sh` | [bones/scripts/rc-pack.md](bones/scripts/rc-pack.md) | 2026-10-01 | 2026-10-01 | OK | 0 | overview: populated; usage: populated; options: populated; examples: populated; exit codes: populated; reads and writes: populated; side effects: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/scripts/rc-preflight.sh` | [bones/scripts/rc-preflight.md](bones/scripts/rc-preflight.md) | 2026-10-01 | 2026-10-01 | Stub | 0 | overview: populated; usage: populated; options: populated; examples: populated; exit codes: populated; reads and writes: populated; side effects: missing; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/scripts/rc-release.sh` | [bones/scripts/rc-release.md](bones/scripts/rc-release.md) | 2026-10-01 | 2026-10-01 | OK | 0 | overview: populated; usage: populated; options: populated; examples: populated; exit codes: populated; reads and writes: populated; side effects: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/scripts/rc-render.sh` | [bones/scripts/rc-render.md](bones/scripts/rc-render.md) | 2026-10-02 | 2026-10-02 | OK | 0 | overview: populated; usage: populated; options: populated; examples: populated; exit codes: populated; reads and writes: populated; side effects: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/scripts/rc-scan.sh` | [bones/scripts/rc-scan.md](bones/scripts/rc-scan.md) | 2026-10-01 | 2026-10-01 | OK | 0 | overview: populated; usage: populated; options: populated; examples: populated; exit codes: populated; reads and writes: populated; side effects: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/scripts/rc-showcase.sh` | [bones/scripts/rc-showcase.md](bones/scripts/rc-showcase.md) | 2026-10-01 | 2026-10-01 | OK | 0 | overview: populated; usage: populated; options: populated; examples: populated; exit codes: populated; reads and writes: populated; side effects: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/scripts/rc-status.sh` | [bones/scripts/rc-status.md](bones/scripts/rc-status.md) | 2026-10-01 | 2026-10-01 | OK | 0 | overview: populated; usage: populated; options: populated; examples: populated; exit codes: populated; reads and writes: populated; side effects: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/scripts/rc-test.sh` | [bones/scripts/rc-test.md](bones/scripts/rc-test.md) | 2026-10-09 | 2026-10-02 | Stale | 0 | overview: populated; usage: populated; options: populated; examples: populated; exit codes: populated; reads and writes: populated; side effects: populated; notes: populated; history: populated | present | doc: stale; sidecar: stale |
| `bones/scripts/rc-utils.sh` | [bones/scripts/rc-utils.md](bones/scripts/rc-utils.md) | 2026-10-02 | 2026-10-02 | Stub | 0 | overview: populated; usage: missing; options: missing; examples: missing; exit codes: missing; reads and writes: populated; side effects: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/scripts/tests/fixtures/oliver-smoke/smoke-fixture-expected.html` | `bones/scripts/tests/fixtures/oliver-smoke/smoke-fixture-expected.md` | 2026-09-24 | Missing | Exempt | 0 | overview: exempt; usage: exempt; reads and writes: exempt; notes: exempt; history: exempt | exempt | doc: exempt; sidecar: exempt |
| `bones/scripts/tests/fixtures/template-golden/theme-brutal.golden.html` | `bones/scripts/tests/fixtures/template-golden/theme-brutal.golden.md` | 2026-10-01 | Missing | Exempt | 0 | overview: exempt; usage: exempt; reads and writes: exempt; notes: exempt; history: exempt | exempt | doc: exempt; sidecar: exempt |
| `bones/scripts/tests/fixtures/template-golden/theme-spooky-dark-xhtml.golden.html` | `bones/scripts/tests/fixtures/template-golden/theme-spooky-dark-xhtml.golden.md` | 2026-10-01 | Missing | Exempt | 0 | overview: exempt; usage: exempt; reads and writes: exempt; notes: exempt; history: exempt | exempt | doc: exempt; sidecar: exempt |
| `bones/scripts/tests/fixtures/template-golden/theme-spooky-dark.golden.html` | `bones/scripts/tests/fixtures/template-golden/theme-spooky-dark.golden.md` | 2026-10-01 | Missing | Exempt | 0 | overview: exempt; usage: exempt; reads and writes: exempt; notes: exempt; history: exempt | exempt | doc: exempt; sidecar: exempt |
| `bones/scripts/tests/rc-glue.bats` | `bones/scripts/tests/rc-glue.md` | 2026-07-12 | Missing | Exempt | 0 | overview: exempt; usage: exempt; reads and writes: exempt; notes: exempt; history: exempt | exempt | doc: exempt; sidecar: exempt |
| `bones/templates/rotkeeper-blog.html` | [bones/templates/rotkeeper-blog.md](bones/templates/rotkeeper-blog.md) | 2026-08-27 | 2026-10-01 | OK | 0 | overview: populated; usage: populated; reads and writes: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/templates/rotkeeper-doc.html` | [bones/templates/rotkeeper-doc.md](bones/templates/rotkeeper-doc.md) | 2026-10-01 | 2026-10-01 | OK | 0 | overview: populated; usage: populated; reads and writes: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/templates/theme-brutal.html` | [bones/templates/theme-brutal.md](bones/templates/theme-brutal.md) | 2026-08-27 | 2026-10-01 | Stub | 0 | overview: populated; usage: populated; reads and writes: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/templates/theme-daisy-vanilla.html` | [bones/templates/theme-daisy-vanilla.md](bones/templates/theme-daisy-vanilla.md) | 2026-08-28 | 2026-10-01 | Stub | 0 | overview: populated; usage: populated; reads and writes: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/templates/theme-daisy.html` | [bones/templates/theme-daisy.md](bones/templates/theme-daisy.md) | 2026-08-28 | 2026-10-01 | Stub | 0 | overview: populated; usage: populated; reads and writes: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/templates/theme-dark.html` | [bones/templates/theme-dark.md](bones/templates/theme-dark.md) | 2026-08-27 | 2026-10-01 | OK | 0 | overview: populated; usage: populated; reads and writes: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/templates/theme-flash.html` | [bones/templates/theme-flash.md](bones/templates/theme-flash.md) | 2026-09-05 | 2026-10-01 | Stub | 0 | overview: populated; usage: populated; reads and writes: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/templates/theme-kawaii.html` | [bones/templates/theme-kawaii.md](bones/templates/theme-kawaii.md) | 2026-08-27 | 2026-10-01 | OK | 0 | overview: populated; usage: populated; reads and writes: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/templates/theme-light.html` | [bones/templates/theme-light.md](bones/templates/theme-light.md) | 2026-08-27 | 2026-10-01 | OK | 0 | overview: populated; usage: populated; reads and writes: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/templates/theme-necropolis.html` | [bones/templates/theme-necropolis.md](bones/templates/theme-necropolis.md) | 2026-08-28 | 2026-10-01 | Stub | 0 | overview: populated; usage: populated; reads and writes: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/templates/theme-overgrown.html` | [bones/templates/theme-overgrown.md](bones/templates/theme-overgrown.md) | 2026-08-27 | 2026-10-01 | OK | 0 | overview: populated; usage: populated; reads and writes: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/templates/theme-phosphor.html` | [bones/templates/theme-phosphor.md](bones/templates/theme-phosphor.md) | 2026-08-27 | 2026-10-01 | OK | 0 | overview: populated; usage: populated; reads and writes: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/templates/theme-pride.html` | [bones/templates/theme-pride.md](bones/templates/theme-pride.md) | 2026-09-05 | 2026-10-01 | Stub | 0 | overview: populated; usage: populated; reads and writes: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/templates/theme-spooky-dark-xhtml.html` | [bones/templates/theme-spooky-dark-xhtml.md](bones/templates/theme-spooky-dark-xhtml.md) | 2026-08-28 | 2026-10-01 | Stub | 0 | overview: populated; usage: populated; reads and writes: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/templates/theme-spooky-dark.html` | [bones/templates/theme-spooky-dark.md](bones/templates/theme-spooky-dark.md) | 2026-08-28 | 2026-10-01 | Stub | 0 | overview: populated; usage: populated; reads and writes: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/templates/theme-spooky-light.html` | [bones/templates/theme-spooky-light.md](bones/templates/theme-spooky-light.md) | 2026-08-27 | 2026-10-01 | Stub | 0 | overview: populated; usage: populated; reads and writes: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `bones/templates/theme-textpattern.html` | [bones/templates/theme-textpattern.md](bones/templates/theme-textpattern.md) | 2026-10-01 | 2026-10-01 | Stub | 0 | overview: populated; usage: populated; reads and writes: populated; notes: populated; history: populated | present | doc: current; sidecar: current |
| `rotatui.sh` | [rotatui.md](rotatui.md) | 2026-10-01 | 2026-10-01 | Stub | 0 | overview: populated; usage: missing; options: missing; examples: missing; exit codes: missing; reads and writes: populated; side effects: missing; notes: populated; history: populated | present | doc: current; sidecar: current |
| `rotkeeper.sh` | [rotkeeper.md](rotkeeper.md) | 2026-10-02 | 2026-10-02 | Stub | 0 | overview: populated; usage: populated; options: populated; examples: populated; exit codes: populated; reads and writes: populated; side effects: missing; notes: populated; history: populated | present | doc: current; sidecar: stale |
| `scripts/setup.sh` | [scripts/setup.md](scripts/setup.md) | 2026-10-09 | 2026-10-01 | Stub | 0 | overview: populated; usage: missing; options: missing; examples: missing; exit codes: missing; reads and writes: populated; side effects: missing; notes: populated; history: populated | present | doc: stale; sidecar: stale |
| `Unknown` | [bones/scripts/tests/fixtures/index.md](bones/scripts/tests/fixtures/index.md) | Missing | 2026-08-13 | Unowned | 0 | Not a core reference | Not applicable | unknown |
| `Unknown` | [bones/scripts/tests/fixtures/oliver-smoke/index.md](bones/scripts/tests/fixtures/oliver-smoke/index.md) | Missing | 2026-10-01 | Unowned | 0 | Not a core reference | Not applicable | unknown |
| `Unknown` | [bones/scripts/tests/fixtures/template-golden/index.md](bones/scripts/tests/fixtures/template-golden/index.md) | Missing | 2026-10-01 | Unowned | 0 | Not a core reference | Not applicable | unknown |
| `Unknown` | [bones/scripts/tests/index.md](bones/scripts/tests/index.md) | Missing | 2026-10-01 | Unowned | 0 | Not a core reference | Not applicable | unknown |
| `Unknown` | [daisyui-map.md](daisyui-map.md) | Missing | 2026-09-04 | Unowned | 0 | Not a core reference | Not applicable | unknown |
| `Unknown` | [textile-showcase.textile](textile-showcase.textile) | Missing | 2026-08-13 | Unowned | 0 | Not a core reference | Not applicable | unknown |

**Totals:** OK: 23 | Stub: 20 | Missing: 0 | Stale rows: 5 | Unowned: 6 | Exempt: 10 | Rows: 64

**Placeholders:** 1 lines in 1 pages.

**Sidecar coverage (targets):** present: 48 | missing: 0 | exempt: 10 | orphaned sidecars: 0

**Staleness:** unknown | known stale targets: 7 | unknown targets: 1 | stale docs: 6 | stale sidecars: 7

## Authored task guides

These pages declare `doc_type: guide`, have no core `target_file`, and are maintained by authors, not stitched as command references. Review dates and prose placeholders remain visible; declaration alone does not mean completion.

| Guide | Reviewed | Status | Placeholders |
| --- | --- | --- | --- |
| [docs/creating-themes.md](../docs/creating-themes.md) | 2026-10-02 | Reviewed | 0 |
| [docs/index.md](../docs/index.md) | 2026-10-02 | Reviewed | 0 |
| [docs/new-ritual.md](../docs/new-ritual.md) | 2026-10-02 | Reviewed | 0 |
| [docs/onboarding.md](../docs/onboarding.md) | 2026-10-03 | Reviewed | 0 |
| [docs/publishing.md](../docs/publishing.md) | 2026-10-03 | Reviewed | 0 |
| [docs/rotkeeper-reference.md](../docs/rotkeeper-reference.md) | 2026-10-02 | Reviewed | 0 |
| [docs/rotkeeper-schemas.md](../docs/rotkeeper-schemas.md) | 2026-10-02 | Reviewed | 0 |
| [docs/textile-guide.textile](../docs/textile-guide.textile) | 2026-10-02 | Reviewed | 0 |
| [docs/themes.md](../docs/themes.md) | 2026-10-02 | Reviewed | 0 |
| [docs/workflow.md](../docs/workflow.md) | 2026-10-03 | Reviewed | 0 |
| [docs/xhtml-profile.md](../docs/xhtml-profile.md) | 2026-10-02 | Reviewed | 0 |
| [help/index.md](../help/index.md) | 2026-10-02 | Reviewed | 0 |

## Target exemptions

- `.blessed`: Currently contains only a version tag; a separate reference page is unnecessary.
- `.editorconfig`: Conventional editor formatting settings, not a runtime component.
- `.gitignore`: Standard Git ignore rules are self-documenting by their paths.
- `.vscode/extensions.json`: Optional VS Code extension recommendations, not runtime dependencies.
- `.vscode/settings.json`: Optional, local VS Code settings; Rotkeeper does not require this editor.
- `bones/scripts/tests/fixtures/oliver-smoke/smoke-fixture-expected.html`: Expected renderer output used by the smoke regression, not an authored template.
- `bones/scripts/tests/fixtures/template-golden/theme-brutal.golden.html`: Expected template output used by golden regressions, not an authored template.
- `bones/scripts/tests/fixtures/template-golden/theme-spooky-dark-xhtml.golden.html`: Expected XHTML template output used by golden regressions, not an authored template.
- `bones/scripts/tests/fixtures/template-golden/theme-spooky-dark.golden.html`: Expected template output used by golden regressions, not an authored template.
- `bones/scripts/tests/rc-glue.bats`: Test assertions for glue behavior, not a dispatcher command or user-facing reference target.

## Degraded inputs

- Autopsy report missing — artifact excludes incomplete.
- Help input missing (bones/reports/autopsy-help.md); command references read static help directly from scripts.
