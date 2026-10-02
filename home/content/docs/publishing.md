---
title: "Publishing the Docs"
slug: publishing
template: "rotkeeper-doc.html"
version: "1.1"
updated: "2026-10-01"
description: "Rotkeeper's help site is built in GitHub Actions and published to Cloudflare Pages. The generated output remains portable to other static hosts."
tags:
  - rotkeeper
  - docs
  - publishing
---

# Publishing the Docs

Rotkeeper's own help site uses the Cloudflare Pages project **`rotkeeper`**:

- **Primary URL:** [rot.filed.fyi](https://rot.filed.fyi/)
- **Pages URL:** [rotkeeper.pages.dev](https://rotkeeper.pages.dev/)

Both hostnames are configured to serve the same production deployment after the first successful publish. The old rotkeeper.com is abandoned.

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
```

The filesystem catalog and autopsy reports supply DIP's discovery and help inputs. DIP runs before rendering so the published site includes the refreshed documentation and matrix. Additional book binders are optional retrieval aids; they are not uploaded.

Run this in a disposable checkout when you only want to inspect the publish: DIP regenerates documentation under `home/content/docs/`. The deployable result is `output/`, not the reports or the source tree.

## GitHub Actions pipeline

The approved workflow file is `.github/workflows/deploy.yml` (**Publish Rotkeeper help**):

1. **Pull requests targeting `main`** install the pinned tools, build the site, and run the checks. They never deploy and do not receive Cloudflare secrets, including fork pull requests.
2. **Pushes to `main`** run the same build and checks, then deploy the checked `output/` artifact to the production branch `main` of the Pages project `rotkeeper`.
3. **After deployment**, the workflow requests both public hostnames and verifies HTTP 200 and byte-for-byte equality with the uploaded home and publishing pages. It retries briefly for propagation and fails if either hostname is not serving that deployment.

Tool installation uses `scripts/setup.sh`, the same checksum- and commit-verified Oliver installer used by CI, with Zig 0.16.0 available for its pinned source-build fallback. Actions are pinned to commit SHAs. Node and Wrangler are used only in the deploy job to upload static files; they are not site build or runtime dependencies.

Build errors, missing entry pages, and broken local links block deployment. Placeholder and page-structure checks, plus the theme accessibility audit, run **warn-only** while the help backlog is open. Sidecar coverage and generated command-reference coverage still depend on issues #328, #331, and #334; the workflow reports them as pending rather than claiming they pass. Issue #334 completes and enforces the site-level gates. Setting `HELP_CHECKS_ENFORCE` to `true` before those pending gates are implemented intentionally blocks publication.

Generated docs and `output/` are not committed by the workflow. The checked site artifact expires after one day.

## Cloudflare configuration

The repository's Actions secrets are:

| Secret | Purpose |
| --- | --- |
| `CLOUDFLARE_ACCOUNT_ID` | Account containing the `rotkeeper` Pages project |
| `CLOUDFLARE_API_TOKEN` | Token scoped to that account with **Account → Cloudflare Pages → Edit** only |

The workflow references these secrets only in the production deploy step. Do not print their values, enable shell tracing around them, or copy them into source files. A Pages deployment does not need DNS-edit permission.

The Pages project must have **`main` as its production branch**. Add `rot.filed.fyi` in the project's **Custom domains** settings, not just in DNS. Its proxied CNAME should point to `rotkeeper.pages.dev`. Both hostnames must stay attached to the same project. If the project uses Cloudflare's Git integration, disable its automatic builds so GitHub Actions remains the single publisher.

### Initial 522 diagnosis

On 2026-10-01, both hostnames returned HTTP 522. The existing proxied CNAME for `rot.filed.fyi` already targeted `rotkeeper.pages.dev`; the owner confirmed that Pages had **never received a deployment**. The hosting target had no deployed site to serve, rather than needing a different DNS target.

The first successful push-to-`main` deployment supplies the missing site. The workflow's public checks then confirm that both hostnames serve it. If the Pages URL works but the custom hostname still fails, check the project's Custom domains status and certificate activation before changing DNS. A CNAME alone does not register a Pages custom domain.

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

*Back to*: [Documentation overview](index.md)
