---
title: "Create a theme"
slug: creating-themes
template: rotkeeper-doc.html
doc_type: guide
reviewed: "2026-10-02"
description: "Build a local HTML wrapper and stylesheet, register the template, and check rendering and accessibility."
---

# Create a theme

Templates are standalone HTML files using Oliver's `wrap` dialect. Begin
with an existing wrapper and its stylesheet. New repository files require
maintainer approval; this guide does not authorize adding a dependency or
build system.

## Keep the wrapper contract

Use `$body$` for rendered content and `$assets_root$` for local asset paths.
Those slots are raw. Metadata tokens such as `$title$`, `$description$`,
`$author$`, `$date$`, `$palette$`, `$version$`, `$subtitle$`, `$tags$`, and
`$asset_meta$` are escaped by Oliver. Other merged frontmatter keys can also
be tokens; unknown tokens remain literal.

```html
<link rel="stylesheet" href="$assets_root$css/my-theme.css">
<header><h1>$title$</h1></header>
<main>$body$</main>
```

Do not replace `$body$` with an escaped metadata token. Do not hard-code a
deployment domain or root-absolute asset path. The adapter adds one-H1
normalization and documentation navigation to Docs and Help pages.
See the [Oliver contract](oliver-contract.html) for the complete interface.

## Include metadata and optional navigation

Use conditional slots with markers at column zero:

```html
<footer>
  <p>Rendered by Rotkeeper · v$version$</p>
$if(asset_meta)$  <p>$asset_meta$</p>
$endif$$if(tags)$  <p>$tags$</p>
$endif$</footer>
```

`version` comes from `bones/config/version`. For configured site navigation,
put `<site-nav></site-nav>` in the wrapper and use the `navigation` block
in `bones/config/rotkeeper.yaml`. The adapter inserts literal navigation
HTML with page-relative links.

Shared decorative styles are available in `home/assets/css/rk-identity.css`.
An optional `@import url("rk-identity.css");` must precede other CSS rules.
Use the existing styles and their `--rk-*` tokens rather than duplicating
them. Decorative markup must not carry essential instructions.

## Register and select

Add a named entry under `theme_registry` and, if desired, set `default` to
the new wrapper. Registry names do not replace filenames in `template`
frontmatter. `new --list` enumerates available HTML files, whether or not
each one has a registry name.

Set `template: my-theme.html` on a test page. The wrapper must exist in the
active layout's template directory. Put its stylesheet in the active assets
directory so `render` can synchronize it.

## Use an XHTML wrapper when needed

An XHTML page needs an XML-compatible wrapper, such as
`theme-spooky-dark-xhtml.html`, and `render_profile: xhtml`. Use self-closing
void elements and the XHTML namespace. The body parser fails closed on raw
HTML it cannot accept in the XHTML profile.

## Validate

```bash
bash rotkeeper.sh showcase
bash rotkeeper.sh render
bash rotkeeper.sh links
bash rotkeeper.sh a11y
bash rotkeeper.sh test
bash rotkeeper.sh status
```

Check headings, keyboard focus, narrow viewports, code blocks, and tables
in a browser. Passing the static audit alone does not certify every page.
If an existing wrapper's expected output changes intentionally, regenerate
its checked-in goldens with
`RK_REGEN_TEMPLATE_GOLDENS=1 bash rotkeeper.sh test` and review the diff.
Do not use regeneration to hide an unexpected rendering regression.

**Back to:** [Choose a theme](themes.html) · [Help](../help/index.html)
