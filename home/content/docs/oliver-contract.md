---
title: "Oliver Renderer Contract"
slug: oliver-contract
template: rotkeeper-doc.html
version: "1.1"
updated: "2026-08-12"
description: "The supported contract between Rotkeeper and the native Oliver HTML renderer: executable discovery, input format, output streams, exit codes, and the adapter boundary."
tags:
  - rotkeeper
  - oliver
  - rendering
  - reference
---

# Oliver Renderer Contract

This page is the authoritative reference for how Rotkeeper drives the native [Oliver](https://github.com/drawmeanelephant/oliver) renderer — a small, freestanding CommonMark/Textile parsing and rendering library in Zig, and the successor to the Apex renderer. It records the stable contract between the Oliver binary and `rc-oliver-adapter.sh`.

## Executable discovery

`rc-render.sh` locates Oliver in this order:

1. `RK_OLIVER_BIN` environment variable (explicit override).
2. `oliver` resolved via `PATH`.

If neither yields an executable file, `render` fails with exit 1 and prints a setup message covering installation and the environment variable.

## The binary contract

Oliver is invoked once per Markdown source file, reading the file on stdin:

```bash
oliver render --from markdown < file.md > body.html 2> warnings.log
```

| Aspect | Contract |
| --- | --- |
| Invocation | `oliver render --from markdown` — one file per invocation, stdin → stdout |
| Input | Markdown on **stdin** — a leading YAML frontmatter block is stripped by the adapter before invocation (Oliver itself is a pure CommonMark renderer) |
| stdout | Rendered **body HTML fragment** (no full page wrapping) |
| stderr | Non-fatal renderer warnings; forwarded through the adapter as warnings, never into the page body |
| Exit 0 | Success |
| Exit 1 | Render failure (e.g. missing input); page is aborted |
| Version | Oliver's CLI is provisional and has no stable release yet. `preflight` gates on a live smoke render through the real CLI instead of a version range; this table is the compatibility target |

The binary is deliberately narrow: it converts Markdown to a body fragment. Everything around that — frontmatter extraction, sidecars, templates, link rewriting, output planning — lives in Rotkeeper's Bash layer, not in Oliver.

## Rendered Markdown surface

Oliver implements the CommonMark 0.31.2 specification; its own conformance harness scores 652/652 on the normative corpus (see the Oliver docs). That is the contract for what `render` produces:

- **Supported:** ATX and Setext headings, thematic breaks, fenced and indented code blocks (info strings become `language-*` classes), block quotes, tight and loose lists (ordered/unordered, nesting), code spans, emphasis and strong emphasis, inline links and autolinks (URI and email `mailto:`), images, raw HTML (block and inline, passed through verbatim), entity and numeric character references, reference-style links, and GFM pipe tables (header row with required delimiter row, alignment colons `:---` `:---:` `---:`, escaped `\|` pipes, and inline-parsed cells producing `<table><thead>…<tbody>…`).
- **Not supported (not part of CommonMark):** task lists and footnotes render as literal text. Content that needs them should stay CommonMark-safe; raw HTML is passed through verbatim as an escape hatch. The test harness asserts this boundary stays literal in `contract-table.html`.
- **Fidelity verification:** the hermetic golden (`smoke-fixture-expected.html`) is produced by the fixture (fake) binary and verifies the adapter pipeline — frontmatter stripping, link rewriting, escaping — not CommonMark fidelity. Renderer fidelity is asserted by the real-Oliver contract-corpus pass in the test harness (`bones/scripts/tests/fixtures/oliver-contract/`), which runs whenever an `oliver` binary is present.

## Frontmatter

Frontmatter is parsed by the adapter with `yq --front-matter extract`. The fields Rotkeeper reads are:

- `title`
- `description`
- `author`
- `date`
- `template`

All other frontmatter keys pass through untouched. Values are HTML-escaped on template insertion.

## Sidecar precedence

A `.soul.md` sidecar next to a source file (under `bones/meta`) may override frontmatter fields. Sidecar wins over source frontmatter for the fields listed above. Without a sidecar, source frontmatter applies.

## The adapter boundary (temporary, recorded)

`rc-oliver-adapter.sh` is a pure Bash + GAWK + YQ batch adapter (zero Python). It currently owns:

1. Batch manifest (`TSV`) iteration with boundary assertions (source under content, destination under output).
2. Frontmatter extraction and sidecar merge (including stripping a leading YAML frontmatter block before the Markdown reaches Oliver).
3. Template resolution.
4. Oliver invocation and stderr forwarding.
5. Internal `.md` → `.html` link rewriting (fragment/query preserved, external and `mailto:` left alone).
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
- **Real binary (when present):** the same harness renders `real-oliver-fixture.md` through the discovered executable and asserts exit 0, a well-formed HTML page, and the fixture title in the output. It runs on every layout pass.
- **Quick local check:** `bash rotkeeper.sh render` on a checkout with content renders everything through Oliver; failures list the page and Oliver's stderr.
