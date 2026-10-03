---
title: "Publish a site"
slug: publishing
template: "rotkeeper-doc.html"
version: "1.2"
updated: "2026-10-03"
doc_type: guide
reviewed: "2026-10-03"
description: "Rotkeeper's help site is built in GitHub Actions and published to Cloudflare Pages. The generated output remains portable to other static hosts."
tags:
  - rotkeeper
  - docs
  - publishing
---

# Publish a site

## Publish your own site

Follow [installation and the first render](onboarding.html), then
[build and check your content](workflow.html). Publish the active layout's
generated output directory (`output/` for `crypt` and `busy`, `dist/` for
`sterile`) to a static host. Upload the directory's contents so `index.html`
is at the intended site root, including its `assets/` directory.

Keep configuration, source exports, archives, and secrets out of the upload.
No host-side build or application runtime is needed. Test the uploaded
home page, a nested page, and a stylesheet after publishing. Preserve the
HTML if you want byte-for-byte verification; disable host features that
inject analytics or rewrite it.

The commands below build **this repository's help site**. Their deployment
workflow and Cloudflare credentials do not automatically publish another
user's site. Use your host's upload procedure for your own output.

For your own site, record your host's deployment URL and verify public
delivery against your generated files, including a nested page, stylesheet,
and local image. A local archive or successful upload alone is not
publication evidence. These checks do not replace visual or
assistive-technology testing.

## This repository's help site

Rotkeeper's own help site uses the Cloudflare Pages project **`rotkeeper`**:

- **Primary URL:** [rot.filed.fyi](https://rot.filed.fyi/)
- **Pages URL:** [rotkeeper.pages.dev](https://rotkeeper.pages.dev/)

Both hostnames serve the same production deployment. The old rotkeeper.com is abandoned.

The docs are **generated output**, not a separate repository or a host-specific application. Cloudflare is the chosen host for this repository's site; anyone using Rotkeeper can still publish their generated site to another static host.

**Publishing this repository is Actions-only.** Follow the existing GitHub
Actions procedures below, using the existing project and repository secrets.
Do not install Node, npm, npx, or Wrangler locally, run local Cloudflare
login, or supply another token for this walkthrough. Wrangler is an uploader
implementation detail inside Actions, not a Rotkeeper runtime requirement.
Do not create a Pages project or change DNS, account, zone, or host settings.

## What the pipeline produces

| Command | Artifact | What it is |
| --- | --- | --- |
| `bash rotkeeper.sh render` | `output/` | The whole static site — `docs/` pages, showcase gallery, assets. Self-contained: relative asset links, no JS runtime, no server, no CDN (the DaisyUI prototype vendors its CSS on-prem). |
| `bash rotkeeper.sh dip` | `home/content/docs/dip-matrix.md` (+ book reports) | The documentation-integrity matrix: ownership, stale/obsolete docs, pillars. Shows up in the site on the next `render`. |
| `bash rotkeeper.sh book` (`--docbook`, `--configbook`, `--scriptbook-full`, …) | `bones/book-reports/` | The bound reference set — documentation, configuration, scripts, content retrieval artifacts. |
| `bash rotkeeper.sh showcase` | `home/content/showcase/` → `output/showcase/` | The theme gallery wall, every theme through the same evaluation body. |

## Build locally

Install the tools with `bash scripts/setup.sh`, then run the same ordered build used by the publishing workflow:

```bash
bash rotkeeper.sh preflight
bash rotkeeper.sh book --fsbook
bash rotkeeper.sh autopsy --all
bash rotkeeper.sh dip
bash rotkeeper.sh render
bash rotkeeper.sh links
bash rotkeeper.sh a11y
bash rotkeeper.sh status
bash rotkeeper.sh test --site
```

The filesystem catalog and autopsy reports supply DIP's discovery and help inputs. DIP runs before rendering so the published site includes the refreshed documentation and matrix. Additional book binders are optional retrieval aids; they are not uploaded.

Run this in a disposable checkout when you only want to inspect the publish: DIP regenerates documentation under `home/content/docs/`. The deployable result is `output/`, not the reports or the source tree.

## GitHub Actions pipeline

The approved workflow file is `.github/workflows/deploy.yml` (**Publish Rotkeeper help**):

1. **Pull requests targeting `main`** install the pinned tools, build the site, and run the checks. They never deploy and do not receive Cloudflare secrets, including fork pull requests.
2. **Pushes to `main`** run the same build and checks, then deploy the checked `output/` artifact to the production branch `main` of the Pages project `rotkeeper`.
3. **After deployment**, the workflow requests both public hostnames and verifies HTTP 200 and byte-for-byte equality with the uploaded home and publishing pages. It retries briefly for propagation and fails if either hostname is not serving that deployment.

Tool installation uses `scripts/setup.sh`, the same checksum- and commit-verified Oliver installer used by CI, with Zig 0.16.0 available for its pinned source-build fallback. Actions are pinned to commit SHAs. Node and Wrangler are used only in the deploy job to upload static files; they are not site build or runtime dependencies.

The build calls `bash rotkeeper.sh test --site`. All six
[site quality gates](workflow.html#enforced-site-gates) are enforced:
placeholder-free Help and Docs, whole-site local links, audited documentation
stylesheets, sidecar coverage/reachability, generated dispatcher references,
and one H1 plus a nav landmark on every documentation page. Reviewed authored
guides and complete generation inputs are required too. There is no warn-only
or `continue-on-error` path. A failed gate blocks the artifact upload and
deployment.

Generated docs and `output/` are not committed by the workflow. The checked site artifact expires after one day.

### Run the approved preview walkthrough through GitHub

The existing **Rotkeeper CI** workflow has an optional manual input,
`publish_walkthrough`, disabled by default. The repository's secrets supply
the upload credentials; no local Cloudflare login is needed.

1. Get explicit owner approval for publishing to project `rotkeeper`, preview
   branch `docs-334-walkthrough`. This workflow never selects the production
   branch or changes host settings.
2. In GitHub Actions, choose **Rotkeeper CI**, **Run workflow**, and the branch
   containing the intended site. Enable `publish_walkthrough`. With the
   authenticated GitHub CLI, the equivalent is:

   ```bash
   gh workflow run ci.yml --ref YOUR-BRANCH -f publish_walkthrough=true
   ```

3. The full Linux/macOS matrix must pass first. The walkthrough then reads
   the rendered Help hub, onboarding, workflow, and publishing pages from
   that checked build. It makes a fresh remote clone at the selected commit,
   verifies that generated artifacts are absent, installs the documented
   tools, and runs `init`, `new`, the onboarding reference refresh
   (`book --fsbook`, `autopsy --all`, `dip`), `render`, checks, and `pack`.
4. It checks the gzip archive, embedded metadata, source JSON export, and
   root/nested image URLs and copied/archived page, stylesheet, and image bytes.
   The enforced site build refreshes the
   product references before uploading only `output/` through the existing
   pinned Wrangler action.
5. Read **Fresh-clone Help walkthrough and approved preview** in the run.
   Its final step must report the unique preview URL and HTTP 200 plus exact
   byte matches for the home page, first page, nested walkthrough page, and
   stylesheet and local image. Record the run URL, commit, commands, artifact hashes, and
   publication evidence. A failed or skipped verification is not success.

This explicit manual input is the only CI preview-publishing path. Ordinary
pull-request CI never receives Pages secrets or deploys. Production remains
the separate publishing workflow's checked push-to-`main` path.

The [completed walkthrough](workflow.html#completed-clean-clone-walkthrough-2026-10-02)
already records a successful run and verified preview. Reuse that evidence;
do not dispatch another publication merely to refresh its timestamp.

## Cloudflare configuration

The repository's Actions secrets are:

| Secret | Purpose |
| --- | --- |
| `CLOUDFLARE_ACCOUNT_ID` | Account containing the `rotkeeper` Pages project |
| `CLOUDFLARE_API_TOKEN` | Token scoped to that account with **Account → Cloudflare Pages → Edit** only |

The workflows reference these existing secrets only in the production and
explicitly approved preview upload steps. Do not print their values, enable
shell tracing around them, or copy them into source files. A Pages deployment
does not need DNS-edit permission. No new credentials are needed.

The existing project uses **`main` as its production branch** and has
`rot.filed.fyi` attached as a custom domain. This is deployment context, not
an instruction to reconfigure hosting. GitHub Actions remains the publisher.

### Initial 522 diagnosis

On 2026-10-01, both hostnames returned HTTP 522. The existing proxied CNAME for `rot.filed.fyi` already targeted `rotkeeper.pages.dev`; the owner confirmed that Pages had **never received a deployment**. The hosting target had no deployed site to serve, rather than needing a different DNS target.

The production deployment and exact-byte verification passed on 2026-10-02
after a hostname-only Real User Monitoring (RUM) exclusion. That historical
success does not prove current custom-domain delivery.

### Current delivery limitation (2026-10-03) <a id="current-delivery-limitation-2026-10-03"></a>

[Production run 37095154368](https://github.com/drawmeanelephant/rotkeeper/actions/runs/37095154368)
built, checked, and uploaded successfully, then failed exact-byte verification
of `https://rot.filed.fyi/docs/publishing`. The Pages hostname matches the
deployed page; the custom domain's email obfuscation rewrites command examples
and injects a decoding script.

Report this as a separate hosting concern, not an installation or upload
failure. Keep HTTP 200 and exact-byte verification unchanged. The owner
accepts the verified GitHub-runner preview for issue #334; fixing custom-domain
settings is not a prerequisite or an authorized part of that walkthrough.

## Publish the bytes

`output/` is portable as-is: relative `../assets/` links work at a domain root or a subpath, there is no build step on the host, and no JavaScript is required to read the docs.

- **Any static host** — copy `output/` (rsync, scp, object storage, a file drop) and point the host at it.
- **A domain you own** — same copy; DNS + static hosting is all it takes.
- **GitHub Pages** — another hosting option for your own site. Publish the generated `output/` with your own workflow or Pages source configuration; this repository's workflow uses Cloudflare Pages instead.

Hosting remains downstream of the build. The primary URL for this repository is `https://rot.filed.fyi/`; the generated site's relative links do not depend on that domain.

## What not to do

- Don't commit `output/` to the repo — it's the generated tree; `render` and `scan` treat it as output.
- Don't add host-specific URLs to templates or local asset links — deployment and public-host checks belong in the workflow, not in the renderer.
- Don't hand-edit generated docs artifacts (`dip-matrix.md`, `bones/book-reports/`) — regenerate them.

---

**Back to:** [Help](../help/index.html) · [Build workflow](workflow.html)
