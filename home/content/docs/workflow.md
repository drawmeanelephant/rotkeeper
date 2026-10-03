---
title: "Write, build, check, and ship"
slug: workflow
template: rotkeeper-doc.html
doc_type: guide
reviewed: "2026-10-02"
description: "Content formats, frontmatter, site checks, packaging, documentation maintenance, and troubleshooting."
---

# Write, build, check, and ship

First [install and initialize Rotkeeper](onboarding.html). Run the commands
below from the repository root. Paths use the default `crypt` layout;
`bash rotkeeper.sh status` shows the active paths for other layouts.

## Write content

Create a new page, then edit the source file:

```bash
bash rotkeeper.sh new notes.md --subdir journal --title "Notes" --tags "journal,example"
```

This creates `home/content/journal/notes.md`. Bare filenames get `.md`.
Nested filenames and `--subdir` must stay inside the content root.

### Frontmatter and Markdown

```markdown
---
title: "Notes"
description: "A short summary."
template: rotkeeper-doc.html
tags:
  - journal
---

# Notes

Write a paragraph, then link to [another page](../my-page.md).
```

Oliver renders the body and the template wraps it. Internal `.md`,
`.textile`, and `.cook` links become `.html`. A source's directory and
basename determine its output path; `slug` does not move it. `template`
overrides the site default. Sidecar frontmatter wins over source frontmatter.
Use CommonMark headings, lists, links, and fenced code. Oliver supports
pipe tables; do not assume every extension from another Markdown renderer
is supported.

### Local assets <a id="local-assets"></a>

Keep local images in `home/assets/images/` in the default layout. Rendering
copies the asset tree to `output/assets/`. Body asset URLs pass through
rendering unchanged: write them relative to the **rendered page**, not the
source file's location under `home/content/`.

For `home/content/my-page.md`, which renders to `output/my-page.html`:

```markdown
![Rotasan reference](assets/images/shikabane-rotasan-reference.jpg)
```

For `home/content/journal/notes.md`, which renders to
`output/journal/notes.html`:

```markdown
![Rotasan reference](../assets/images/shikabane-rotasan-reference.jpg)
```

Both examples use an image already shipped in this checkout. Replace the
filename with your own image and supply descriptive alt text. Add one
`../` for each directory level below the output root. The same depth rule
applies to other local body assets and to Textile image URLs. In `busy`,
source assets live in `assets/`; in `sterile`, they live in `src/assets/`
and render under `dist/assets/`. The rendered asset directory is always
`assets/`, so the URL rule stays the same.

Only page-link extensions (`.md`, `.textile`, `.cook`) are rewritten to
`.html`; image paths are not rebased from the source tree. Keep URLs
relative so they also work when the site is hosted under a URL prefix.
After editing, run `bash rotkeeper.sh render`, then `bash rotkeeper.sh links`
and open the rendered page to check that the image loads.

### Textile and Cooklang

```bash
bash rotkeeper.sh new notes.textile --subdir journal --title "Textile notes"
bash rotkeeper.sh new soup.cook --subdir recipes --title "Soup"
```

A `.textile` file always selects Textile; a `.cook` file always selects
Cooklang. A `.md` file uses the site's `input_format`, which defaults to
Markdown. Keep different basenames in the same directory: `notes.md` and
`notes.textile` both map to `notes.html` and cause a collision.

See the [Textile guide](textile-guide.html) for syntax. A Cooklang source
may contain `Add @water{250%ml} to a #pot{}. Heat for ~{5%minutes}.`
The new-source scaffold supplies a sample recipe that you can replace.
Cooklang recipes may keep the title in frontmatter rather than a Markdown
heading. The [Oliver contract](oliver-contract.html) defines all three
input formats.

### Sidecars

`bash rotkeeper.sh new notes.md --subdir journal --soul` also creates
`bones/meta/journal/notes.soul.md` if it is absent. Use a new filename when
trying this example if `journal/notes.md` already exists.

The scaffold's null review fields and unfinished notes are not reviewed
documentation. Replace the notes and record the review date and version.
The lookup path is content-relative; `target_file` inside the sidecar is
repository-relative. Directory sidecars describe sections, while core-file
sidecars feed DIP references. See the
[sidecar contract](new-ritual.html#sidecar-contract) before adding or
changing one.

## Choose a theme

List templates with `bash rotkeeper.sh new --list`. Choose a per-page
`template`, or change `theme_registry.default` in
`bones/config/rotkeeper.yaml` for the site. The
[theme guide](themes.html) covers palettes and the
[theme development guide](creating-themes.html) covers wrappers and CSS.

```bash
bash rotkeeper.sh showcase
bash rotkeeper.sh render
```

Showcase generates comparison sources, which render like other content.
The [XHTML guide](xhtml-profile.html) explains how to pair
`render_profile: xhtml` with an XHTML-compatible wrapper.

## Build and check

```bash
bash rotkeeper.sh preflight
bash rotkeeper.sh glue --dry-run
bash rotkeeper.sh glue
bash rotkeeper.sh render
bash rotkeeper.sh links
bash rotkeeper.sh a11y
bash rotkeeper.sh scan
bash rotkeeper.sh status
```

- `preflight` checks renderer discovery, executability, and a live smoke render.
- `glue` creates missing directory indexes and refreshes marked navigation in authored indexes. It does not write task-guide prose.
- `render` converts sources, wraps pages, rewrites source links, and runs asset synchronization. Stale output deletion requires the generated-tree ownership marker.
- `assets` can be run separately after asset changes: `bash rotkeeper.sh assets`. It mirrors local assets and rebuilds `bones/asset-manifest.yaml`.
- `links` checks local page, fragment, and asset targets. It does not prove external sites are reachable.
- `a11y` runs a static theme audit. It is not a substitute for browser and assistive-technology testing.
- `scan` checks the render/archive ledger in `bones/manifest.txt`. It is not the asset-manifest generator.
- `status` reports environment health and freshness; inspect warnings rather than treating the command's exit alone as proof.

`render --dry-run` previews output changes. Most dry-runs still create
bootstrap logs. Consult each command reference for supported flags and
exceptions.

To omit product documentation from your own site, set
`render_system_docs: false` in `bones/config/rotkeeper.yaml`. It excludes
Docs, Help, and `messages/`. Replace the repository homepage and remove
links to those omitted pages before disabling them.

## Archive the site

```bash
bash rotkeeper.sh pack --dry-run
bash rotkeeper.sh pack
```

Default packing archives the generated site, embeds `metadata.json`, and
exports Markdown sources to JSON under `bones/archive/`. Archive names
contain a timestamp and random tag, not the framework version.
`pack --content` archives sources but excludes `help/`; `pack --self`
bundles the system, sources, and output. Neither mode deploys a website.
Do not publish source exports unintentionally.

Use the [publishing guide](publishing.html) to upload the generated output
directory. Do not commit or hand-edit `output/`.

## Package a framework release

Site publication does not require a version bump or framework release.
For an intentional framework release:

```bash
bash rotkeeper.sh test
bash rotkeeper.sh bump --patch -m "Describe the release" --dry-run
```

Review the preview. When ready, run the same bump without `--dry-run`, then
`bash rotkeeper.sh release`. `bump` requires exactly one version selector
and a message. It updates `bones/config/version`, CHANGELOG, and the build
log. `--commit` is optional and can stage unrelated work, so do not use it
without reviewing the tree.

`release` builds `bones/archive/releases/rotkeeper-VERSION.zip`. It validates
the distribution's root allowlist, required files, exclusions, and embedded
release manifest. This distributes Rotkeeper, not just your rendered site.

## Maintain documentation

```bash
bash rotkeeper.sh book --fsbook
bash rotkeeper.sh autopsy --all
bash rotkeeper.sh dip --dry-run
bash rotkeeper.sh dip
bash rotkeeper.sh render
bash rotkeeper.sh links
```

The filesystem book supplies DIP's core inventory. Autopsy reads static
help and output annotations. DIP rebuilds owned references, refreshes the
marked command index, and reports missing sections, placeholders, sidecar
coverage, and ownership. Fix generated reference information in the script
or sidecar, not the rendered page.

Task guides declare `doc_type: guide` and a `reviewed: YYYY-MM-DD` date.
They have no core `target_file` and remain author-owned. DIP reports them
separately, including missing/older review dates and unfinished prose; it
does not require command-reference sections or suppress their findings.
Review a guide whenever its instructions change.

### Enforced site gates

```bash
bash rotkeeper.sh test --site
```

This builds the current checkout through `preflight`, `book --fsbook`,
`autopsy --all`, `dip`, and `render`, then checks:

1. No unfinished placeholder text in rendered Help or Docs, including code examples.
2. No broken local links, fragments, or assets anywhere in the rendered site.
3. Every stylesheet used by Help or Docs has a passing static accessibility audit.
4. Every non-exempt DIP target has an existing sidecar, with no unreachable sidecars.
5. Every script-backed dispatcher command, including aliases, has a generated
   reference and a link in the marked, generated Docs command index. Manual
   command rows outside that block fail.
6. Every Help and Docs source is rendered; each rendered page has exactly one
   H1 and a nav landmark. Missing or disabled documentation fails.

Help and Docs are the product-documentation scope, recursively, including
directory indexes, authored guides, references, Textile pages, and the DIP
matrix. Other site content is outside the page-structure and placeholder
checks, but not the whole-site link check. DIP exceptions apply to reference
and sidecar generation only; they do not exempt a rendered page from checks.
Both core-reference rows and the separate authored-guide report are consumed.
Guides must be reviewed and placeholder-free; missing generation inputs or
ambiguous ownership also fail.

The full `test` runs these same gates on a disposable copy of the tracked
working site, including current edits. It refreshes only the copy's
checkout-specific paths with plain `init`, checks parent configuration and
edit preservation, and runs negative regressions for each gate. `test --site` checks
the actual output artifact in the current checkout. CI and the publishing
workflow both enforce this mode before accepting or uploading that output.
There is no warn-only switch. Neither mode publishes content.

DIP's aggregate `Stub`, `Stale`, and `Unowned` counts are not interchangeable
with site defects. The gate prints section gaps, unowned paths, staleness,
and authored-guide states rather than silently dropping them. The inherited
19 stub rows include template pages still marked `status: stub` despite
populated sections, missing overview sections for `.agentignore` and the
version file, internal libraries without CLI help, and scripts with no
annotated side effects. These are not missing sidecars or rendered
placeholders. Six unowned pages are four fixture directory indexes,
`daisyui-map.md`, and `textile-showcase.textile`, not orphaned sidecars.
Git staleness is a review signal; it is unknown in copies without history.
The gates independently check actual sidecar files, command-reference
contracts/usage, rendered text, structure, links, and audited stylesheets.

Optional binders include `book --docbook`, `book --scriptbook-full`, and
`book --configbook`. They write retrieval aids under `bones/book-reports/`,
not authoritative policy or files to deploy.

To extend the CLI, follow the [command development guide](new-ritual.html)
and [contribution rules](CONTRIBUTING.html). Configuration shapes are in the
[schema reference](rotkeeper-schemas.html).

## Troubleshoot

| Message or symptom | What to check |
| --- | --- |
| `Missing required dependency` | Install the named tool. Confirm mikefarah `yq` v4, GNU `gawk`, and Bash 4+ are on `PATH`. |
| Oliver missing or rendering fails before page discovery | Run `preflight`; fix `PATH` or `RK_OLIVER_BIN`, then rerun it. |
| `YAML configuration is malformed` | Validate `bones/config/rotkeeper.yaml` with `yq eval '.'`; repair YAML rather than removing validation. |
| Cached paths do not match the current repository | From the copied or moved checkout, run `bash rotkeeper.sh init` to derive safe paths from its physical root and active layout and replace the stale cache. Normal commands reject the mismatch until repaired. `init --dry-run` previews without rewriting the cache; it still creates local bootstrap logs. Repair malformed YAML or escaping symlinks first. |
| `File already exists` | Edit that source, or choose another filename. `new` does not overwrite it. |
| `Source basename collision` | Keep only one source format for a directory/basename pair. |
| `RawHtmlNotXmlWellFormed` | Remove incompatible raw HTML or use the HTML profile with an HTML wrapper. |
| `No templates found` | Provide templates in the active layout's template directory. |
| `links` reports `(outside rendered root)` for an image | Follow the [local asset depth rule](#local-assets): use `assets/images/...` from a root page, `../assets/images/...` from a one-level nested page. Do not use the source-relative path from `home/content/`. Fix the source, render again, and rerun `links`. |
| Broken links | Repair the source link or create the intended target, render again, then rerun `links`. |
| `realpath: illegal option -- m` on macOS | Install Homebrew coreutils and put its `libexec/gnubin` directory on `PATH`. Do not weaken canonical-path checks. |
| Site returns 200 but deployment's uploaded-byte check fails | Ensure the host does not inject analytics or otherwise rewrite HTML. This repository disables Cloudflare RUM only for `rot.filed.fyi`. |

## Release-day checklist <a id="8-release-day-checklist"></a>

On a fresh checkout, follow [installation](onboarding.html), run
`preflight`, `init`, `new`, `render`, `links`, `pack`, and the
[publishing steps](publishing.html). Include a page with a local image:
follow the [local asset depth rule](#local-assets), confirm `links` passes,
and open the rendered page to check the image. Then run the full test harness and
inspect/extract the framework release if that is the intended deliverable.
The separate site-level quality work records this clean-clone walkthrough;
the checklist alone is not evidence that it passed.

## Completed clean-clone walkthrough (2026-10-02)

Evidence for issue #334 and documentation epic #325:
[successful GitHub Actions run 37032630378](https://github.com/drawmeanelephant/rotkeeper/actions/runs/37032630378).
The tested source commit was `33900d4a908ff26680f9c223d4fe5610696a1948`.
Both Linux and macOS full matrices passed before the walkthrough job ran.
The repository owner approved project `rotkeeper`, preview branch
`docs-334-walkthrough`, and publication through GitHub's existing secrets.

The job read the **rendered** Help hub and its onboarding, workflow, and
publishing pages from the checked CI artifact. It cloned that remote branch
afresh and asserted the exact commit, with no generated output, filesystem
book, autopsy help report, or manifest present. It did not copy a working
checkout's generated artifacts.

| Step | Commands and observed result |
| --- | --- |
| Install | `sudo apt-get update`, `sudo apt-get install -y shellcheck coreutils`, checksum-verified Zig 0.16.0 installation, then `bash scripts/setup.sh`. The rolling Oliver binary reported a newer commit and was rejected; setup built exactly `b84f6368181079b9df2fc2c28646ffcb29ffd2ff`. `preflight` passed. |
| Initialize | `bash rotkeeper.sh init --with-sample` completed and wrote this clone's active paths. |
| Create | `bash rotkeeper.sh new my-page.md --title "My page" --description "My first Rotkeeper page."` and `bash rotkeeper.sh new walkthrough.md --subdir journal --title "Walkthrough"` created both sources without overwriting anything. |
| Refresh and render | `book --fsbook`, `autopsy --all`, `dip`, then `render`, through the dispatcher. Render produced **133 pages**. `links` checked **8,451 links with zero broken**; `a11y` passed all **14 static theme audits**; `status` reported current output and all 22 scripts matching 0.8.1. |
| Pack | `bash rotkeeper.sh pack` produced `tomb-2026-10-02_164337-0735.tar.gz` and `tomb-export-2026-10-02_164337-0735.json`. `gzip -t` passed. The JSON export parsed as an array; embedded metadata had mode `default` and `file_count: 191`. Archived home, first page, nested page, and stylesheet matched the local files exactly. |
| Gate and publish | `bash rotkeeper.sh test --site` passed all six gates. The existing pinned Wrangler action ran `pages deploy output --project-name=rotkeeper --branch=docs-334-walkthrough`, uploading only generated output. The publication verifier passed at **16:44:31 UTC**. |

The archive's compressed SHA-256 was
`894458bf0e0fd555623c13ede3493398fc58d4b3bc97be731ce1fdce73de10bd`.
Its embedded pre-metadata tar SHA-256 was
`eb608ded2b72b59515ebadb716314b98c9f3e38d59ba019db407654368a73fb1`.
No archive, source export, log, or rendered site is committed with this evidence.

### Public delivery evidence

The immutable deployment URL is
[d8a5074a.rotkeeper.pages.dev](https://d8a5074a.rotkeeper.pages.dev/).
The following anonymous requests returned HTTP 200 and **exactly matched
the uploaded files**, not just expected titles:

| Requested route | Bytes | SHA-256 |
| --- | --- | --- |
| `/` | 2,343 | `487946af2e714f928eb78a0d78a5439ac9b36a979359c926c0312d65cdba3281` |
| `/my-page.html` | 1,264 | `24ecd7031a205cf5077a3726a9980e8aaffc2d9c8f6c1295162caebc29aefee4` |
| `/journal/walkthrough.html` | 1,236 | `7754208d3c785fb1af9fc9a1f0ef17ea65d95319403fad8c52306e91b1958781` |
| `/assets/css/theme-spooky-dark.css` | 101 | `371d102f4aaf8377f89e5d6c8a7791bf87ab6aa5a6de00fc9551ada07e3b4d1b` |

Production, DNS, access controls, and host settings were unchanged.
Cloudflare RUM remains disabled only for `rot.filed.fyi`.

### Findings fixed and validation limits

- The first real run stopped on eight broken links in the historical
  checked-in DIP matrix. Onboarding now requires the reference refresh
  before the first render. No link assertion was relaxed.
- The next run uploaded a preview but failed public verification with
  Cloudflare error 1010/HTTP 403 for Python's default user agent. The final
  run used the existing production verifier's `rotkeeper-deploy-check`
  header and passed exact-byte checks. No security setting was disabled.
- A supplemental macOS clone entered through `/tmp` hit canonical-path
  boundary errors. Repeating from `/private/tmp` with a physical working
  directory passed rendering, links, all theme audits, packing, gzip,
  metadata, and archive byte checks. Onboarding now uses `cd -P`.
- Site gates covered **87 Help/Docs pages**, **18 commands plus the smoke
  alias**, both documentation stylesheets, **47 present sidecars**, zero
  missing/unreachable sidecars, and **12 Reviewed authored guides** with no
  placeholders. The separate reference report still showed 19 Stub rows,
  two Stale rows (three known stale targets overall), and six unowned
  pages, with their meanings explained above rather than ignored.
- The strict full suite passed all three layouts locally and in both CI
  operating systems, including all **15 negative gate regressions**.
  Bash syntax, ShellCheck, workflow lint, status, and supported build/audit
  dry-runs passed. `test --dry-run` remains only the legacy-command suite.
- Browser DOM/navigation spot checks worked. No screenshot, visual-review,
  or assistive-technology pass is claimed. GitHub reported an existing
  pinned Wrangler action Node 20 deprecation warning while successfully
  running it under Node 24; the upload tool itself used Node 22.

This is the prepared issue/epic evidence summary. Posting it or closing
issues still requires owner approval.

**Back to:** [Help](../help/index.html) · [Command reference](index.html)
