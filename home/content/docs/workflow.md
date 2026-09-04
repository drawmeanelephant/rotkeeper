---
title: "Rotkeeper Workflow"
slug: workflow
template: rotkeeper-doc.html
description: "End-to-end Rotkeeper workflow: install, initialize, author, render, verify, archive, and release. Every step runs through the dispatcher."
tags:
  - rotkeeper
  - workflow
  - guide
---

# Rotkeeper Workflow

This guide walks the full Rotkeeper cycle from a cold checkout to a shipped framework zip. Every operation runs through the dispatcher: `bash rotkeeper.sh <command>` (or `./rotkeeper.sh`).

The cycle is: **preflight → init → author → render → verify → archive → release**, finished by the [release-day checklist](#8-release-day-checklist) in section 8 below.

## 1. Preflight — is the renderer ready?

Oliver is the only renderer and the one external runtime dependency. Check it once up front:

```bash
./rotkeeper.sh preflight
```

It reports whether Oliver is found, executable, and actually runnable (a live smoke render through the real CLI), and exits non-zero with a single actionable message when it is not. `render` runs the same check before every pass, so diagnostics never drift.

To install Oliver on macOS or Linux, follow the install paths in `home/content/docs/oliver-contract.md`, then either add `oliver` to `PATH` or set `RK_OLIVER_BIN=/path/to/oliver`.

## 2. Initialize — build the layout

```bash
./rotkeeper.sh init               # crypt layout (default), minimal config
./rotkeeper.sh init --with-sample # ...plus a sample page to render
```

`init` writes `bones/config/rotkeeper.yaml`, derives all paths for the active layout style (`crypt`, `busy`, or `sterile`), and records a serialized `paths` block. If the repository later moves, `init` heals the path mappings; a relocation mismatch is detected and reported before scripts run.

## 3. Author — write content

Source content is Markdown with YAML frontmatter:

```bash
./rotkeeper.sh new my-page.md     # scaffold a page with frontmatter
```

Frontmatter drives the render: `title`, `description`, `author`, `date`, `template` (per-page template override), and `palette` (theme selection when the template supports it). A `.soul.md` sidecar in `bones/meta` may override any of those fields for a page.

Asset files (CSS, images, fonts) live in the layout's assets directory — `home/assets/` in `crypt`.

## 4. Render — Markdown becomes HTML

```bash
./rotkeeper.sh render
```

The renderer sweeps the content tree (`*.md` and `*.textile` sources), extracts frontmatter (sidecar wins), resolves a template, invokes Oliver once per page (`oliver render --from <markdown|textile>` per `input_format` in `rotkeeper.yaml`, with a `.textile` source always rendering as textile; stdout = body HTML, stderr = warnings), rewrites internal `.md`/`.textile` links to `.html`, and interpolates the page into the template. The adapter's responsibilities and the Oliver binary contract are recorded in `oliver-contract.md`.

If a render fails, the error names the page, Oliver's stderr (warnings never leak into page bodies), and the offending path. `--dry-run` previews the pass without writing; `--verbose` shows detail.

## 5. Verify — scan, links, status

```bash
./rotkeeper.sh scan    # manifest entries + SHA-256 hashes vs. generated files
./rotkeeper.sh links   # audit internal links and local asset references in output
./rotkeeper.sh status  # environment health, counts, render freshness
```

`scan` proves the rendered tree matches the manifest. `links` proves every hyperlink and asset reference resolves — catch a `.md` link the rewrite missed, or a stylesheet that no longer ships.

## 6. Archive — pack the rendered site

```bash
./rotkeeper.sh pack
```

Archives the rendered HTML and metadata into a versioned tarball under `bones/archive/`. This is the deployable artifact of a single site publish.

## 7. Release — ship the framework

```bash
./rotkeeper.sh test              # full harness: all layout styles, hermetic fixtures
./rotkeeper.sh bump --to 0.5.2   # record the microrelease, sync version markers
./rotkeeper.sh release 0.5.2     # build the canonical framework zip
```

`release` stages the repository against an explicit root-entry allowlist, excludes dev-only and forbidden trees (caches, logs, temp, output, credentials), generates `bones/config/release-manifest.txt` inside the archive, and fails fast on unexpected root entries, missing required files, or forbidden artifacts. The zip lands at `bones/archive/releases/rotkeeper-<VERSION>.zip`.

## 8. Release-day checklist <a id="8-release-day-checklist"></a>

Run the full loop before tagging a version — a release is only real when a clean environment reproduces the advertised workflow:

1. **Clean clone.** `git clone` the repo into a fresh directory (no cached env, no leftover `paths` block).
2. **Pinned renderer.** `bash scripts/setup.sh` — it installs Oliver from the upstream `builds` release (checksum + `--version` commit verified against the pinned `OLIVER_PIN`), falling back to a Zig 0.16.0 source build of the same pin when the download path is unavailable (never unpinned `main`). Do not pre-install an Oliver from a different source.
3. **Gate.** `./rotkeeper.sh preflight` must PASS, and `bash rotkeeper.sh test` must be green with `RK_STRICT=1` (forces the real-Oliver renderer smoke and CommonMark contract corpus on every layout pass).
4. **Initialize all three profiles.** `./rotkeeper.sh init --with-sample` in `crypt` (default), then init a `busy` and a `sterile` fixture and render each.
5. **Verify.** `scan`, `links`, `assets`, and `status` report zero drift; `book --docbook` and `dip` bind without new stubs.
6. **Archive.** `pack`, then confirm the tomb: `gzip -t bones/archive/tomb-*.tar.gz` and check `metadata.json` is embedded.
7. **Release.** `./rotkeeper.sh bump --to <VERSION>` (records changelog + roadmap), then `./rotkeeper.sh release <VERSION>`.
8. **Inspect the artifact.** The zip must contain the framework spine (`rotkeeper.sh`, `bones/config/rotkeeper.yaml`, `bones/config/version`, `bones/config/release-manifest.txt`, `bones/scripts/rc-utils.sh`), only `rotkeeper/`-rooted entries, and no caches, logs, archives, or credentials. The harness asserts all of this on every run; spot-check the manifest inside the archive.
9. **Extract and replay.** Unzip to a second clean directory, run preflight → init → render → scan → pack, and confirm the quickstart works from the shipped artifact — then tag the version.

## Day-two operations

- `preflight` — re-check the renderer after upgrades or PATH changes.
- `glue` — regenerate navigation glue for new content directories.
- `assets` — regenerate the asset manifest after adding files.
- `showcase` — regenerate theme preview pages for every template.
- `dip` — audit documentation coverage and obsolete pages.
- `book --docbook` — bind documentation into a single retrieval artifact.
- `test` — run the full integration harness before any release.

## Verification gate

Before any release: `bash -n` on every modified script, `shellcheck` (repository `.shellcheckrc`), `bash rotkeeper.sh test`, `bash rotkeeper.sh status`, and the relevant `--dry-run` for the changed command. The harness rebuilds `crypt`, `busy`, and `sterile` fixtures, renders the checked-in smoke fixture against its golden output, exercises the real Oliver binary when present, and verifies the canonical release archive.