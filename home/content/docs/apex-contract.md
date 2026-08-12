---
title: "Apex Renderer Contract"
slug: apex-contract
template: rotkeeper-doc.html
version: "1.1"
updated: "2026-08-11"
description: "The supported contract between Rotkeeper and the native Apex HTML renderer: executable discovery, input format, output streams, exit codes, and the adapter boundary."
tags:
  - rotkeeper
  - apex
  - rendering
  - reference
---

# Apex Renderer Contract

This page is the authoritative reference for how Rotkeeper drives the native [Apex](https://github.com/ApexMarkdown/apex) renderer. It is the stable contract promised by the Post-PR177 roadmap ("Make Apex boring to run") and the split of responsibilities between the Apex binary and `rc-apex-adapter.sh`.

## Executable discovery

`rc-render.sh` locates Apex in this order:

1. `RK_APEX_BIN` environment variable (explicit override).
2. `apex` resolved via `PATH`.

If neither yields an executable file, `render` fails with exit 1 and prints a setup message covering installation and the environment variable.

## The binary contract

Apex is invoked once per Markdown source file:

```bash
apex <file.md> > body.html 2> warnings.log
```

| Aspect | Contract |
| --- | --- |
| Invocation | `apex <markdown-file>` — one file per invocation |
| Input | Markdown with optional YAML frontmatter (see below) |
| stdout | Rendered **body HTML fragment** (no full page wrapping) |
| stderr | Non-fatal renderer warnings; forwarded through the adapter as warnings, never into the page body |
| Exit 0 | Success |
| Exit 1 | Render failure (e.g. missing input file); page is aborted |
| Version range | 1.1.x. Verified against 1.1.13 and 1.1.15 (2026-08). CI pins 1.1.15. |

The binary is deliberately narrow: it converts Markdown to a body fragment. Everything around that — frontmatter extraction, sidecars, templates, link rewriting, output planning — lives in Rotkeeper's Bash layer, not in Apex.

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

`rc-apex-adapter.sh` is a pure Bash + GAWK + YQ batch adapter (zero Python). It currently owns:

1. Batch manifest (`TSV`) iteration with boundary assertions (source under content, destination under output).
2. Frontmatter extraction and sidecar merge.
3. Template resolution.
4. Apex invocation and stderr forwarding.
5. Internal `.md` → `.html` link rewriting (fragment/query preserved, external and `mailto:` left alone).
6. Template interpolation: `$if(name)$/$endif$` conditionals, then literal replacement of `$title$`, `$description$`, `$author$`, `$date$`, `$assets_root$`, `$body$` with HTML escaping.

Per the stabilization roadmap, these responsibilities are candidates for incremental movement into Apex only after the contract above is stable. Bash keeps dispatch, environment setup, filesystem boundaries, orchestration, and packaging.

## Install paths

macOS or Linux, without a package manager:

```bash
# pick the asset for your platform:
#   apex-<ver>-macos-universal.tar.gz
#   apex-<ver>-linux-x86_64.tar.gz
#   apex-<ver>-linux-aarch64.tar.gz
curl -sL "https://github.com/ApexMarkdown/apex/releases/download/v1.1.15/apex-1.1.15-macos-universal.tar.gz" -o /tmp/apex.tar.gz
tar -xzf /tmp/apex.tar.gz
install -m 0755 "/tmp/apex-1.1.15-macos-universal/apex" /usr/local/bin/apex
```

Then either put `apex` on `PATH` or set `RK_APEX_BIN=/path/to/apex`. CI environments use `scripts/setup-jules.sh`, which pins 1.1.15, verifies the SHA-256 sidecar, and installs to `/usr/local/bin/apex`.

## Smoke paths

- **Availability check:** `bash rotkeeper.sh preflight` reports whether Apex is found, executable, within the supported 1.1.x range, and actually runnable; it fails with one setup message otherwise. `render` runs the same check before rendering.
- **Hermetic (always):** the test harness (`bash rotkeeper.sh test`) builds fixture binaries and exercises frontmatter, sidecars, escaping, links, stderr separation, and manifest consistency without any Apex dependency. The checked-in fixture at `bones/scripts/tests/fixtures/apex-smoke/` renders through a fixture binary and its body is compared against `smoke-fixture-expected.html` on every layout pass.
- **Real binary (when present):** the same harness renders `real-apex-fixture.md` through the discovered executable and asserts exit 0, a well-formed HTML page, and the fixture title in the output. It runs on every layout pass.
- **Quick local check:** `bash rotkeeper.sh render` on a checkout with content renders everything through Apex; failures list the page and Apex's stderr.
