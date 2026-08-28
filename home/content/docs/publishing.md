---
title: "Publishing the Docs"
slug: publishing
template: "rotkeeper-doc.html"
version: "1.0"
updated: "2026-08-28"
description: "The docs are portable generated output — the same bytes any workstation produces when the full render + DIP + book pipeline runs. Publish them to any static host."
tags:
  - rotkeeper
  - docs
  - publishing
---

# Publishing the Docs

The docs are not a separate repo, and they no longer have a blessed domain (the old rotkeeper.com is abandoned). The docs are **generated output**: run the same toolchain any workstation runs, get the same site, and publish it to whichever static host you like. Someone who clones Rotkeeper and runs the full pipeline on their machine gets the same bytes you would publish — GitHub Pages, rot.filed.fyi, or a plain rsync target are all just places to put those bytes.

## What the pipeline produces

| Command | Artifact | What it is |
| --- | --- | --- |
| `bash rotkeeper.sh render` | `output/` | The whole static site — `docs/` pages, showcase gallery, assets. Self-contained: relative asset links, no JS runtime, no server, no CDN (the DaisyUI prototype vendors its CSS on-prem). |
| `bash rotkeeper.sh dip` | `home/content/docs/dip-matrix.md` (+ book reports) | The documentation-integrity matrix: ownership, stale/obsolete docs, pillars. Shows up in the site on the next `render`. |
| `bash rotkeeper.sh book` (`--docbook`, `--configbook`, `--scriptbook-full`, …) | `bones/book-reports/` | The bound reference set — documentation, configuration, scripts, content retrieval artifacts. |
| `bash rotkeeper.sh showcase` | `home/content/showcase/` → `output/showcase/` | The theme gallery wall, every theme through the same evaluation body. |

A full docs run on a workstation is: `render` + `dip` + the `book` binders you care about, then `render` again so the DIP matrix lands in the site. Nothing in that chain depends on where the output ends up.

## Publish the bytes

`output/` is portable as-is: relative `../assets/` links work at a domain root or a subpath, there is no build step on the host, and no JavaScript is required to read the docs.

- **Any static host** — copy `output/` (rsync, scp, object storage, a file drop) and point the host at it.
- **A domain you own** — same copy; DNS + static hosting is all it takes.
- **GitHub Pages** — one option among many, not the blessed one: publish `output/` (e.g. an Actions workflow that runs `render` + `dip` and uploads a `gh-pages` branch, or a Pages source directory). The interesting property is that Pages serves *identical bytes* to a local run — it is a hosting choice, not a pipeline.

The point of the whole arrangement: **anyone who wants the docs runs the toolchain and gets them.** There is no per-host build, no dead-domain CI, and no reason to treat any particular URL as canonical.

## What not to do

- Don't commit `output/` to the repo — it's the generated tree; `render` and `scan` treat it as output.
- Don't wire CI to a specific domain — the pipeline produces the site; hosting is downstream of the pipeline, not part of it.
- Don't hand-edit generated docs artifacts (`dip-matrix.md`, `bones/book-reports/`) — regenerate them.

---

*Back to*: [Documentation overview](index.md)
