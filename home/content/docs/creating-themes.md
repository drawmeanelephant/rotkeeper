---
title: "Creating a Theme"
slug: creating-themes
template: "rotkeeper-doc.html"
version: "1.0"
updated: "2026-08-28"
description: "How to add a new template or theme without breaking the render pipeline — the token contract, the shared skeleton, registration, XHTML variants, and the validation gates."
tags:
  - rotkeeper
  - themes
  - templates
---

# Creating a Theme

Every template in `bones/templates/` is a **standalone HTML file** rendered by the Oliver `wrap` dialect: the adapter feeds it the page's frontmatter tokens, the rendered body, and the asset root, and `oliver wrap` interpolates the `$token$` / `$if(token)$` markers. This page is the walkthrough for adding a new template or theme without breaking the pipeline — the ground truth is [oliver-contract.md](oliver-contract.md) plus the adapter source (`bones/scripts/rc-oliver-adapter.sh`).

## 1. Start from a member

Copy an existing theme pair — `theme-spooky-dark.html` + `theme-spooky.css` are the plainest — rather than writing a template from scratch. The **shared skeleton** is the contract: variation between themes lives in CSS, ornament, and surface treatment, not in divergent HTML structure.

## 2. The token contract

Typed tokens (html-escaped by `wrap`): `$title$`, `$description$`, `$author$`, `$date$`, `$palette$`, `$version$`, `$subtitle$`, `$tags$`, `$asset_meta$`. Raw tokens: `$assets_root$` (asset prefix, literal) and `$body$` (the rendered markdown, never escaped). Gating uses `$if(name)$ … $endif$` — keep the markers **at column 0** so a removed block leaves no blank line. The **generic hook** (#269) interpolates any other frontmatter key the adapter merges into `wrap_meta` — the necropolis theme's `$page_type$` body hook is the example. Unknown `$tokens$` pass through verbatim.

## 3. The shared skeleton

- **Header** — site/page `$title$` plus optional deck (`$if(description)$`), per theme.
- **Nav** — optional; `theme-textpattern` and the daisy pair ship one. It is driven from the `navigation:` block in `bones/config/rotkeeper.yaml` through the raw-HTML `<site-nav></site-nav>` slot — never hardcode tabs.
- **Main** — `$body$` wrapped in the theme's article element.
- **Footer** — the standardized asset-meta slot, present on every theme:

```html
<footer class="<theme-footer>">
  <p class="footer-credit">Rendered by Rotkeeper · v$version$</p>
$if(asset_meta)$      <p class="footer-asset-meta">$asset_meta$</p>
$endif$$if(tags)$      <p class="footer-tags">$tags$</p>
$endif$    </footer>
```

`v$version$` is live from `bones/config/version` (the same single source `--version` uses). Lore lines live above the slot (see #4).

## 4. Identity primitives (optional)

The haunted house voice — dividers, lore blocks, icons — lives in `home/assets/css/rk-identity.css` (#251). Opt in with one line at the **top** of the theme stylesheet (an `@import` must precede all other rules), then map the `--rk-*` tokens on your `:root`. Full contracts and the token table are in [Theme Families](themes.md) under "Shared identity primitives". A theme that doesn't want the voice simply doesn't import the file.

## 5. Register it

The config-driven theme registry (`theme_registry` in `bones/config/rotkeeper.yaml`, #252) maps mode names to template files and is the per-site selector. Add your template to the registry so `new` lists it and `status`/`render`/`glue` resolve it; the resolver validates every registered entry exists. Per-page `template:` frontmatter always wins over the registry default.

## 6. XHTML variants (optional)

XHTML output is opt-in per page (`render_profile: xhtml`) or per site, and needs a wrapper variant — the `theme-spooky-dark-xhtml.html` pattern (self-closing void elements, `xmlns`). Rendering fails closed on raw HTML under `--to xhtml` (`error.RawHtmlNotXmlWellFormed`), so keep content CommonMark-safe for XHTML pages or accept the constraint.

## 7. Validate before you call it done

| Command | What it proves |
| --- | --- |
| `bash rotkeeper.sh render` | The site still renders with your theme wired in |
| `bash rotkeeper.sh showcase` | Scaffolds a showcase page for your theme and refreshes the gallery — every theme renders the same evaluation body |
| `bash rotkeeper.sh a11y` | The gate auto-discovers your theme via its stylesheet link and follows `@import` chains: AA contrast pairs, visible focus, narrow-viewport overflow strategy |
| `bash rotkeeper.sh test` | Full harness 3/3 layouts + contract/DIP/regression; the S7 registry assertions require your registered template to exist |
| `bash rotkeeper.sh status` | Config sanity, registry resolution, manifest checks |

When you change an **existing** template's structure, rendered goldens diverge — regenerate them with `RK_REGEN_TEMPLATE_GOLDENS=1 bash rotkeeper.sh test` and commit the goldens alongside the template change.

## Common mistakes

- `@import` not at the top of the stylesheet (the a11y gate's chain resolver and browsers both require it first).
- `$if$` markers not at column 0 — blank-line drift in rendered output.
- Styling content instead of the skeleton — Rotkeeper content is markdown-first; the theme styles the chrome, not the prose.
- Shipping a theme that fails the a11y gate — no template joins a family in good standing without passing.
- An XHTML page without a wrapper variant — `render_profile` and template must agree.

---

*Back to*: [Theme Families](themes.md) · [Documentation overview](index.md)
