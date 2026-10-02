---
title: "Choose a theme"
slug: themes
template: rotkeeper-doc.html
doc_type: guide
reviewed: "2026-10-02"
description: "Select a site or page template, choose a supported palette, and compare themes."
---

# Choose a theme

A template is the HTML wrapper around rendered content. A theme combines
that wrapper with local CSS. The default layout keeps templates in
`bones/templates/` and CSS in `home/assets/css/`.

## Select a template

```bash
bash rotkeeper.sh new --list
bash rotkeeper.sh new themed-page.md --template theme-spooky-light.html --title "Themed page"
```

For an existing source, edit its frontmatter:

```yaml
template: theme-spooky-light.html
```

For a site-wide choice, set `theme_registry.default` in
`bones/config/rotkeeper.yaml`. It takes precedence over the older
`default_template` key. Per-page frontmatter takes precedence over both.
Keep each registered template available in the active template directory.

## Compare the choices

| Group | Templates | Use |
| --- | --- | --- |
| Terminal-oriented | `theme-phosphor.html`, `theme-brutal.html` | Monospace presentation |
| General-purpose | `theme-spooky-dark.html`, `theme-dark.html`, `theme-light.html`, `theme-kawaii.html`, `theme-flash.html`, `theme-pride.html` | Content and documentation |
| Reading-oriented | `theme-spooky-light.html`, `theme-overgrown.html`, `theme-textpattern.html` | Longer prose |
| XHTML variant | `theme-spooky-dark-xhtml.html` | Pages using the XHTML output profile |
| 404 treatment | `theme-necropolis.html` | The `page_type: 404` presentation |
| Prototypes | `theme-daisy.html`, `theme-daisy-vanilla.html` | Vendored DaisyUI and a plain-CSS counterpart |

The DaisyUI theme uses locally vendored CSS, not a CDN or a Node build.
The [DaisyUI comparison](daisyui-map.html) explains its prototype status.
The XHTML wrapper must be paired with the
[XHTML profile](xhtml-profile.html).

## Choose a palette

Templates using `$palette$` can expose palette variants. Set `palette`
in a source's frontmatter; `new` does not have a `--palette` flag.

```yaml
template: theme-brutal.html
palette: unix
```

Brutal provides `mac`, `unix`, and `pwsh`; Flash provides `nova`, `aurora`,
and `hyper`; Pride provides `trans`, `bi`, and `sunset`. Omit `palette`
for the default. Other templates need not implement palette variants.

## Generate previews and check

```bash
bash rotkeeper.sh showcase
bash rotkeeper.sh render
bash rotkeeper.sh links
bash rotkeeper.sh a11y
```

Browse the [showcase](../showcase/index.html) to compare the same evaluation
content across templates. The static accessibility audit checks theme
contrast, keyboard focus styling, and wide-content overflow. Its hard
contrast pairs require 4.5:1; secondary pairs have a 3:1 floor and warn
below 4.5:1. Test your own content and keyboard interaction in a browser too.

To add or change a theme, follow [Create a theme](creating-themes.html).

**Back to:** [Help](../help/index.html) · [Build workflow](workflow.html)
