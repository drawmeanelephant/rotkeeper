---
title: "Publish a site"
slug: publishing
template: "rotkeeper-doc.html"
version: "1.1"
updated: "2026-10-02"
doc_type: guide
reviewed: "2026-10-02"
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

### Upload to an existing Cloudflare Pages project

For this repository, use the GitHub Actions procedure below when the
repository already holds the Pages secrets. A local Wrangler login is not
required for that route.

Get the project owner's approval for the project and branch first. A branch
other than the project's configured production branch creates a **preview**,
not a production replacement. Do not create a project, edit DNS, or change
host settings as part of this upload.

For this optional upload tool only, use Node **22** with npm. On macOS you
can install it with `brew install node@22` and add
`$(brew --prefix)/opt/node@22/bin` to `PATH`; the site itself needs no Node
runtime. Confirm `node --version` and `npm --version`. Use the same pinned
Wrangler version as this repository's deployment workflow:

```bash
npx --yes wrangler@4.146.0 login
npx --yes wrangler@4.146.0 whoami
```

Login opens an interactive browser authorization. Run it in your own
terminal. If `whoami` reports an expired login, repeat login before uploading.
Never paste a token into documentation, chat, command arguments, or Git.

After `render`, `links`, and `pack`, upload **only** the generated directory.
For the approved issue #334 walkthrough, the existing project is `rotkeeper`
and the preview branch is `docs-334-walkthrough`:

```bash
npx --yes wrangler@4.146.0 pages deploy output \
  --project-name=rotkeeper --branch=docs-334-walkthrough
```

Use your own approved existing project and non-production branch for another
site. For `sterile`, replace `output` with `dist`. A successful command prints
the deployment URL. Record that URL, not just the branch alias or CLI exit.

Verify the **deployment URL** before declaring success. Assign the URL
printed by Wrangler to `DEPLOYMENT_URL`, then compare the uploaded home,
a nested page you created, and its stylesheet with the local bytes:

```bash
export DEPLOYMENT_URL="https://YOUR-DEPLOYMENT.rotkeeper.pages.dev"
curl -fsS "$DEPLOYMENT_URL/" | cmp - output/index.html
curl -fsS "$DEPLOYMENT_URL/journal/walkthrough.html" | cmp - output/journal/walkthrough.html
curl -fsS "$DEPLOYMENT_URL/assets/css/theme-spooky-dark.css" | cmp - output/assets/css/theme-spooky-dark.css
```

Create `journal/walkthrough.md` with `new --subdir journal` as shown in the
[workflow guide](workflow.html), or substitute another real nested output
path. Nonzero curl or cmp exits mean verification failed. These reads check
public delivery, not visual appearance or assistive-technology behavior.
An archive, a local browser, or a successful CLI upload alone is not
publication evidence.

## This repository's help site

Rotkeeper's own help site uses the Cloudflare Pages project **`rotkeeper`**:

- **Primary URL:** [rot.filed.fyi](https://rot.filed.fyi/)
- **Pages URL:** [rotkeeper.pages.dev](https://rotkeeper.pages.dev/)

Both hostnames serve the same production deployment. The old rotkeeper.com is abandoned.

The docs are **generated output**, not a separate repository or a host-specific application. Cloudflare is the chosen host for this repository's site; anyone using Rotkeeper can still publish their generated site to another static host.

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
   archived page/stylesheet bytes. The enforced site build refreshes the
   product references before uploading only `output/` through the existing
   pinned Wrangler action.
5. Read **Fresh-clone Help walkthrough and approved preview** in the run.
   Its final step must report the unique preview URL and HTTP 200 plus exact
   byte matches for the home page, first page, nested walkthrough page, and
   stylesheet. Record the run URL, commit, commands, artifact hashes, and
   publication evidence. A failed or skipped verification is not success.

This explicit manual input is the only CI preview-publishing path. Ordinary
pull-request CI never receives Pages secrets or deploys. Production remains
the separate publishing workflow's checked push-to-`main` path.

## Cloudflare configuration

The repository's Actions secrets are:

| Secret | Purpose |
| --- | --- |
| `CLOUDFLARE_ACCOUNT_ID` | Account containing the `rotkeeper` Pages project |
| `CLOUDFLARE_API_TOKEN` | Token scoped to that account with **Account → Cloudflare Pages → Edit** only |

The workflow references these secrets only in the production deploy step. Do not print their values, enable shell tracing around them, or copy them into source files. A Pages deployment does not need DNS-edit permission.

The Pages project must have **`main` as its production branch**. Add `rot.filed.fyi` in the project's **Custom domains** settings, not just in DNS. Its proxied CNAME should point to `rotkeeper.pages.dev`. Both hostnames must stay attached to the same project. If the project uses Cloudflare's Git integration, disable its automatic builds so GitHub Actions remains the single publisher.

The active configuration rule `(http.host eq "rot.filed.fyi")` disables
Real User Monitoring (RUM) only for that hostname. Cloudflare's automatically
injected analytics beacon otherwise changes the response bytes and fails
the deployment check. Other hostnames keep their existing analytics settings.

### Initial 522 diagnosis

On 2026-10-01, both hostnames returned HTTP 522. The existing proxied CNAME for `rot.filed.fyi` already targeted `rotkeeper.pages.dev`; the owner confirmed that Pages had **never received a deployment**. The hosting target had no deployed site to serve, rather than needing a different DNS target.

The production deployment and exact-byte verification passed on 2026-10-02
after the hostname-only RUM exclusion. If the Pages URL works but the custom
hostname fails, check the project's Custom domains status and certificate
activation before changing DNS. A CNAME alone does not register a Pages
custom domain.

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
