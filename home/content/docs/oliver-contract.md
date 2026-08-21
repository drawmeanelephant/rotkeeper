---
title: "Oliver Renderer Contract"
slug: oliver-contract
template: rotkeeper-doc.html
version: "1.8-S3-draft"
updated: "2026-08-20"
description: "The supported contract between Rotkeeper and the native Oliver HTML renderer: executable discovery, input format and output profile, output streams, exit codes, the adapter boundary, and the stable template/input contract."
tags:
  - rotkeeper
  - oliver
  - rendering
  - reference
---

# Oliver Renderer Contract

This page is the authoritative reference for how Rotkeeper drives the native [Oliver](https://github.com/drawmeanelephant/oliver) renderer — a small, freestanding CommonMark/Textile/Cooklang parsing and rendering library in Zig, and the successor to the Apex renderer. It records the stable contract between the Oliver binary and `rc-oliver-adapter.sh`.

## Executable discovery

`rc-render.sh` locates Oliver in this order:

1. `RK_OLIVER_BIN` environment variable (explicit override).
2. `oliver` resolved via `PATH`.

If neither yields an executable file, `render` fails with exit 1 and prints a setup message covering installation and the environment variable.

## The binary contract

Oliver is invoked once per source file, reading the file on stdin. The input language comes from `input_format` in `bones/config/rotkeeper.yaml` (`markdown` default, `textile` and `cooklang` alternatives), overridden to `textile` for any source whose extension is `.textile` and to `cooklang` for any source whose extension is `.cook`; the adapter and `preflight` pass the resulting format through on every invocation. The output profile comes from `render_profile` in `bones/config/rotkeeper.yaml` (`html` default, `xhtml` opt-in), overridden per page by a `render_profile` frontmatter key; only an `xhtml` profile appends `--to xhtml`, so the default invocation is byte-identical to the html-only contract:

```bash
oliver render --from markdown < file.md > body.html 2> warnings.log
oliver render --from textile < file.md > body.html 2> warnings.log
oliver render --from textile < file.textile > body.html 2> warnings.log
oliver render --from cooklang < file.md > body.html 2> warnings.log
oliver render --from cooklang < file.cook > body.html 2> warnings.log
oliver render --from markdown --to xhtml < file.md > body.xhtml 2> warnings.log
```

| Aspect | Contract |
| --- | --- |
| Invocation | `oliver render --from <markdown\|textile\|cooklang> [--to <html\|xhtml>]` — one file per invocation, stdin → stdout; format comes from `input_format` in `bones/config/rotkeeper.yaml` (default `markdown`, validated to `markdown`/`textile`/`cooklang` at environment load; anything else warns and falls back to `markdown`). A source with a `.textile` extension always invokes `--from textile` and one with a `.cook` extension always invokes `--from cooklang`, overriding the config default for that file. The output profile comes from `render_profile` in `bones/config/rotkeeper.yaml` (default `html`, validated to `html`/`xhtml` at environment load; anything else warns and falls back to `html`), overridden per page by a `render_profile` frontmatter key; `--to xhtml` is appended only when the effective profile is `xhtml`, so the default invocation carries no `--to` flag and is byte-identical to the pre-XHTML contract. `--to` is rejected by Oliver on `serialize`/`scale`/`menu` |
| Input | Markdown, **Textile, or Cooklang** on **stdin** — a leading YAML frontmatter block is stripped by **Oliver** (`oliver meta --from <fmt> --format json` extracts it; `oliver render` auto-strips when meta-capable, adapter `awk` remains as fallback until pin bump) |
| stdout | Rendered **body HTML fragment** (no full page wrapping) — an **XHTML fragment** under `--to xhtml` (no DOCTYPE, no document wrappers; see [XHTML output profile](#xhtml-output-profile-opt-in)) |
| stderr | Non-fatal renderer warnings; forwarded through the adapter as warnings, never into the page body. Under `--to xhtml`, raw HTML fails closed on stderr with `error.RawHtmlNotXmlWellFormed` and an actionable hint, and the page aborts with exit 1 |
| Exit 0 | Success |
| Exit 1 | Render failure (e.g. missing input, or raw HTML under `--to xhtml`); page is aborted |
| Version | Oliver's CLI is provisional and has no stable release yet, so Rotkeeper pins an exact source revision: CI and `scripts/setup.sh` install the binary published by the upstream rolling `builds` release and verify it reports exactly `commit <OLIVER_PIN>`; the Zig source build remains the fallback (the `OLIVER_PIN` variable in `setup.sh`). Moving the pin is a deliberate act — upgrade it, re-run the harness, and update this table. The pin moved 2026-08-15 from `c8a8e06` to `6edb520c` to adopt the upstream `builds` release (prebuilt binaries + published `sha256sums.txt`, download-first with checksum and `--version` commit verification), plus the `--version` stdout fix, GFM footnote reference/backref fixes, and the XHTML footnote-attribute serialization fix — Markdown/Textile/Cooklang parsing untouched, footnote/task-list literals remain out of scope. The prior move (2026-08-14) from `e314dbbe` to `c8a8e06` had picked up the XHTML output profile (`--to html\|xhtml`, oliver PR #54, `docs/XHTML.md`) — same semantics, different serialization bytes; Markdown/Textile/Cooklang parsing untouched, CommonMark 652/652 and Cooklang 60/60 gates unchanged — plus the audit fixes #55–#58 (NUL → U+FFFD under the XHTML profile, CLI subcommand grammar with `--to` render-only). The move before that (2026-08-13) from `22b3c779` to `e314dbbe` had added the Cooklang frontend (CK1) plus CK2–CK5. `preflight`'s live smoke render (in the configured format and profile) remains the behavioral safety net on top of the pin |

The binary is deliberately narrow: it converts Markdown, Textile, or Cooklang to a body fragment. **Phase 6 S1 (draft):** frontmatter extraction moves to Oliver (`oliver meta`); sidecars, templates, link rewriting, output planning remain in Bash until later slices.

## Rendered Markdown surface

Oliver implements the CommonMark 0.31.2 specification; its own conformance harness scores 652/652 on the normative corpus (see the Oliver docs). That is the contract for what `render` produces:

- **Supported:** ATX and Setext headings, thematic breaks, fenced and indented code blocks (info strings become `language-*` classes), block quotes, tight and loose lists (ordered/unordered, nesting), code spans, emphasis and strong emphasis, inline links and autolinks (URI and email `mailto:`), images, raw HTML (block and inline, passed through verbatim), entity and numeric character references, reference-style links, and GFM pipe tables (header row with required delimiter row, alignment colons `:---` `:---:` `---:`, escaped `\|` pipes, and inline-parsed cells producing `<table><thead>…<tbody>…`).
- **Not supported (not part of CommonMark):** task lists and footnotes render as literal text. Content that needs them should stay CommonMark-safe; raw HTML is passed through verbatim as an escape hatch. The test harness asserts this boundary stays literal in `contract-table.html`.
- **Fidelity verification:** the hermetic golden (`smoke-fixture-expected.html`) is produced by the fixture (fake) binary and verifies the adapter pipeline — frontmatter stripping, link rewriting, escaping — not CommonMark fidelity. Renderer fidelity is asserted by the real-Oliver contract-corpus pass in the test harness (`bones/scripts/tests/fixtures/oliver-contract/`), which runs whenever an `oliver` binary is present.

## Rendered Cooklang surface

Oliver implements Cooklang per the official spec and canonical corpus (60/60 on its conformance wall). That is the contract for what `render` produces for `.cook` sources and `input_format: cooklang`:

- **Supported:** `@ingredient` (with `{braced multiword names}`, quantities/units preserved as source text), `#cookware`, `~timers` (single-word and braced; named timers render the name, unnamed the quantity/units), `(preparations)` shorthand, `--` and `[- -]` comments (removed from the tree), `> notes`, `=` sections, and `@./path` recipe references (parsed, never resolved). Output follows Oliver's own deterministic HTML policy: `<article class="recipe">`, sections with `<h2>`, `<ol class="steps">` with `<li>` and `<br>` breaks, `<aside class="note">`, `<span class="ingredient" data-quantity data-units>`, `<span class="cookware">`, `<span class="timer">`, `<span class="preparation">`, `<span class="recipe-ref" data-ref="...">`. Frontmatter is data, not content: it is never rendered.
- **Not supported (degrades to literal text, per the corpus):** invalid tokens; unclosed `{`, `(`, `[-`, or fenced blocks additionally emit a structured warning diagnostic. Recipe-reference resolution, metadata authority, and scaling are consumer territory (the `.menu` view and `scaleRecipe` live in the Oliver library, not Rotkeeper).
- **Recipe metadata** (title, author, servings, etc.) belongs in the leading YAML frontmatter, which Rotkeeper's adapter strips before Oliver sees it — exactly as for Markdown and Textile sources.

## XHTML output profile (opt-in)

Oliver ships an explicit, deterministic, XML-compatible XHTML serialization of the same rendered document — same normalized IR, same semantics, different bytes (oliver PR #54, `docs/XHTML.md` upstream). Rotkeeper exposes it as an opt-in page render mode; the default (`html`) path is byte-identical to the pre-XHTML contract.

- **Selection:** `render_profile` in `bones/config/rotkeeper.yaml` (`html` default, `xhtml` opt-in; validated at environment load, anything else warns and falls back to `html`) arrives at the adapter as `RENDER_PROFILE`. A per-page `render_profile` key in the source frontmatter overrides the config value for that file — the per-page knob exists because raw-HTML content makes XHTML a per-page decision, not a global one.
- **Flag:** the adapter appends `--to xhtml` only when the effective profile is `xhtml`; an `html` profile appends nothing, keeping the default invocation byte-identical. `preflight`'s smoke render passes `--to xhtml` too when the config selects it, so the compatibility gate covers the configured profile.
- **Fragments only:** the XHTML profile serializes a body fragment — no DOCTYPE, no `<html>`/`<head>`/`<body>` wrappers. Rotkeeper's themes own the document wrapper, so an XHTML *document* is a theme variant (XML declaration + `<html xmlns="http://www.w3.org/1999/xhtml">`), not an adapter concern. `bones/templates/theme-spooky-dark-xhtml.html` is the reference variant; a page opts in with `template: theme-spooky-dark-xhtml.html` plus `render_profile: xhtml` (see [XHTML Output Profile](xhtml-profile.md), itself an XHTML page). Void elements always serialize XML-form under `--to xhtml` (`<hr />`, `<br />`, `<img ... />`); attributes stay double-quoted in the existing fixed order; escaping is the existing policy (XML predefined escapes, NUL → U+FFFD, raw Unicode preserved).
- **Fail-closed on raw HTML:** Markdown raw HTML (`.raw_html` and `.html_block` leaves, and Textile `pre.`) passes through verbatim under `html` but fails under `xhtml` with Oliver's typed `error.RawHtmlNotXmlWellFormed` and an actionable hint on stderr. Oliver never repairs, rewrites, or escapes raw HTML into fake XHTML, and the adapter surfaces the failure as ERROR + exit 1 for that page. A site flipping pages to XHTML must sweep its raw HTML first (the site's own docs historically contain raw HTML). The harness asserts both the fail-closed error path and XHTML well-formedness through an independent XML parser (`xmllint`) when a real Oliver binary is present.
- **Cooklang:** the forced line break is the one byte delta (`<br>` → `<br />`); recipes render through the same profile mechanism.

## Frontmatter — Phase 6 S1 (Oliver-owned with Bash fallback)

Frontmatter is parsed by **Oliver** via `oliver meta --from <markdown|textile|cooklang> --format json < file.md` (stdin → stdout JSON). Example:

```bash
oliver meta --from markdown --format json < file.md > meta.json  # {"title":"…","description":"…",…}
oliver meta --from textile --format json < file.textile > meta.json
oliver meta --from cooklang --format json < file.cook > meta.json
# Render auto-strips the same block (no awk) when meta-capable:
oliver render --from markdown < file.md > body.html
```

The adapter (`rc-oliver-adapter.sh:76`) tries `oliver meta` first, validates JSON with `yq`, falls back to `yq --front-matter extract` on current pin `6edb520c` (which lacks `meta`). This keeps the slice green before the upstream bump. The fields Rotkeeper reads are:

- `title`
- `description`
- `author`
- `date`
- `template`
- `palette`
- `render_profile` (per-page XHTML opt-in; `html`/`xhtml`, overrides `render_profile` in `rotkeeper.yaml` for that page only)

All other frontmatter keys pass through untouched. Values are HTML-escaped on template insertion. Rules retained: block must start on line 1 `---` (no BOM, no leading blank line), close at next `---`, `...` not honored, scalar strings only (lists/maps ignored), `null`/empty treated as `""`.

## Template and input contract (stable)

This section is the stable contract that Phase 6 ("Rationalize the Oliver boundary") uses as its definition of truth before any renderer-adjacent responsibility moves out of Bash. It is derived from `rc-oliver-adapter.sh`; if the two ever disagree, the script is authoritative and this document must be updated.

### Input side

- Sources are UTF-8 files with an optional leading YAML frontmatter block. The body format is Markdown by default (`input_format: markdown`), Textile when `input_format: textile` is set, Cooklang when `input_format: cooklang` is set, and any source whose extension is `.textile` or `.cook` renders in that format regardless of the config value. Source-file discovery covers `*.md`, `*.textile`, and `*.cook`; soul sidecar naming and output naming are extension-agnostic (a `.textile` or `.cook` source gets the same `foo.html` output and `foo.soul.md` sidecar as `foo.md`). A `foo.md`/`foo.textile`/`foo.cook` pair in the same directory is a source basename collision and aborts the render — only one source file may exist per page basename.
- The frontmatter block must start on the **very first line** (`---` on line 1 — no BOM, no leading blank line) and close at the next `---` line. A YAML `...` document-end marker is not honored; anything after the closing `---` is body content in the configured format.
- Only the seven fields above are consumed, as **scalar strings**. Lists, maps, and other keys are ignored for template purposes.
- A `.soul.md` sidecar under `bones/meta` may override any of the six metadata fields **per field** (`render_profile` is frontmatter-only); the sidecar value wins only when it is non-empty and not `null`. Without a sidecar, source frontmatter applies.
- `template` resolution: `$template$` selects `${TEMPLATE_DIR}/${template}`. If the named template does not exist or escapes `TEMPLATE_DIR`, the batch manifest's default template (from `default_template` in `bones/config/rotkeeper.yaml`) is used. The page fails if no valid template resolves.

### Template dialect

Templates are HTML files containing exactly seven tokens:

| Token | Source | Insertion |
| --- | --- | --- |
| `$title$` | frontmatter `title` (sidecar wins) | HTML-escaped |
| `$description$` | frontmatter `description` (sidecar wins) | HTML-escaped |
| `$author$` | frontmatter `author` (sidecar wins) | HTML-escaped |
| `$date$` | frontmatter `date` (sidecar wins) | HTML-escaped |
| `$palette$` | frontmatter `palette` (sidecar wins) | HTML-escaped |
| `$assets_root$` | render batch (path prefix to the layout's assets dir) | literal, not escaped |
| `$body$` | Oliver-rendered body fragment | literal, not escaped (it is trusted rendered HTML) |

Escaping is `&` `<` `>` `"` `'` → `&amp;` `&lt;` `&gt;` `&quot;` `&#39;`. `$assets_root$` and `$body$` are the only tokens exempt from escaping — templates must never place untrusted values there, and `$body$` must never be escaped.

Conditionals: `$if(name)$ … $endif$` for `title`, `description`, `author`, `date`, `palette`. When the value is empty (or `null`) the whole block — including its interior newlines — is removed; otherwise the interior text is kept.

- Evaluation is one variable pass at a time (title → description → author → date → palette), and the **first** `$endif$` in the document closes the opener. Do not nest the same variable twice; keep conditionals single-level in practice.
- Order of operations: all `$if$` blocks are resolved first, then the literal token substitution runs.
- Any unrecognized `$word$` token passes through to the output verbatim; it is not an error.

This dialect — seven tokens, five conditional gates, escape/raw split — is **Phase 6 S2**: **Oliver `wrap` is authoritative; adapter tries `oliver wrap --template <file> --meta-json <json> --assets-root <prefix> --body <file>` then falls back to GAWK on pin `6edb520c`**. Example:

```bash
oliver wrap --template bones/templates/theme-spooky-dark.html \
  --meta-json meta.json --assets-root ./assets/ --body body.html > page.html
# or: oliver render --template <file> --meta-json <json> (alternative, feature-detected)
```

Seven tokens remain, same escape/raw split and `$if$` evaluation order. Bash keeps `TEMPLATE_DIR` boundary checks; Oliver handles interpolation when `wrap` is present.

## Sidecar precedence

A `.soul.md` sidecar next to a source file (under `bones/meta`) may override frontmatter fields. Sidecar wins over source frontmatter for the fields listed above. Without a sidecar, source frontmatter applies.

## The adapter boundary (temporary, recorded)

`rc-oliver-adapter.sh` is a pure Bash + GAWK + YQ batch adapter (zero Python). It currently owns:

1. Batch manifest (`TSV`) iteration with boundary assertions (source under content, destination under output).
2. Frontmatter extraction and sidecar merge — **S1: Oliver `meta` is authoritative; adapter tries `oliver meta --from <fmt> --format json` then falls back to `yq --front-matter extract` on pin `6edb520c`; stripping via `awk` remains until `oliver render` auto-strips**.
3. Template resolution — **Bash retains `TEMPLATE_DIR` boundary; Oliver `wrap` receives canonical path**.
4. Oliver invocation and stderr forwarding (including the `--to xhtml` flag when the effective `render_profile` is `xhtml`).
5. Internal `.md`/`.textile`/`.cook` → `.html` link rewriting — **S3: Oliver `render` is authoritative (AST-level `*.md|*.textile|*.cook` → `*.html`, fragment/query preserved, angle-bracket stripped, external/`mailto:` skipped); adapter probes `printf '[x](foo.md)' | oliver render --from markdown | grep foo.html` and skips GAWK when true, else GAWK fallback on pin `6edb520c`**.
6. Template interpolation — **S2: Oliver `wrap` is authoritative; adapter tries `oliver wrap --template <file> --meta-json <json> --assets-root <prefix> --body <file>` then falls back to GAWK on pin `6edb520c`**.

Per the stabilization roadmap, these responsibilities are candidates for incremental movement into Oliver only after the contract above is stable. Bash keeps dispatch, environment setup, filesystem boundaries, orchestration, and packaging. **S1+S2+S3 are the first moves; step 4 remains in Bash (output planning + manifest next).**

## Install paths

Oliver has no stable release yet, but upstream publishes a rolling `builds` release with prebuilt binaries (`oliver-<os>-<arch>` for linux/macos × x86_64/aarch64) plus a published `sha256sums.txt`. `scripts/setup.sh` is download-first: it fetches the platform binary, verifies it against the published checksum, and asserts `oliver --version` reports exactly `commit <OLIVER_PIN>` before installing to `/usr/local/bin/oliver`. Any failure falls back to building the pinned commit from source with Zig 0.16.0:

```bash
git clone https://github.com/drawmeanelephant/oliver.git /tmp/oliver
cd /tmp/oliver
git checkout --quiet <OLIVER_PIN>   # exact commit, never unpinned main
zig build                           # builds the library and CLI into zig-out/
install -m 0755 zig-out/bin/oliver /usr/local/bin/oliver
```

Then either put `oliver` on `PATH` or set `RK_OLIVER_BIN=/path/to/oliver`. CI environments (see `.github/workflows/ci.yml`) run `scripts/setup.sh`, which prefers the builds release (checksum + commit-version verified) and falls back to the Zig 0.16.0 source build when the download path is unavailable.

## Smoke paths

- **Availability check:** `bash rotkeeper.sh preflight` reports whether Oliver is found, executable, and actually runnable (a live smoke render through the real CLI); it fails with one setup message otherwise. `render` runs the same check before rendering.
- **Hermetic (always):** the test harness (`bash rotkeeper.sh test`) builds fixture binaries and exercises frontmatter, sidecars, escaping, links, stderr separation, and manifest consistency without any Oliver dependency. The checked-in fixture at `bones/scripts/tests/fixtures/oliver-smoke/` renders through a fixture binary and its body is compared against `smoke-fixture-expected.html` on every layout pass.
- **Real binary (when present):** the same harness renders `real-oliver-fixture.md` through the discovered executable and asserts exit 0, a well-formed HTML page, and the fixture title in the output. It runs on every layout pass. With a real binary present, the harness also renders an XHTML-profile page through `--to xhtml` and asserts the wrapped document is well-formed via `xmllint`, and asserts that a raw-HTML page selected for XHTML fails with `error.RawHtmlNotXmlWellFormed`. Setting `RK_STRICT=1` turns the real-binary skip paths (missing `oliver`, missing contract corpus) into hard failures so a green run always proves the real binary was exercised — CI runs the harness with `RK_STRICT=1`.
- **Quick local check:** `bash rotkeeper.sh render` on a checkout with content renders everything through Oliver; failures list the page and Oliver's stderr.
