---
title: "Oliver Renderer Contract"
slug: oliver-contract
template: rotkeeper-doc.html
version: "1.4"
updated: "2026-08-13"
description: "The supported contract between Rotkeeper and the native Oliver HTML renderer: executable discovery, input format, output streams, exit codes, the adapter boundary, and the stable template/input contract."
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

Oliver is invoked once per source file, reading the file on stdin. The input language comes from `input_format` in `bones/config/rotkeeper.yaml` (`markdown` default, `textile` and `cooklang` alternatives), overridden to `textile` for any source whose extension is `.textile` and to `cooklang` for any source whose extension is `.cook`; the adapter and `preflight` pass the resulting format through on every invocation:

```bash
oliver render --from markdown < file.md > body.html 2> warnings.log
oliver render --from textile < file.md > body.html 2> warnings.log
oliver render --from textile < file.textile > body.html 2> warnings.log
oliver render --from cooklang < file.md > body.html 2> warnings.log
oliver render --from cooklang < file.cook > body.html 2> warnings.log
```

| Aspect | Contract |
| --- | --- |
| Invocation | `oliver render --from <markdown\|textile\|cooklang>` — one file per invocation, stdin → stdout; format comes from `input_format` in `bones/config/rotkeeper.yaml` (default `markdown`, validated to `markdown`/`textile`/`cooklang` at environment load; anything else warns and falls back to `markdown`). A source with a `.textile` extension always invokes `--from textile` and one with a `.cook` extension always invokes `--from cooklang`, overriding the config default for that file |
| Input | Markdown, **Textile, or Cooklang** on **stdin** — a leading YAML frontmatter block is stripped by the adapter before invocation (Oliver itself is a pure CommonMark/Textile/Cooklang renderer) |
| stdout | Rendered **body HTML fragment** (no full page wrapping) |
| stderr | Non-fatal renderer warnings; forwarded through the adapter as warnings, never into the page body |
| Exit 0 | Success |
| Exit 1 | Render failure (e.g. missing input); page is aborted |
| Version | Oliver's CLI is provisional and has no stable release yet, so Rotkeeper pins an exact source revision: CI and `scripts/setup-jules.sh` build from commit `e314dbbe74d0cffb269039c3cb750d55140fa26e` (the `OLIVER_PIN` variable in `setup-jules.sh`). Moving the pin is a deliberate act — upgrade it, re-run the harness, and update this table. The pin moved 2026-08-13 from `22b3c779` to `e314dbbe` to pick up the Cooklang frontend (CK1) plus CK2–CK5 (canonical serializer, `scaleRecipe`, richer HTML policy, `.menu` view); Markdown and Textile rendering are byte-identical across the move (Oliver's own gates: CommonMark 652/652, Textile suite untouched). `preflight`'s live smoke render (in the configured format) remains the behavioral safety net on top of the pin |

The binary is deliberately narrow: it converts Markdown, Textile, or Cooklang to a body fragment. Everything around that — frontmatter extraction, sidecars, templates, link rewriting, output planning — lives in Rotkeeper's Bash layer, not in Oliver.

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

## Frontmatter

Frontmatter is parsed by the adapter with `yq --front-matter extract`. The fields Rotkeeper reads are:

- `title`
- `description`
- `author`
- `date`
- `template`
- `palette`

All other frontmatter keys pass through untouched. Values are HTML-escaped on template insertion.

## Template and input contract (stable)

This section is the stable contract that Phase 6 ("Rationalize the Oliver boundary") uses as its definition of truth before any renderer-adjacent responsibility moves out of Bash. It is derived from `rc-oliver-adapter.sh`; if the two ever disagree, the script is authoritative and this document must be updated.

### Input side

- Sources are UTF-8 files with an optional leading YAML frontmatter block. The body format is Markdown by default (`input_format: markdown`), Textile when `input_format: textile` is set, Cooklang when `input_format: cooklang` is set, and any source whose extension is `.textile` or `.cook` renders in that format regardless of the config value. Source-file discovery covers `*.md`, `*.textile`, and `*.cook`; soul sidecar naming and output naming are extension-agnostic (a `.textile` or `.cook` source gets the same `foo.html` output and `foo.soul.md` sidecar as `foo.md`). A `foo.md`/`foo.textile`/`foo.cook` pair in the same directory is a source basename collision and aborts the render — only one source file may exist per page basename.
- The frontmatter block must start on the **very first line** (`---` on line 1 — no BOM, no leading blank line) and close at the next `---` line. A YAML `...` document-end marker is not honored; anything after the closing `---` is body content in the configured format.
- Only the six fields above are consumed, as **scalar strings**. Lists, maps, and other keys are ignored for template purposes.
- A `.soul.md` sidecar under `bones/meta` may override any of the six fields **per field**; the sidecar value wins only when it is non-empty and not `null`. Without a sidecar, source frontmatter applies.
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

This dialect — seven tokens, five conditional gates, escape/raw split — is the candidate for incremental movement into Oliver. Until then, `rc-oliver-adapter.sh` is its canonical implementation.

## Sidecar precedence

A `.soul.md` sidecar next to a source file (under `bones/meta`) may override frontmatter fields. Sidecar wins over source frontmatter for the fields listed above. Without a sidecar, source frontmatter applies.

## The adapter boundary (temporary, recorded)

`rc-oliver-adapter.sh` is a pure Bash + GAWK + YQ batch adapter (zero Python). It currently owns:

1. Batch manifest (`TSV`) iteration with boundary assertions (source under content, destination under output).
2. Frontmatter extraction and sidecar merge (including stripping a leading YAML frontmatter block before the source reaches Oliver).
3. Template resolution.
4. Oliver invocation and stderr forwarding.
5. Internal `.md`/`.textile`/`.cook` → `.html` link rewriting (fragment/query preserved, external and `mailto:` left alone).
6. Template interpolation: `$if(name)$/$endif$` conditionals, then literal replacement of `$title$`, `$description$`, `$author$`, `$date$`, `$assets_root$`, `$body$` with HTML escaping.

Per the stabilization roadmap, these responsibilities are candidates for incremental movement into Oliver only after the contract above is stable. Bash keeps dispatch, environment setup, filesystem boundaries, orchestration, and packaging.

## Install paths

Oliver has no published releases yet — build the current source with Zig 0.16.0:

```bash
git clone --depth 1 https://github.com/drawmeanelephant/oliver.git /tmp/oliver
cd /tmp/oliver
zig build                     # builds the library and CLI into zig-out/
install -m 0755 zig-out/bin/oliver /usr/local/bin/oliver
```

Then either put `oliver` on `PATH` or set `RK_OLIVER_BIN=/path/to/oliver`. CI environments (see `.github/workflows/ci.yml`) install Zig 0.16.0, then run `scripts/setup-jules.sh`, which clones the repository, builds it, and installs to `/usr/local/bin/oliver` when a prebuilt binary is absent.

## Smoke paths

- **Availability check:** `bash rotkeeper.sh preflight` reports whether Oliver is found, executable, and actually runnable (a live smoke render through the real CLI); it fails with one setup message otherwise. `render` runs the same check before rendering.
- **Hermetic (always):** the test harness (`bash rotkeeper.sh test`) builds fixture binaries and exercises frontmatter, sidecars, escaping, links, stderr separation, and manifest consistency without any Oliver dependency. The checked-in fixture at `bones/scripts/tests/fixtures/oliver-smoke/` renders through a fixture binary and its body is compared against `smoke-fixture-expected.html` on every layout pass.
- **Real binary (when present):** the same harness renders `real-oliver-fixture.md` through the discovered executable and asserts exit 0, a well-formed HTML page, and the fixture title in the output. It runs on every layout pass. Setting `RK_STRICT=1` turns the real-binary skip paths (missing `oliver`, missing contract corpus) into hard failures so a green run always proves the real binary was exercised — CI runs the harness with `RK_STRICT=1`.
- **Quick local check:** `bash rotkeeper.sh render` on a checkout with content renders everything through Oliver; failures list the page and Oliver's stderr.
